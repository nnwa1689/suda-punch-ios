import SwiftUI
internal import CoreLocation

struct WiFiTestView: View {
    // 連結剛才寫好的 Manager
    @State private var locationManager = AttendanceLocationManager()
    
    var body: some View {
        List {
            // 1. WiFi 連線狀態
            Section(header: Text("網路介面偵測")) {
                HStack {
                    Label("WiFi 連線狀態", systemImage: "wifi")
                    Spacer()
                    if locationManager.isUsingWiFi {
                        Text("已連線").foregroundColor(.green).bold()
                    } else {
                        Text("未連線").foregroundColor(.red)
                    }
                }
            }
            
            // 2. 定位權限狀態
            Section(header: Text("系統權限狀態")) {
                HStack {
                    Text("定位授權等級")
                    Spacer()
                    Text(statusDescription(locationManager.authStatus))
                        .foregroundColor(locationManager.authStatus == .authorizedWhenInUse || locationManager.authStatus == .authorizedAlways ? .green : .orange)
                }
            }
            
            // 3. 座標數據偵測
            Section(header: Text("GPS 數據偵測")) {
                if let location = locationManager.userLocation {
                    LabeledContent("緯度 (Lat)", value: String(format: "%.6f", location.coordinate.latitude))
                    LabeledContent("經度 (Lon)", value: String(format: "%.6f", location.coordinate.longitude))
                    LabeledContent("精確度", value: "\(Int(location.horizontalAccuracy)) 公尺")
                } else {
                    HStack {
                        ProgressView().padding(.trailing, 5)
                        Text("正在等待座標更新...")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("偵測狀態測試")
        .onAppear {
            // 畫面出現時啟動要求權限與偵測
            locationManager.requestPermission()
        }
    }
    
    // 輔助函式：轉換權限說明
    func statusDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "等待授權中"
        case .restricted: return "受到限制"
        case .denied: return "已拒絕權限"
        case .authorizedAlways: return "總是允許 (4)"
        case .authorizedWhenInUse: return "使用期間允許 (3)"
        @unknown default: return "未知狀態"
        }
    }
}
