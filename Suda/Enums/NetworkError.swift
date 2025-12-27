import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(String)
    case unauthorized
    case decodingError(Error)
    case noData
    
    // 提供人類可讀的錯誤訊息（選填）
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無效的網址"
        case .requestFailed(let message): return "請求失敗: \(message)"
        case .unauthorized: return "驗證過期，請重新登入"
        case .decodingError: return "資料解析錯誤"
        case .noData: return "伺服器未回傳資料"
        }
    }
}
