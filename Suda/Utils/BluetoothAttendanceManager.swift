import Foundation
import CoreBluetooth
import Observation

@Observable
class BluetoothAttendanceManager: NSObject {
    private var centralManager: CBCentralManager?
    
    // 偵測到的裝置列表
    var discoveredPeripherals: [CBPeripheral] = []
    var isScanning = false
    var bluetoothStatus: CBManagerState = .unknown
    
    // 2. 補上這行：用來存取廣播資訊的字典
        // Key 是裝置的 UUID，Value 是一個包含 RSSI 和 UUID 陣列的元組 (Tuple)
    var peripheralExtraInfo: [UUID: (rssi: Int, serviceUUIDs: [String])] = [:]

    override init() {
        super.init()
        // 初始化中央管理器
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard bluetoothStatus == .poweredOn else { return }
        isScanning = true
        // 開始掃描所有裝置 (可以傳入特定 Service UUID)
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        centralManager?.stopScan()
        isScanning = false
    }
}

extension BluetoothAttendanceManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.bluetoothStatus = central.state
        if central.state == .poweredOn {
            print("藍牙已就緒")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // --- 抓取名稱的優先順序 ---
        // 1. 廣播包中的 Local Name (最即時)
        // 2. peripheral 物件本身的 name (系統快取)
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let finalName = localName ?? peripheral.name ?? "匿名裝置"
        
        // 抓取 UUIDs
        let serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map { $0.uuidString } ?? []
        
        DispatchQueue.main.async {
            // 更新字典 (這裡我們把名稱也存進去，確保 View 讀得到最新的)
            self.peripheralExtraInfo[peripheral.identifier] = (rssi: RSSI.intValue, serviceUUIDs: serviceUUIDs)
            
            // 檢查是否已在列表中，並確保名稱有更新
            if let index = self.discoveredPeripherals.firstIndex(where: { $0.identifier == peripheral.identifier }) {
                // 如果原本是匿名，現在抓到名字了，可以更新
                // 注意：CBPeripheral 的 name 是 read-only，所以我們 View 要改讀字典裡的名稱
            } else {
                self.discoveredPeripherals.append(peripheral)
            }
        }
    }
}
