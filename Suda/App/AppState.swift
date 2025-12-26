//
//  AppState.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation
import SwiftData
import Observation

// 全域狀態管理
@Observable
class AppState {
    var isLoggedIn: Bool = false
}
