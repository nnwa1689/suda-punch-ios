import Foundation

struct PunchPoint: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let latitude: String
    let longitude: String
    let radiusMeters: String
    let isActive: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude
        case radiusMeters = "radius_meters"
        case createdAt = "created_at"
        case isActive = "is_active"
    }
}
