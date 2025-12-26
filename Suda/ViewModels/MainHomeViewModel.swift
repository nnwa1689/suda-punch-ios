import Foundation
import Observation

@Observable
class MainHomeViewModel {
    // 顯示內容
    var currentTime: String = ""
    var currentDate: String = ""
    var selectedLocation: String = "公司"
    var lastPunchTime: String = "8:58 AM"
    var lastPunchLocation: String = "公司"
    var expectedPunchTime: String = "9:00 AM"
    
    let locations = ["公司", "外勤-台北", "外勤-台中", "居家辦公"]
    
    init() {
        updateTime()
    }
    
    func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm aa"
        self.currentTime = formatter.string(from: Date())
        
        formatter.dateFormat = "EEEE, MMMM d"
        self.currentDate = formatter.string(from: Date())
    }
    
    func performPunchIn() {
        print("執行上班打卡於：\(selectedLocation)")
        // 未來串接 API
    }
    
    func performPunchOut() {
        print("執行下班打卡")
    }
}
