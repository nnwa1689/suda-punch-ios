//
//  DeviceBindRequest.swift
//  suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation

struct DeviceBindRequest: Encodable {
    let employeeId: String
    let deviceUuid: String
    let deviceType: String = "ios" // 固定為 ios
}
