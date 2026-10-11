import Foundation
import CoreBluetooth
import Observation
import SwiftData
internal import CoreLocation

@Observable
@MainActor
class PunchInPageViewModel {
    private let punchService = PunchService()
    private let scheduleService = ScheduleService()
    private let userService = UserService()
    var bluetoothManager = BluetoothAttendanceManager()
    
    var locationManager: LocationManager? // 用於獲取經緯度
    
    var serverUrl: String = ""
    var userToken: String = ""
    var employeeId: String = ""
    var deviceUuid: String = ""
    
    var currentTime: String = "--:--:-- --"
    var currentDate: String = "----, ---- --"
    
    // UI 顯示用變數
    var scheduleName: String = "讀取中..."
    var expectedPunchTime: String = "--:--"
    var expectedPunchTimeOut: String = "--:--"

    var lastPunchTime: String = "--:--"
    var lastPunchLocation: String = "--"
    
    var punchPoints: [PunchPoint] = []
    var selectedPoint: PunchPoint? {
        didSet {
            if let id = selectedPoint?.id {
                UserDefaults.standard.set(id, forKey: "LastPunchPointID")
                print("DEBUG: 已儲存上次打卡點 ID: \(id)")
            } else {
                // 如果被設為 nil，可以考慮移除紀錄
                UserDefaults.standard.removeObject(forKey: "LastPunchPointID")
            }
        }
    }
    
    var lastPunchInfo: String = "尚無紀錄"
    var lastPunchRemark: String? = nil
    
    var isPunching: Bool = false      // 控制按鈕是否正在轉圈圈/禁用
    var isPunchingBluetooth: Bool = false
    var showAlert: Bool = false       // 控制 .alert 彈窗是否顯示
    var alertMessage: String = ""     // 存儲 API 回傳的成功或錯誤訊息
    
    // --- 藍牙相關屬性 ---
    // 儲存掃描到的即時資訊 [ID: (RSSI, [ServiceUUIDs])]
    var bluetoothExtraInfo: [UUID: (rssi: Int, serviceUUIDs: [String])] = [:]
    // 目前掃描到的裝置列表
    var discoveredPeripherals: [CBPeripheral] = []
    
    
    // 儲存從伺服器拿到的 Date 物件
    private var serverDate: Date?
    private var timer: Timer?
    private let authService = AuthService()
    
    // 初始化時直接注入資料
    init(auth: AuthData) {
        self.serverUrl = auth.serverUrl
        self.userToken = auth.token
        self.employeeId = auth.userId
        self.deviceUuid = auth.deviceUuid ?? ""
        
        Task {
            await fetchInitialServerTime()
            await fetchPunchPoints()
            await fetchTodaySchedule()
            await fetchLastPunch()
        }
    }
    
