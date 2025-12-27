import SwiftUI
import SwiftData
import Foundation
import Observation

struct MainHomeView: View {
    @Query private var authRecords: [AuthData]
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            if let auth = authRecords.first {
                PunchInPageView(auth: auth)
                    .tabItem {
                        Label("打卡", systemImage: "clock.fill")
                    }
                    .tag(0)
                
                // 2. 紀錄頁面
                PunchHistoryView(auth: auth)
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
            } else {
                ProgressView("讀取資料中...")
            }
        }
        // 設定 TabBar 的外觀
        .tint(.blue)
    }
}
