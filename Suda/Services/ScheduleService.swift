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
        request.timeoutInterval = 10
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
    
    func checkIsHoliday(serverUrl: String, token: String, date: String) async -> Bool? {
        // 1. 建立 URL
        let urlString = "\(serverUrl)/api/v1/holidays/get/check?date=\(date)"
        guard let url = URL(string: urlString) else { return false }
        
        var request = URLRequest(url: url)
        // 2. 設定 Header (Bearer Token)
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 檢查狀態碼
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("伺服器回傳錯誤代碼")
                return false
            }

            // 3. 解析兩層 JSON
            let decodedResponse = try JSONDecoder().decode(BaseResponse<IsHoliday>.self, from: data)
            
            if decodedResponse.data != nil {
                return decodedResponse.data?.isHoliday
            }
        } catch {
            print("解析假日 API 失敗: \(error.localizedDescription)")
        }
        
        return false
    }
}
