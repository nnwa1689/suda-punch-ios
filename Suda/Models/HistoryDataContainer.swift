//
//  HistoryDataContainer.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation

struct HistoryDataContainer: Decodable {
    let data: [PunchLog]?
    let meta: HistoryMeta?
}

struct HistoryMeta: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let totalPages: Int
}

// UI 顯示用的模型（將多筆 PunchLog 合併為一天）
struct DailyRecord: Identifiable {
    let id: String // 通常用日期當 ID
    let date: String
    var checkInTime: String = "--:--"
    var checkOutTime: String = "--:--"
    var workingHours: String = "0.0"
}
