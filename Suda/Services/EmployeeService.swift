//
//  EmployeeService.swift
//  Suda
//
//  Created by Hazuya on 2025/12/30.
//
import Foundation

struct EmployeeService {
    func getEmployeeInfo(empId: String, token: String, serverUrl: String) async throws -> BaseResponse<EmployeeData> {
        
        guard let url = URL(string: "\(serverUrl)/api/v1/employee/\(empId)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.requestFailed("無法取得員工")
        }
        
        return try JSONDecoder().decode(BaseResponse<EmployeeData>.self, from: data)
    }
}
