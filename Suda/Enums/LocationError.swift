import Foundation

enum LocationError: Error, LocalizedError {
    case denied       // 使用者拒絕或系統限制定位
    case unavailable  // 已授權但收不到位置訊號
    case timeout      // 等待定位逾時
    case busy         // 上一次定位尚未完成

    var errorDescription: String? {
        switch self {
        case .denied: return "未授權定位，請至「設定 > 隱私權與安全性 > 定位服務」開啟速打的定位權限"
        case .unavailable: return "無法取得位置訊號，請移至訊號較佳處後再試"
        case .timeout: return "取得定位逾時，請稍後再試"
        case .busy: return "正在取得定位，請稍候"
        }
    }
}
