import Foundation

struct PunchService {
    
    /// 獲取所有啟用的打卡點
    func getAllPunchPoints(serverUrl: String, token: String) async throws -> BaseResponse<[PunchPoint]> {
        guard let url = URL(string: "\(serverUrl)/api/v1/punch-point/") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.requestFailed("無法取得打卡點")
        }
        
        return try JSONDecoder().decode(BaseResponse<[PunchPoint]>.self, from: data)
    }
    
    /// 獲取最後一次打卡紀錄 (GET /api/v1/punch/last)
    func getLastPunch(serverUrl: String, token: String) async throws -> BaseResponse<PunchLog> {
        guard let url = URL(string: "\(serverUrl)/api/v1/punch/last") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.requestFailed("伺服器無回應")
        }
        
        // 檢查狀態碼
        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.requestFailed("錯誤代碼：\(httpResponse.statusCode)")
        }
        
        do {
            return try JSONDecoder().decode(BaseResponse<PunchLog>.self, from: data)
        } catch {
            print("解析上次打卡紀錄失敗: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
    
    //執行打卡 (POST /api/v1/punch)
    func postPunch(serverUrl: String, token: String, requestData: PunchRequest) async throws -> BaseResponse<PunchResult> {
        guard let url = URL(string: "\(serverUrl)/api/v1/punch") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.requestFailed("伺服器無回應")
        }

        // 處理失敗情況 (如 403 Forbidden)
        if httpResponse.statusCode != 200 {
            // 嘗試解析錯誤訊息
            if let errorDetails = try? JSONDecoder().decode(BaseResponse<PunchResult>.self, from: data) {
                throw NetworkError.requestFailed(errorDetails.message ?? "")
            } else {
                throw NetworkError.requestFailed("錯誤代碼：\(httpResponse.statusCode)")
            }
        }
        
        // 處理成功情況
        do {
            return try JSONDecoder().decode(BaseResponse<PunchResult>.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func getMyRecords(serverUrl: String, token: String, startDate: String, endDate: String) async throws -> BaseResponse<HistoryDataContainer> {
        guard let url = URL(string: "\(serverUrl)/api/v1/punch/my-records") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // 建立符合 API 要求的 Body
        let body: [String: Any] = [
            "startDate": startDate,
            "endDate": endDate,
            "page": "1",
            "limit": "1000" // 建議設大一點以便前端分組
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 偵錯用：印出 JSON 看看
        // if let jsonString = String(data: data, encoding: .utf8) { print(jsonString) }
        
        return try JSONDecoder().decode(BaseResponse<HistoryDataContainer>.self, from: data)
    }
}
