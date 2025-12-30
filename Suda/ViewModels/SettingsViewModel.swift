import Foundation
import Observation
import SwiftData

@Observable
@MainActor
class SettingsViewModel {
    private let employeeService = EmployeeService()
    var employee: EmployeeData?
    var isLoading = false
    var errorMessage: String?
    
    var hireDate = ""
    //var accountID: String
    //var loginType = "LocalDB / OAuthAPI"
    var appVersion = ""
    var employeeName = ""
    
    var serverUrl: String = ""
    var userToken: String = ""
    var employeeId: String = ""
    var deviceUuid: String = ""
    
    // 初始化時直接注入資料
    init(auth: AuthData) {
        self.serverUrl = auth.serverUrl
        self.userToken = auth.token
        self.employeeId = auth.userId
        self.deviceUuid = auth.deviceUuid ?? ""
        self.appVersion = auth.appVersion
        
        Task {
            await fetchEmployeeInfo()
        }
    }

    // 格式化到職日期
    var formattedArrival: String {
        guard let arrival = employee?.arrival else { return "尚未設定" }
        // 處理 ISO8601 格式
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        if let date = formatter.date(from: arrival) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy/MM/dd"
            return displayFormatter.string(from: date)
        }
        return arrival
    }

    func fetchEmployeeInfo() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let reps = try await employeeService.getEmployeeInfo(empId: employeeId, token: userToken, serverUrl: serverUrl)
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
            dateFormatter.dateFormat = "yyyy/MM/dd EEEE"
            
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let emp = reps.data {
                self.employeeName = emp.name
                if let date = isoFormatter.date(from: emp.arrival ?? ""){
                    self.hireDate = dateFormatter.string(from: date)
                }
            }
            
        } catch {
            self.errorMessage = "抓取失敗: \(error.localizedDescription)"
            print("DEBUG: \(error)")
        }
    }
}
