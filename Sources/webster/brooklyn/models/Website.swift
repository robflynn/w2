/// Website
public struct Website: Decodable {
    var id: Int
    var name: String
    var url: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
    }
}