    // 從 API 獲取初始時間
    func fetchInitialServerTime() async {
        do {
            let response = try await authService.getServerTime(serverUrl: serverUrl)
            if let timeData = response.data {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "zh_Hant_TW@hours=24")
                formatter.timeZone = TimeZone(identifier: timeData.timeZone)
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                if let date = formatter.date(from: timeData.serverTime) {
                    self.serverDate = date
                    startLocalTimer()
                }
            }
        } catch {
            print("時間校準失敗: \(error)")
        }
    }
    
    // 每秒在本機更新，避免頻繁請求 API
    private func startLocalTimer() {
        timer?.invalidate()
        // 1. 先建立 timer，但不直接排程 (不要用 scheduledTimer)
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in // 確保在主執行緒更新 UI
                self?.tick()
            }
        }
        
        // 2. 將 timer 加入到 .common 模式的 RunLoop 中
        RunLoop.main.add(newTimer, forMode: .common)
        
        // 3. 儲存 timer 實例以便後續停止
        self.timer = newTimer
    }
    
    private func tick() {
        guard let date = serverDate else { return }
        // 增加一秒
        let newDate = date.addingTimeInterval(1)
        self.serverDate = newDate
        
        // 更新 UI 字串
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "zh_Hant_TW@hours=24")
        timeFormatter.dateFormat = "HH:mm:ss"
        self.currentTime = timeFormatter.string(from: newDate)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        dateFormatter.dateFormat = "yyyy/MM/dd EEEE"
        self.currentDate = dateFormatter.string(from: newDate)
    }
    
    // 4. 核心功能方法
    func performPunch(type: String) async {
        defer {
            // 不論結果如何，結束時都要清空，確保下次打卡是全新的偵測
            bluetoothManager.stopScan()
            self.isPunching = false
        }
        // 1. 檢查地點
        guard let point = selectedPoint else {
            self.alertMessage = "請先選擇打卡地點"
            self.showAlert = true
            return
        }
        
        // BlueTooth 打卡驗證
        if point.verifyType == "Bluetooth" {
            bluetoothManager.startScan()
            self.isPunchingBluetooth = true
            // 2. 藍牙硬體檢查
            guard bluetoothManager.bluetoothStatus == .poweredOn else {
                self.alertMessage = "請開啟藍牙以進行位置驗證"
                self.showAlert = true
                self.isPunchingBluetooth = false
                return
            }
            
            if let targetUuid = point.bluetoothServiceUuid, !targetUuid.isEmpty {
                // 給予 2 秒的時間確保掃描到最新的 RSSI（避免剛打開 App 還沒掃到）
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                
                if !isSelectedPointInRange {
                    self.alertMessage = "未偵測到打卡基站，請靠近「\(point.name)」"
                    self.isPunching = false
                    self.isPunchingBluetooth = false
                    self.showAlert = true
                    return
                }
            }
            self.isPunchingBluetooth = false
        } else {
            // Wifi 打卡預留
        }

        // 2. 檢查定位組件
        if locationManager == nil {
            locationManager = LocationManager()
        }
        
        guard let lm = locationManager else {
            self.alertMessage = "定位模組初始化失敗"
            self.showAlert = true
            return
        }
        
        // 3. 開始定位流程：等待權限與定位結果 (最多 10 秒)，不再固定等待 1 秒
        self.isPunching = true
        let coords: CLLocationCoordinate2D
        do {
            coords = try await lm.requestCurrentLocation()
            print("DEBUG: 拿到座標: \(coords.latitude), \(coords.longitude)")
        } catch {
            print("DEBUG: 定位失敗: \(error)")
            self.alertMessage = "打卡失敗：\(error.localizedDescription)"
            self.showAlert = true
            return
        }

        // 4. 取得座標後發送請求
        do {
            let request = PunchRequest(
                latitude: coords.latitude,
                longitude: coords.longitude,
                deviceUuid: self.deviceUuid,
                type: type,
                punchPointsId: point.id
            )

            let response = try await punchService.postPunch(
                serverUrl: serverUrl,
                token: userToken,
                requestData: request
            )

            self.alertMessage = response.message ?? ""
            self.showAlert = true
            await fetchLastPunch()

        } catch {
            self.alertMessage = "打卡失敗：\(error.localizedDescription)"
            self.showAlert = true
        }

        // 5. 結束打卡狀態
        self.isPunching = false
    }
    // 輔助方法
    func performPunchIn() { Task { await performPunch(type: "CHECK_IN") } }
    func performPunchOut() { Task { await performPunch(type: "CHECK_OUT") } }
    
    // --- 藍牙掃描控制 ---
    func startBluetoothScan() {
            bluetoothManager.startScan()
        }

    func stopBluetoothScan() {
        bluetoothManager.stopScan()
    }
    
    // --- 驗證邏輯：判斷目前選中的地點是否在旁邊 ---
    var isSelectedPointInRange: Bool {
        guard let targetPoint = selectedPoint,
              let targetUUIDString = targetPoint.bluetoothServiceUuid else {
            return false
        }
        
        // 將字串轉為 CBUUID 物件，這會自動處理大小寫與連字號問題
        let targetCBUUID = CBUUID(string: targetUUIDString)
        
        return bluetoothManager.peripheralExtraInfo.values.contains { info in
            // 將掃描到的字串陣列轉回 CBUUID 進行物件比對
            info.serviceUUIDs.contains { scannedUUIDString in
                CBUUID(string: scannedUUIDString) == targetCBUUID
            }
        }
    }

    func fetchPunchPoints() async {
        do {
            let response = try await punchService.getAllPunchPoints(
                serverUrl: serverUrl,
                token: userToken
            )
            
            // 💡 因為是 BaseResponse<[PunchPoint]>，所以 data 就是陣列
            if let points = response.data {
                self.punchPoints = points.filter { $0.isActive }
                checkIfLastPointIsAvailable()
            }
        } catch {
            print("取得打卡點失敗: \(error)")
        }
    }
    
    func fetchTodaySchedule() async {
        do {
            let response = try await scheduleService.getTodayNearest(
                serverUrl: serverUrl,
                token: userToken
            )
            
            // 使用鏈式解包來取出資料
            if let shift = response.data?.shift {
                self.scheduleName = shift.name
                self.expectedPunchTime = shift.startTime
                self.expectedPunchTimeOut = shift.endTime
            } else {
                // 處理「近期無排班」的情況
                self.scheduleName = response.message ?? "無排班"
                self.expectedPunchTime = "--:--"
                print("伺服器訊息：\(response.message)")
            }
        } catch {
            print("獲取班別失敗: \(error)")
            self.scheduleName = "讀取失敗"
            self.expectedPunchTime = "N/A"
        }
    }
    
    func fetchLastPunch() async {
        do {
            let response = try await punchService.getLastPunch(
                serverUrl: serverUrl,
                token: userToken
            )
            
            if let log = response.data {
                // 1. 處理時間格式化
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                let displayTime: String
                if let date = isoFormatter.date(from: log.punchTime) {
                    let outputFormatter = DateFormatter()
                    outputFormatter.dateFormat = "HH:mm"
                    displayTime = outputFormatter.string(from: date)
                } else {
                    displayTime = "--:--"
                }
                
                // 2. 處理類型轉換
                let typeStr = log.punchType == "CHECK_IN" ? "上班" : "下班"
                let locationName = log.punchPoint?.name ?? "未知地點"
                
                // 3. 更新 UI 字串
                self.lastPunchLocation = locationName
                self.lastPunchTime = "\(displayTime)(\(typeStr))"
                
            } else {
                self.lastPunchTime = "查無打卡紀錄"
                self.lastPunchLocation = "--"
            }
        } catch {
            print("取得上次打卡失敗: \(error)")
            self.lastPunchInfo = "無紀錄"
        }
    }
    
    func checkIfLastPointIsAvailable() {
        // 從手機讀取上次存的 ID
        guard let lastID = UserDefaults.standard.string(forKey: "LastPunchPointID") else {
            // 如果從來沒存過，預設選第一個
            self.selectedPoint = punchPoints.first
            return
        }
        
        // 檢查上次存的 ID 是否還在這次 API 回傳的列表裡
        if let foundPoint = punchPoints.first(where: { $0.id == lastID }) {
            self.selectedPoint = foundPoint
        } else {
            // 如果上次的地點失效了（API沒回傳），則預設選第一個
            self.selectedPoint = punchPoints.first
        }
    }
}
