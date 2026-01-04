import Foundation
import Observation
import SwiftData

@Observable
@MainActor
class MainHomeViewModel {
    private let authService = AuthService()
    private let userService = UserService()
    var apiIsOnline = false
    var userIsActive = false
    var isLoading = true
    var auth: AuthData
    
    init(auth: AuthData) {
        self.auth = auth
    }
    
    func apiTets() async {
        self.isLoading = true
        defer { self.isLoading = false }
        do {
            // 2. 呼叫 API (需在你的 PunchService 實作對應 POST 方法)
            let response = try await authService.fetchApiInfo(baseURL: self.auth.serverUrl)
            
            if response.data != nil {
                print("api連線成功")
                self.apiIsOnline = true
            }
        } catch {
            print("api連線失敗: \(error)")
        }
    }
    
    func fetchSelfUserInfo() async {
        self.isLoading = true
        defer { self.isLoading = false }
        do {
            let userInfo = try await userService.getSelfUser(serverUrl: self.auth.serverUrl, token: self.auth.token)
            
            if userInfo.statusCode == 200 && userInfo.data?.activeDeviceUuid == self.auth.deviceUuid {
                self.userIsActive = true
            }
            
        } catch {
            self.userIsActive = false
        }
    }
}
