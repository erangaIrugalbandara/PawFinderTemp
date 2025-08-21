import Foundation

struct LocationData: Decodable {
    let latitude: Double
    let longitude: Double
    let address: String
    let city: String
    let state: String

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case address
        case city
        case state
    }
}
