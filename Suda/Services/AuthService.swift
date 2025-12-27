//
//  AuthService.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation
import UIKit

class AuthService {
    func getServerTime(serverUrl: String) async throws -> BaseResponse<TimeData> {
        guard let url = URL(string: "\(serverUrl)/api/v1/common/time") else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(BaseResponse<TimeData>.self, from: data)
        return decoded
    }
    
    // 第一階段：登入
    func login(serverUrl: String, params: [String: String]) async throws -> BaseResponse<LoginData> {
        guard let url = URL(string: "\(serverUrl)/api/v1/auth/login") else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(params)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0
        
        // 使用我們之前討論過的 Optional Model 解析
        let decoded = try JSONDecoder().decode(BaseResponse<LoginData>.self, from: data)
        
        // 判斷 201 成功 (根據你之前的 API 資訊)
        if httpStatus == 201 && decoded.success == true {
            return decoded
        } else {
            // 處理 401 或其他訊息
            throw NetworkError.requestFailed(decoded.message ?? "帳號密碼錯誤")
        }
    }

    // 第二階段：綁定裝置 (api/v1/device/bind)
    func bindDevice(serverUrl: String, token: String, employeeId: String) async throws -> BaseResponse<BindData> {
        guard let url = URL(string: "\(serverUrl)/api/v1/device/bind") else { throw NetworkError.invalidURL }
        
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
        let decoded = try JSONDecoder().decode(BaseResponse<BindData>.self, from: data)
        
        if (httpStatus == 200 || httpStatus == 201) && decoded.success == true {
            return decoded
        } else {
            throw NetworkError.requestFailed(decoded.message ?? "設備綁定失敗")
        }
    }
}
