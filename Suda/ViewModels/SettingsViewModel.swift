import Foundation
import Observation
import SwiftData

@Observable
@MainActor
class SettingsViewModel {
    private let employeeService = EmployeeService()
    private let authService = AuthService()
    
    var employee: EmployeeData?
    var isLoading = false
    var errorMessage: String?
    var showAlert = false
    
    var hireDate = ""
    //var accountID: String
    //var loginType = "LocalDB / OAuthAPI"
    var appVersion = ""
    var employeeName = ""
    
    var serverUrl: String = ""
    var userToken: String = ""
    var employeeId: String = ""
    var deviceUuid: String = ""
    
    var isUnbinding = false
    var unbindMessage: String = ""
    var apiVersion: String = ""
    
    // 初始化時直接注入資料
    init(auth: AuthData) {
        self.serverUrl = auth.serverUrl
        self.userToken = auth.token
        self.employeeId = auth.userId
        self.deviceUuid = auth.deviceUuid ?? ""
        
        Task {
            await fetchEmployeeInfo()
            await checkApiVersion()
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
    
    func performUnbind() async -> Bool {
        await MainActor.run { self.isUnbinding = true }
                
        defer {
            // 結束時關閉轉圈圈
            Task { @MainActor in self.isUnbinding = false }
        }
        
        do {
            let (success, message) = try await authService.unbindDevice(
                baseURL: self.serverUrl,
                empId: self.employeeId,
                uuid: self.deviceUuid,
                token: self.userToken
            )
            
            if !success {
                await MainActor.run {
                    isUnbinding = false
                    self.errorMessage = message
                    self.showAlert = true
                }
            }
            return success
        } catch {
            await MainActor.run {
                isUnbinding = false
                self.errorMessage = "網路連線異常"
                self.showAlert = true
            }
            return false
        }
    }
    
    func checkApiVersion() {
        Task {
            do {
                let version = try await authService.fetchApiInfo(baseURL: self.serverUrl)
                await MainActor.run {
                    self.apiVersion = version
                    print("成功連線 API，版本：\(version)")
                }
            } catch {
                print("API 請求失敗：\(error)")
            }
        }
    }
}
