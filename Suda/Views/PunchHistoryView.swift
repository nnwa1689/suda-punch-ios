//
//  PunchHistoryView.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation
import SwiftUI

struct PunchHistoryView: View {
    @State private var viewModel: PunchHistoryViewModel
    
    init(auth: AuthData) {
        // 初始化 State 包裝的 ViewModel
        _viewModel = State(initialValue: PunchHistoryViewModel(auth: auth))
    }
    
    var body: some View {
        VStack {
            // 1. 頂部篩選器 (年度/月份)
            HistoryFilterHeader(viewModel: viewModel)
            .padding()
            .zIndex(1)

            // 2. 紀錄列表
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.dailyRecords) { record in
                            RecordCard(record: record)
                        }
                    }
                    .padding()
                }
                .opacity(viewModel.isLoading ? 0 : 1) // 讀取時隱藏而非銷毀

                if viewModel.isLoading {
                    ProgressView("讀取中...")
                        .transition(.opacity) // 平滑過渡
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .task {
            await viewModel.fetchHistory(serverUrl: viewModel.serverUrl, token: viewModel.userToken)
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color(uiColor: .systemGroupedBackground)
                    ProgressView("讀取中...")
                }
            }
        }
    }
    
    // 自定義選單按鈕
//    func filterMenu(title: String, selection: Binding<String>, options: [String]) -> some View {
//        Menu {
//            ForEach(options, id: \.self) { option in
//                Button(option) {
//                    selection.wrappedValue = option
//                }
//            }
//        } label: {
//            HStack {
//                // 如果 selection 有值就顯示值，否則顯示 title
//                Text(selection.wrappedValue.isEmpty ? title : selection.wrappedValue)
//                    .lineLimit(1)
//                Spacer()
//                Image(systemName: "chevron.down").font(.caption)
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 10)
//            .background(Color.white)
//            .cornerRadius(25)
//            .overlay(
//                RoundedRectangle(cornerRadius: 25)
//                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
//            )
//        }
//        .foregroundColor(.blue)
//    }
}

struct HistoryFilterHeader: View {
    @Bindable var viewModel: PunchHistoryViewModel
    
    // 將選項定義為常數，避免在 Body 內重複計算
    var yearOptions: [String] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let startYear = 2024 // 你的 App 開始運行的年份
        
        // 生成 [ "2024", "2025", ... ]
        return (startYear...currentYear).map { String($0) }
    }
    let monthOptions = (1...12).map { String(format: "%02d", $0) }
    
    var body: some View {
        HStack(spacing: 15) {
            // 年度選單
            FilterDropdown(selection: $viewModel.selectedYear, options: yearOptions, title: "年度")
            // 月份選單
            FilterDropdown(selection: $viewModel.selectedMonth, options: monthOptions, title: "月份")
        }
        .id("history_header")
        .padding()
    }
}

// 更小的子組件，負責顯示選單樣式
struct FilterDropdown: View {
    @Binding var selection: String
    let options: [String]
    let title: String
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    Task { @MainActor in
                        selection = option
                    }
                }
            }
        } label: {
            HStack {
                Text(selection.isEmpty ? title : selection)
                Spacer()
                Image(systemName: "chevron.down").font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 2)
        }
    }
}

// 3. 紀錄卡片組件
struct RecordCard: View {
    let record: DailyRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.date).bold().font(.headline)
                Spacer()
                Text(record.duration).foregroundColor(.gray)
            }
            
            Text("上班打卡時間: \(record.checkInTime)").foregroundColor(.blue.opacity(0.8))
            Text("下班打卡時間: \(record.checkOutTime)").foregroundColor(.blue.opacity(0.8))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
