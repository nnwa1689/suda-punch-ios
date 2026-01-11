import Foundation
internal import CoreLocation
import Network
import Observation

@Observable
class AttendanceLocationManager: NSObject {
    private let manager = CLLocationManager()
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // 狀態屬性
    var isUsingWiFi: Bool = false
    var userLocation: CLLocation?
    var authStatus: CLAuthorizationStatus = .notDetermined
    
    // 計算屬性：判斷是否具備打卡條件
    var canPunchIn: Bool {
        return isUsingWiFi && authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 啟動網路監控
        startMonitoringNetwork()
    }

    private func startMonitoringNetwork() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                // 判斷是否正透過 WiFi 連線
                self?.isUsingWiFi = path.usesInterfaceType(.wifi)
                print("目前連線狀態: \(path.status), 是否為 WiFi: \(String(describing: self?.isUsingWiFi))")
            }
        }
        networkMonitor.start(queue: queue)
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation() // 開始抓取 GPS
    }
}

// MARK: - 定位代理實作
extension AttendanceLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userLocation = locations.last
    }
}
