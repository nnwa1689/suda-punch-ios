//
//  Extensions.swift
//  Suda
//
//  Created by Hazuya on 2025/12/30.
//

import Foundation
import SwiftUI

extension Color {
    // 💡 使用 static let，讓全域都能存取且不佔用重複記憶體
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let textSecondary = Color.gray
    static let bgColor = Color(red: 243/255, green: 244/255, blue: 246/255)
    static let cardBgColor = Color(red: 1, green: 1, blue: 1)
    static let primaryBlue = Color(red: 45/255, green: 212/255, blue: 191/255)
    
    static let bgColorDark = Color(red: 255, green: 255, blue: 255)
    static let cardBgColorDark = Color(red: 0.08, green: 0.06, blue: 0.04)
}

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // 格式化輸出：1.0.1 (Build 5)
    var fullVersionString: String {
        return "\(appVersion) (Build \(buildNumber))"
    }
}
