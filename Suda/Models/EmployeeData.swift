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
    let department: Department?

    enum CodingKeys: String, CodingKey {
        case id, name, arrival, department
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

struct Department: Codable {
    let departmentId: String
    let name: String
    let parentDepartmentId: String

    enum CodingKeys: String, CodingKey {
        case name
        case departmentId = "id"
        case parentDepartmentId = "parent_department_id"
    }
}
