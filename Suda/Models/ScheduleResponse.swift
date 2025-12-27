//
//  ScheduleResponse.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation

struct ShiftInfo: Decodable {
    let id: String
    let date: String
    let shift: ShiftDetails
}

struct ShiftDetails: Decodable {
    let id: String
    let name: String
    let isCrossDay: Bool
    let startTime: String
    let endTime: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, startTime, endTime, isActive
        case isCrossDay = "is_cross_day"
    }
}
