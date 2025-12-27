//
//  TimeResponse.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation

struct TimeData: Decodable {
    let serverTime: String
    let timeZone: String
    
    enum CodingKeys: String, CodingKey {
        case serverTime = "server_time"
        case timeZone = "time_zone"
    }
}
