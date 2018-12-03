/// Page
public struct Page: Decodable {
    var id: Int
    var website_id: Int
    var url: String

    enum CodingKeys: String, CodingKey {
        case id
        case website_id
        case url
    }
}
