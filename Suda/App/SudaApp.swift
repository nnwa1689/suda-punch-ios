//
//  sudaApp.swift
//  suda
//
//  Created by Hazuya on 2025/12/25.
//

import SwiftUI
import SwiftData

@main
struct SudaApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
            .environment(appState)
//            TabView {
//                ContentView()
//                    .tabItem {
//                        Label("Journal", systemImage: "book")
//                    }
//                LoginView()
//                    .tabItem {
//                        Label("Settings", systemImage: "gear")
//                    }
//            }
            //ContentView()
            
        }
        .modelContainer(for: AuthData.self)
    }
}
