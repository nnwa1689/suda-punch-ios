import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel: SettingsViewModel
    @State private var showUnbindAlert = false
    @State private var unbindSuccess = false // 用於判斷是否執行後續登出動作
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
                            UserAvatarView(username: viewModel.employeeName, size: 100)
                            Text(viewModel.employeeName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color.textPrimary)
                            
                            Text("\(viewModel.deptId) - \(viewModel.deptName)")
                                .font(.system(size: 16))
                                .foregroundColor(Color.textSecondary)
                            
                            Text("到職日期: \(viewModel.hireDate)")
                                .font(.system(size: 16))
                                .foregroundColor(Color.textSecondary)
                        }
                        .padding(.top, 40)
                        
                        // --- 帳號資訊卡片 ---
                        VStack(alignment: .leading, spacing: 0) {
                            Text("帳號資訊")
                                .font(.headline)
                                .padding(.leading, 4)
                                .padding(.bottom, 8)
                                .foregroundColor(Color.textPrimary)
                            
                            VStack(spacing: 0) {
                                infoRow(title: "帳號", value: viewModel.employeeId)
                                Divider().padding(.horizontal)
                                infoRow(title: "API 連線公司名稱", value: viewModel.companyName)
                                Divider().padding(.horizontal)
                                //infoRow(title: "帳號登入類型", value: loginType)
                                //Divider().padding(.horizontal)
                                infoRow(title: "綁定打卡手機 UUID", value: viewModel.deviceUuid)
                            }
                            .background(Color.cardBgColor) // 使用你定義的卡片色
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        // --- 底部版本資訊 ---
                        VStack(spacing: 4) {
                            Text("APP版本 :\(Bundle.main.fullVersionString)")
                            Text("API連線位置: \(viewModel.serverUrl)")
                            Text("API版本: \(viewModel.apiVersion)")
                        }
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    }
                }
                
                // --- 登出按鈕 ---
                Button(action: {
                    showUnbindAlert = true
                }) {
                    HStack {
                        if viewModel.isUnbinding {
                            ProgressView().tint(.white)
                            Text("處理中...")
                        } else {
                            Text("登出並解除裝置綁定")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(28)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(viewModel.isUnbinding)
            }
        }
        .alert("解除裝置綁定", isPresented: $showUnbindAlert) {
            Button("取消", role: .cancel) { }
            Button("確定解除", role: .destructive) {
                Task{
                    let success = await viewModel.performUnbind()
                    
                    if success {
                        await MainActor.run {
                            do{
                                // 從 SwiftData 移除這筆資料
                                try modelContext.delete(model: AuthData.self)
                                try? modelContext.save()
                                appState.isLoggedIn = false
                                print("DEBUG: 本地 AuthData 已成功刪除，App 將反應式地回到登入頁")
                            } catch {
                                // 💡 處理錯誤（例如：磁碟空間不足或資料庫鎖定）
                                print("清除資料時發生錯誤: \(error.localizedDescription)")
                                viewModel.errorMessage = "本地資料清除失敗，請嘗試手動重開 App"
                                viewModel.showAlert = true
                            }
                        }
                    }
                }
            }
        } message: {
            Text("解除綁定後，這台手機將無法繼續打卡。確定要執行嗎？")
        }
        .alert("提示", isPresented: $viewModel.showAlert) {
            Button("取消", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // 輔助組件：資訊列
    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.textPrimary)
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UserAvatarView: View {
    let username: String
    let size: CGFloat
    
    // 取得第一個字
    private var firstLetter: String {
        username.prefix(1).uppercased()
    }
    
    // 根據名字固定產生顏色（這樣同一個人的顏色就不會變）
    private var backgroundColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal]
        let index = abs(username.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            
            Text(firstLetter)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
