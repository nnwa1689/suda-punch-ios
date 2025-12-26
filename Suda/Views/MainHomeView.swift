import SwiftUI

struct MainHomeView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 打卡頁面
            PunchInPageView()
                .tabItem {
                    Label("打卡", systemImage: "clock.fill")
                }
                .tag(0)
            
            // 2. 紀錄頁面
            Text("紀錄頁面建設中...")
                .tabItem {
                    Label("紀錄", systemImage: "list.bullet")
                }
                .tag(1)
            
            // 3. 設定頁面
            Text("設定頁面建設中...")
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(2)
        }
        // 設定 TabBar 的外觀
        .tint(.blue)
    }
}
