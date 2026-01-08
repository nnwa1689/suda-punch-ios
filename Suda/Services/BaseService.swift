//
//  UserService.swift
//  Suda
//
//  Created by Hazuya on 2026/1/4.
//

import Foundation

struct BaseService
{
    func getSystemBaseInfo(serverUrl: String, token: String, baseId: String) async throws -> BaseResponse<BaseData> {
        guard let url = URL(string: "\(serverUrl)/api/v1/common/base/\(baseId)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(BaseResponse<BaseData>.self, from: data)
        return decoded
    }
}
