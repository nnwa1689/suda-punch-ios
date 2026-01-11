import SwiftUI
import SwiftData
import Foundation
import Observation

struct MainHomeView: View {
    @State private var selectedTab = 0
    @Environment(\.scenePhase) var scenePhase
    @State private var viewModel: MainHomeViewModel
    
    init(auth: AuthData) {
        // 初始化 State 包裝的 ViewModel
        _viewModel = State(initialValue: MainHomeViewModel(auth: auth))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("讀取中...")
            } else if !viewModel.apiIsOnline {
                VStack(spacing: 20) {
                    FullScreenMessageView(icon: "wifi.exclamationmark", title: "連線失敗！", message: "請檢查網路連線")
                    Button("重試", systemImage: "arrow.counterclockwise.circle.fill") {
                        Task {
                            await viewModel.apiTets()
                            await viewModel.fetchSelfUserInfo()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if !viewModel.userIsActive {
                VStack(spacing: 20) {
                    FullScreenMessageView(icon: "iphone.gen3.slash.circle", title: "無法使用", message: "帳號或裝置已被停用")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                //WiFiTestView()
                TabView(selection: $selectedTab) {
                    PunchInPageView(auth: viewModel.auth)
                        .tabItem {
                            Label("打卡", systemImage: "clock.fill")
                        }
                        .tag(0)
                    
                    // 2. 紀錄頁面
                    PunchHistoryView(auth: viewModel.auth)
                        .tabItem {
                            Label("紀錄", systemImage: "list.bullet")
                        }
                        .tag(1)
                    
                    // 3. 設定頁面
                    SettingsView(auth: viewModel.auth)
                        .tabItem {
                            Label("設定", systemImage: "gearshape")
                        }
                        .tag(2)
                }
                .tint(.blue)
            }
        }
        .onAppear {
            Task{
                await viewModel.apiTets()
                await viewModel.fetchSelfUserInfo()
            }
        }
    }
}

struct FullScreenMessageView: View {
    var icon = ""
    var message = ""
    var title = ""
    
    init(icon: String, title: String, message: String){
        self.icon = icon
        self.message = message
        self.title = title
    }
    
    var body: some View {
        VStack{
            Image(systemName: self.icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(self.title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(10)
            
            Text(self.message)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}
