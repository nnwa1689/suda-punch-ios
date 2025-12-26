//
//  AuthService.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation
import UIKit

class AuthService {
    // 第一階段：登入
    func login(serverUrl: String, params: [String: String]) async throws -> LoginResponse {
        guard let url = URL(string: "\(serverUrl)/api/v1/auth/login") else { throw AuthError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(params)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0
        
        // 使用我們之前討論過的 Optional Model 解析
        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        // 判斷 201 成功 (根據你之前的 API 資訊)
        if httpStatus == 201 && decoded.requestSendSuccess == true {
            return decoded
        } else {
            // 處理 401 或其他訊息
            throw AuthError.requestFailed(decoded.message ?? "帳號密碼錯誤")
        }
    }

    // 第二階段：綁定裝置 (api/v1/device/bind)
    func bindDevice(serverUrl: String, token: String, employeeId: String) async throws -> DeviceBindResponse {
        guard let url = URL(string: "\(serverUrl)/api/v1/device/bind") else { throw AuthError.invalidURL }
        
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown-UUID"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") // 帶入 Bearer Token
        
        let body = [
            "employeeId": employeeId,
            "deviceUuid": uuid,
            "deviceType": "ios"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0
        
        // 解析我們修正過的 DeviceBindResponse (bindingId 為 String)
        let decoded = try JSONDecoder().decode(DeviceBindResponse.self, from: data)
        
        if (httpStatus == 200 || httpStatus == 201) && decoded.success == true {
            return decoded
        } else {
            throw AuthError.requestFailed(decoded.message ?? "設備綁定失敗")
        }
    }
    
    enum AuthError: Error, LocalizedError {
        case invalidURL
        case requestFailed(String)
        case decodeError
        case unknown
        
        // 這會讓 viewModel 呼叫 error.localizedDescription 時顯示中文
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "伺服器網址格式錯誤，請檢查協議(http/https)。"
            case .requestFailed(let message):
                return message
            case .decodeError:
                return "伺服器回應資料解析失敗。"
            case .unknown:
                return "發生未知錯誤。"
            }
        }
    }
}
