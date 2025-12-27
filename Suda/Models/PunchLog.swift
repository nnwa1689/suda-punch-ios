import Foundation

struct PunchLog: Decodable {
    let id: String
    let employeeId: String
    let punchTime: String
    let recordedLat: String
    let recordedLng: String
    let punchPointsId: String
    let punchType: String    // "CHECK_IN" 或 "CHECK_OUT"
    let isLate: Bool
    let isEarly: Bool
    let remark: String?
    let punchPoint: PunchPoint?

    enum CodingKeys: String, CodingKey {
        case id, remark, punchPoint
        case employeeId = "employee_id"
        case punchTime = "punch_time"
        case recordedLat = "recorded_lat"
        case recordedLng = "recorded_lng"
        case punchPointsId = "punch_points_id"
        case punchType = "punch_type"
        case isLate = "is_late"
        case isEarly = "is_early"
    }
}
