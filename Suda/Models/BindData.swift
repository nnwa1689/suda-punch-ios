//
//  DeviceBindResponse.swift
//  suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation

struct BindData: Decodable {
    let employeeId: String?
    let deviceUuid: String?
    let bindingId: String?
    let isActive: Bool?
}
