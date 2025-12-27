import Foundation

struct ScheduleService {
    
    /// 獲取當天最近的班別資訊
    /// - Parameters:
    ///   - serverUrl: 從 AuthData 取得的伺服器網址
    ///   - token: Bearer Token
    func getTodayNearest(serverUrl: String, token: String) async throws -> BaseResponse<ShiftInfo> {
        // 1. 建立 URL
        guard let url = URL(string: "\(serverUrl)/api/v1/schedule/get/today-nearest") else {
            throw NetworkError.invalidURL
        }
        
        // 2. 配置 Request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        // 3. 執行請求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. 檢查 HTTP 狀態碼
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.requestFailed("Invalid Server Response")
        }
        
        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.requestFailed("HTTP Status: \(httpResponse.statusCode)")
        }
        
        // 5. 解析資料
        do {
            let decodedResponse = try JSONDecoder().decode(BaseResponse<ShiftInfo>.self, from: data)
            return decodedResponse
        } catch {
            print("Decoding Error: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
}
