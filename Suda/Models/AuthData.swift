//
//  AuthData.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation
import SwiftData

@Model
final class AuthData {
    var userId: String
    var token: String
    var serverUrl: String
    var lastLoginDate: Date
    var deviceUuid: String?
    var appVersion = "v0.1.0 (2025/12/30)"
    
    init(userId: String, token: String, serverUrl: String, deviceUuid: String) {
        self.userId = userId
        self.token = token
        self.serverUrl = serverUrl
        self.lastLoginDate = Date()
        self.deviceUuid = deviceUuid
    }
}
