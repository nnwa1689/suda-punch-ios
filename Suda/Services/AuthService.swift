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
        request.timeoutInterval = 10
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
    
    func unbindDevice(baseURL: String, empId: String, uuid: String, token: String) async throws -> (Bool, String) {
        var components = URLComponents(string: "\(baseURL)/api/v1/device/unbind")
        guard let url = components?.url else { throw URLError(.badURL) }
        
        // 2. 配置 Request
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "DELETE" // 💡 修改為 DELETE
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 3. 配置 Body 內容
        let body: [String: Any] = [
            "employeeId": empId,
            "deviceUuid": uuid,
            "deviceType": "ios"
        ]
            
        // 將 Dictionary 轉為 JSON Data
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 💡 修正處：檢查 HTTP 狀態碼
        guard let httpResponse = response as? HTTPURLResponse else {
            return (false, "無效的伺服器回應")
        }

        // 3. 解析結果
        // 如果是 200 系列，正常解析成功訊息
        if (200...299).contains(httpResponse.statusCode) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool {
                let message = json["message"] as? String ?? "成功"
                return (success, message)
            }
            return (true, "解除綁定完成")
        }
        // 💡 處理 400 系列或其他錯誤
        else {
            let serverOutput = String(data: data, encoding: .utf8) ?? ""
            print("HTTP Status: \(httpResponse.statusCode)")
            print("Server Response: \(serverOutput)")

            // 2. 嘗試解析 JSON
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // 💡 直接取出 message (型別設為 Any)
                let messageValue = json["message"]
                var finalMessage = ""

                if let messageArray = messageValue as? [String] {
                    // 如果是陣列，直接變成字串 (例如: "error1, error2")
                    finalMessage = messageArray.joined(separator: ", ")
                } else if let messageString = messageValue as? String {
                    // 如果本來就是字串
                    finalMessage = messageString
                } else {
                    // 如果 message 欄位不存在，改抓 error 欄位或顯示狀態碼
                    finalMessage = json["error"] as? String ?? "請求失敗 (\(httpResponse.statusCode))"
                }

                return (false, finalMessage)
            }
            return (false, serverOutput.isEmpty ? "伺服器錯誤" : serverOutput)
        }
    }
    
    func fetchApiInfo(baseURL: String) async throws -> String {
        // 1. 建立 URL
        guard let url = URL(string: "\(baseURL)") else { // 假設路徑為 info
            throw URLError(.badURL)
        }
        
        // 2. 配置 Request (GET 是預設，所以不特別寫也行，但建議寫清楚)
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 3. 發送請求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. 檢查 HTTP 狀態
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // 5. 解析 JSON
        // 這裡 Data 是 String 型別 ("v1.0")
        let decodedResponse = try JSONDecoder().decode(BaseResponse<String>.self, from: data)
        
        return decodedResponse.data ?? "" // 回傳 "v1.0"
    }
}
