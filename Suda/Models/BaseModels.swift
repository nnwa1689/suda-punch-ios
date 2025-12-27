//
//  BaseModels.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation

struct BaseResponse<T: Decodable>: Decodable {
    // let response = try JSONDecoder().decode(BaseResponse<ScheduleData>.self, from: data)
    let statusCode: Int
    let success: Bool?
    let message: String?
    let error: String?
    let data: T?
}
