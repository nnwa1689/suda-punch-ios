//
//  ContentView.swift
//  suda
//
//  Created by Hazuya on 2025/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var authRecords: [AuthData]
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if appState.isLoggedIn {
                if let auth = authRecords.first {
                    MainHomeView(auth: auth)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            } else {
                // 否則停留在登入頁
                LoginView()
                    .transition(.opacity)
            }
        }
        .onAppear{
            let descriptor = FetchDescriptor<AuthData>()
            
            if let records = try? modelContext.fetch(descriptor), !records.isEmpty {
                appState.isLoggedIn = true
            }
        }
//        NavigationSplitView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
//                    } label: {
//                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//        } detail: {
//            Text("Select an item")
//        }
    }

//    private func addItem() {
//        withAnimation {
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//        }
//    }

//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
//    }
}
