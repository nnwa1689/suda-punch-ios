//
//  DeviceBindResponse.swift
//  suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation

struct DeviceBindResponse: Decodable {
    let statusCode: Int?
    let success: Bool?
    let message: String?
    let data: BindData?

    struct BindData: Decodable {
        let employeeId: String?
        let deviceUuid: String?
        let bindingId: String?
        let isActive: Bool?
    }
}
