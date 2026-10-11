internal import CoreLocation

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D?
    var locationError: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // 等待中的權限詢問 / 定位請求
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var timeoutTask: Task<Void, Never>?
    // 收到暫時性錯誤 (locationUnknown) 時記錄，逾時後改回報「收不到訊號」
    private var receivedLocationUnknown = false

    // 超過此秒數的快取座標視為過期，不用於打卡
    private let maxLocationAge: TimeInterval = 30

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        self.authorizationStatus = manager.authorizationStatus
    }

    /// 取得目前座標：必要時先詢問權限，並等待定位結果或逾時
    /// - Parameter timeout: 等待定位的最長秒數 (不含使用者回覆權限詢問的時間)
    func requestCurrentLocation(timeout: TimeInterval = 10) async throws -> CLLocationCoordinate2D {
        guard locationContinuation == nil else { throw LocationError.busy }

        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw LocationError.denied
        }

        // 每次打卡都重新定位，避免沿用上一次的座標
        userLocation = nil
        locationError = nil
        receivedLocationUnknown = false

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(timeout))
                guard let self, !Task.isCancelled else { return }
                self.finish(.failure(self.receivedLocationUnknown ? LocationError.unavailable : LocationError.timeout))
            }
            manager.startUpdatingLocation()
        }
    }

    /// 結束目前的定位請求
    private func finish(_ result: Result<CLLocationCoordinate2D, Error>) {
        manager.stopUpdatingLocation()
        timeoutTask?.cancel()
        timeoutTask = nil
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(with: result)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // 略過過期的快取座標，繼續等待新的定位
        if locationContinuation != nil && abs(location.timestamp.timeIntervalSinceNow) > maxLocationAge {
            return
        }
        userLocation = location.coordinate
        if locationContinuation != nil {
            finish(.success(location.coordinate))
        } else {
            manager.stopUpdatingLocation() // 抓到後停止以省電
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
        let code = (error as? CLError)?.code
        switch code {
        case .locationUnknown:
            // 暫時無法定位，系統會持續嘗試，等到逾時再判定失敗
            receivedLocationUnknown = true
        case .denied:
            finish(.failure(LocationError.denied))
        default:
            finish(.failure(LocationError.unavailable))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .denied {
            print("使用者拒絕了定位權限")
        }
        // 權限詢問已有結果時，繼續等待中的定位流程
        if manager.authorizationStatus != .notDetermined, let continuation = authorizationContinuation {
            authorizationContinuation = nil
            continuation.resume(returning: manager.authorizationStatus)
        }
    }
}
