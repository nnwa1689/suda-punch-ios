import Foundation

struct PunchResult: Decodable {
    let punchId: String
    let punchTime: String
    let remark: String?

    enum CodingKeys: String, CodingKey {
        case remark
        case punchId = "punch_id"
        case punchTime = "punch_time"
    }
}
