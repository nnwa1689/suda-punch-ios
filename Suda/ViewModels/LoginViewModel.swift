import Foundation
import SwiftData
import Observation
import UIKit

@Observable
@MainActor
class LoginViewModel {
    // --- UI 雙向綁定變數 (必須與 View 中的 $ 符號對應) ---
    var serverAddress: String = ""
    var username: String = ""
    var password: String = ""
    var rememberMe: Bool = false
    
    // --- 狀態控制 (View 監控這些值的變化來更新 UI) ---
    var isLoading: Bool = false
    var showAlert: Bool = false        // 用於一般錯誤提示
    var showBindAlert: Bool = false    // 用於二階段確認綁定
    var errorMessage: String = ""      // 錯誤訊息內容
    var isLoginSuccess: Bool = false
    
    // --- 內部邏輯變數 ---
    var tempToken: String = ""
    var fullServerUrl: String = ""
    
    private let authService = AuthService()

    // --- 第一階段：登入 ---
    @MainActor
    func startLoginProcess(protocolPrefix: String) async {
        self.isLoading = true
        self.errorMessage = ""
        self.fullServerUrl = "\(protocolPrefix)\(serverAddress)"
        
        do {
            let result = try await authService.login(
                serverUrl: self.fullServerUrl,
                params: ["username": username, "password": password]
            )
            
            // 根據 LoginResponse 結構，拿到 token 後存入 tempToken
            if let token = result.data?.accessToken {
                self.tempToken = token
                self.isLoading = false
                self.showBindAlert = true // 彈出「確定綁定？」的 Alert
            }
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showAlert = true // 彈出錯誤訊息 Alert
        }
    }

    // --- 第二階段：綁定裝置 ---
    @MainActor
    func confirmBinding(modelContext: ModelContext) async {
        self.isLoading = true
        
        do {
            let result = try await authService.bindDevice(
                serverUrl: self.fullServerUrl,
                token: self.tempToken,
                employeeId: self.username
            )
            
            if result.success == true {
                // 成功後寫入 SwiftData
                let auth = AuthData(
                    userId: self.username,
                    token: self.tempToken,
                    serverUrl: self.fullServerUrl
                )
                modelContext.insert(auth)
                try? modelContext.save()
                
                self.isLoading = false
                self.isLoginSuccess = true
            }
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showAlert = true
        }
    }
}
