import SwiftUI
import CoreBluetooth
struct BluetoothTestView: View {
    @State private var btManager = BluetoothAttendanceManager()
    
    var body: some View {
        NavigationStack {
            List(btManager.discoveredPeripherals, id: \.identifier) { peripheral in
                VStack(alignment: .leading, spacing: 5) {
                    // 安全地從字典取得資訊
                    let info = btManager.peripheralExtraInfo[peripheral.identifier]
                    
                    HStack {
                        // 優先顯示廣播名稱
                        Text(peripheral.name ?? "匿名裝置")
                            .font(.headline)
                        Spacer()
                        if let rssi = info?.rssi {
                            Text("\(rssi) dBm")
                                .font(.caption.monospaced())
                                .foregroundColor(rssi > -60 ? .green : .secondary)
                        }
                    }
                    
                    if let uuids = info?.serviceUUIDs, !uuids.isEmpty {
                        ForEach(uuids, id: \.self) { uuid in
                            Text("Service UUID: \(uuid)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("藍牙掃描中")
            .toolbar {
                Button(btManager.isScanning ? "停止" : "掃描") {
                    btManager.isScanning ? btManager.stopScan() : btManager.startScan()
                }
            }
        }
    }
}
