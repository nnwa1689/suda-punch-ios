//
//  PunchHistoryViewModel.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Observation
import Foundation

@Observable
class PunchHistoryViewModel {
    var dailyRecords: [DailyRecord] = []
    var isLoading: Bool = false
    
    var serverUrl: String = ""
    var userToken: String = ""
    var employeeId: String = ""
    var deviceUuid: String = ""
    
    // 預設抓當月 (範例)
    var selectedYear: String
    var selectedMonth: String
    var yearList: [String] = []
    
    private let punchService = PunchService()
    
    init(auth: AuthData) {
        let now = Date()
        let calendar = Calendar.current
        
        // 取得年度 (例如: 2024)
        let year: Int = calendar.component(.year, from: now)
        yearList = [String(year - 1), String(year), String(year + 1)]
        
        // 取得月份 (例如: 5)
        let month: Int = calendar.component(.month, from: now)
        
        self.selectedYear = String(year)
        // 使用 String(format:) 確保月份是兩位數，例如 "05" 而不是 "5"，這對 API 比較友善
        self.selectedMonth = String(format: "%02d", month)
        
        self.serverUrl = auth.serverUrl
        self.userToken = auth.token
        self.employeeId = auth.userId
        self.deviceUuid = auth.deviceUuid ?? ""
    }

    func fetchHistory(serverUrl: String, token: String) async {
        //try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 秒
        await MainActor.run {
            self.isLoading = true
        }
        
        // 💡 建立當月 1 號的 Date 物件
        var components = DateComponents(year: Int(selectedYear), month: Int(selectedMonth), day: 1)
        let calendar = Calendar.current
        
        guard let startDateObj = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startDateObj) else { return }
        
        // 💡 取得該月最大的天數 (30 或 31，甚至是 2 月的 28/29)
        let lastDay = range.count
        
        // 1. 準備時間範圍 (月初到月底)
        let startDate = "\(selectedYear)-\(selectedMonth)-01"
        let endDate = "\(selectedYear)-\(selectedMonth)-\(lastDay)"
        
        do {
            // 2. 呼叫 API (需在你的 PunchService 實作對應 POST 方法)
            let response = try await punchService.getMyRecords(serverUrl: serverUrl, token: token, startDate: startDate, endDate: endDate)
            
            if let logs = response.data?.data {
                self.dailyRecords = processLogsIntoDaily(logs)
            }
        } catch {
            print("抓取紀錄失敗: \(error)")
        }
        
        isLoading = false
    }
    
    // 3. 核心邏輯：將單筆 Log 合併成每日紀錄
    private func processLogsIntoDaily(_ logs: [PunchLog]) -> [DailyRecord] {
        var tempDict: [String: DailyRecord] = [:]
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let displayDateFormatter = DateFormatter()
        displayDateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for log in logs {
            guard let dateObj = isoFormatter.date(from: log.punchTime) else { continue }
            let dateKey = displayDateFormatter.string(from: dateObj)
            let timeStr = timeFormatter.string(from: dateObj)
            
            var current = tempDict[dateKey] ?? DailyRecord(id: dateKey, date: dateKey)
            
            if log.punchType == "CHECK_IN" {
                current.checkInTime = timeStr
            } else if log.punchType == "CHECK_OUT" {
                current.checkOutTime = timeStr
            }
            
            // 這裡可以進階計算 duration (下班減上班)
            if tempDict[dateKey] == nil{
                tempDict[dateKey] = current
            }
            
            if tempDict[dateKey]?.checkInTime == "--:--" {
                tempDict[dateKey]?.checkInTime = current.checkInTime
            }
            
            if tempDict[dateKey]?.checkOutTime == "--:--" {
                tempDict[dateKey]?.checkOutTime = current.checkOutTime
            }
            
            if tempDict[dateKey]?.workingHours == "0.0" {
                tempDict[dateKey]?.workingHours = calculateHours(start: current.checkInTime, end: current.checkOutTime)
            }
            
        }
        
        // 依照日期排序回傳
        return tempDict.values.sorted { $0.date > $1.date }
    }
    
    private func calculateHours(start: String, end: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard start != "--:--", end != "--:--",
              let startDate = formatter.date(from: start),
              let endDate = formatter.date(from: end) else {
            print("DEBUG: 解析失敗，請檢查格式是否與 \(start) 匹配")
            return "0.0"
        }
        
        let diff = endDate.timeIntervalSince(startDate)
        let actualDiff = diff < 0 ? diff + 86400 : diff
        return String(format: "%.1f", actualDiff / 3600.0)
    }
}
