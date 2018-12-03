/// PageQueue
public struct PageQueue: Decodable {
    var pages: [Page]
    var stats: [String: Int]

    enum CodingKeys: String, CodingKey {
        case pages
        case stats
    }
}
