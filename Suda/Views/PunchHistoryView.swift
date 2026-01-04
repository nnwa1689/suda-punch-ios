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
    
    // 將選項定義為常數，避免在 Body 內重複計算
    var yearOptions: [String] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let startYear = 2025 // 你的 App 開始運行的年份
        // 生成 [ "2024", "2025", ... ]
        return (startYear...currentYear).map { String($0) }
    }
    let monthOptions = (1...12).map { String(format: "%02d", $0) }
    
    var body: some View {
        VStack {
            // 1. 頂部篩選器 (年度/月份)
            HStack(spacing: 15) {
                Menu {
                    ForEach(yearOptions, id: \.self) { option in
                        Button(option) {
                            Task { @MainActor in
                                $viewModel.selectedYear.wrappedValue = option
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text($viewModel.selectedYear.wrappedValue.isEmpty ? "年度" : $viewModel.selectedYear.wrappedValue)
                        Spacer()
                        Image(systemName: "chevron.down").font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.cardBgColor)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .foregroundColor(Color.textPrimary)
                }
                .id("year-dropdown")
                
                Menu {
                    ForEach(monthOptions, id: \.self) { option in
                        Button(option) {
                            Task { @MainActor in
                                $viewModel.selectedMonth.wrappedValue = option
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text($viewModel.selectedMonth.wrappedValue.isEmpty ? "月份" : $viewModel.selectedMonth.wrappedValue)
                        Spacer()
                        Image(systemName: "chevron.down").font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.cardBgColor)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .foregroundColor(Color.textPrimary)
                }
                .id("month-dropdown")
            }
            .padding()

            // 2. 紀錄列表
            ZStack {
                if viewModel.dailyRecords.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(Color.textSecondary)
                        
                        Text("本月無打卡紀錄")
                            .font(.headline)
                            .foregroundColor(Color.textSecondary)
                        
                        Text("\(viewModel.selectedYear)年 \(viewModel.selectedMonth)月")
                            .font(.subheadline)
                            .foregroundColor(Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.dailyRecords) { record in
                                RecordCard(viewModel: viewModel, record: record)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .background(Color.bgColor)
        .onChange(of: viewModel.selectedMonth) { oldVal, newVal in
            Task {
                print("月份已變更：\(oldVal) -> \(newVal)")
                await viewModel.fetchHistory(serverUrl: viewModel.serverUrl, token: viewModel.userToken)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchHistory(serverUrl: viewModel.serverUrl, token: viewModel.userToken)
            }
        }
    }
}

// 3. 紀錄卡片組件
struct RecordCard: View {
    @Bindable var viewModel: PunchHistoryViewModel
    let record: DailyRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.date).bold().font(.headline).foregroundColor(Color.textPrimary)
                Spacer()
                Text(record.workingHours + "小時").foregroundColor(Color.primaryBlue)
            }
            
            Text("上班打卡時間: \(record.checkInTime)").foregroundColor(Color.textSecondary)
            Text("下班打卡時間: \(record.checkOutTime)").foregroundColor(Color.textSecondary)
        }
        .padding()
        .background(Color.cardBgColor)
        .cornerRadius(15)
        //.overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
