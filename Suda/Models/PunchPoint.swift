import Foundation

struct PunchPoint: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let latitude: String
    let longitude: String
    let radiusMeters: String
    let isActive: Bool
    let createdAt: String
    let bluetoothServiceUuid: String?
    let wifiSsid: String?
    let wifiBssidList: Array<String>?
    let verifyType: String?

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude
        case radiusMeters = "radius_meters"
        case createdAt = "created_at"
        case isActive = "is_active"
        case bluetoothServiceUuid = "bluetooth_service_uuid"
        case wifiSsid = "wifi_ssid"
        case wifiBssidList = "wifi_bssid_list"
        case verifyType = "verify_type"
    }
}
