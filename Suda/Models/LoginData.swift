//
//  LoginResponse.swift
//  suda
//
//  Created by Hazuya on 2025/12/26.
//

import Foundation

struct LoginData: Decodable {
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token" // 將底線轉為 Swift 變數名
    }
}
