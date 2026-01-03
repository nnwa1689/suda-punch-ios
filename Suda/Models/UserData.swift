//
//  AuthData.swift
//  Suda
//
//  Created by Hazuya on 2025/12/27.
//

import Foundation
import SwiftData

struct UserData: Decodable {
    let userId: String
    let username: String
    let isActive: Bool
    let isAdmin: Bool
}
