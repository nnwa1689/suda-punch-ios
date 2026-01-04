//
//  UserService.swift
//  Suda
//
//  Created by Hazuya on 2026/1/4.
//

import Foundation

struct UserService
{
    func getSelfUser(serverUrl: String, token: String) async throws -> BaseResponse<UserData> {
        guard let url = URL(string: "\(serverUrl)/api/v1/users/get/self") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(BaseResponse<UserData>.self, from: data)
        return decoded
    }
}
