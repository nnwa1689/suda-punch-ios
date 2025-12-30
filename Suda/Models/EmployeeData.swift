//
//  EmployeeData.swift
//  Suda
//
//  Created by Hazuya on 2025/12/30.
//

import Foundation

struct EmployeeData: Codable {
    let id: String
    let name: String
    let arrival: String?
    let activeDevice: DeviceInfo?

    enum CodingKeys: String, CodingKey {
        case id, name, arrival
        case activeDevice = "active_device"
    }
}

struct DeviceInfo: Codable {
    let deviceUuid: String
    let deviceType: String

    enum CodingKeys: String, CodingKey {
        case deviceUuid = "device_uuid"
        case deviceType = "device_type"
    }
}
