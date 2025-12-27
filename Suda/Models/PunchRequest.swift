import Foundation

struct PunchRequest: Encodable {
    let latitude: Double
    let longitude: Double
    let deviceUuid: String
    let type: String // "CHECK_IN" 或 "CHECK_OUT"
    let punchPointsId: String
}
