import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    //let bgColor = Color(red: 0.97, green: 0.98, blue: 0.99)
    //let cardBgColor = Color(red: 0.92, green: 0.94, blue: 0.96)
    
    init(auth: AuthData) {
        // 初始化 State 包裝的 ViewModel
        _viewModel = State(initialValue: SettingsViewModel(auth: auth))
    }

    var body: some View {
        ZStack {
            // 使用你定義的背景色
            Color.bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // --- 使用者資訊區 ---
                        VStack(spacing: 8) {
                            Text(viewModel.employeeName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("到職日期: \(viewModel.hireDate)")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                        
                        // --- 帳號資訊卡片 ---
                        VStack(alignment: .leading, spacing: 0) {
                            Text("帳號資訊")
                                .font(.headline)
                                .padding(.leading, 4)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 0) {
                                infoRow(title: "帳號", value: viewModel.employeeId)
                                Divider().padding(.horizontal)
                                //infoRow(title: "帳號登入類型", value: loginType)
                                //Divider().padding(.horizontal)
                                infoRow(title: "綁定打卡手機 UUID", value: viewModel.deviceUuid)
                            }
                            .background(Color.cardBgColor) // 使用你定義的卡片色
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        // --- 底部版本資訊 ---
                        VStack(spacing: 4) {
                            Text("APP版本 :\(viewModel.appVersion)")
                            Text("API連線位置: \(viewModel.serverUrl)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    }
                }
                
                // --- 登出按鈕 ---
                Button(action: {
                    // 執行登出動作
                }) {
                    Text("登出並解除裝置綁定")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(28)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // 輔助組件：資訊列
    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
