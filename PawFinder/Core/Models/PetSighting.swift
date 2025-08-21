//import Foundation
//import CoreLocation
//
//struct PetSighting: Identifiable, Decodable {
//    let id: String
//    let petId: String
//    let sightingDate: Date
//    let location: LocationData
//    let description: String
//
////    private enum CodingKeys: String, CodingKey {
////        case id
////        case petId
////        case sightingDate
////        case location
////        case description
////    }
////
////    // Custom initializer to decode sightingDate with a specific format
////    init(from decoder: Decoder) throws {
////        let container = try decoder.container(keyedBy: CodingKeys.self)
////
////        id = try container.decode(String.self, forKey: .id)
////        petId = try container.decode(String.self, forKey: .petId)
////        description = try container.decode(String.self, forKey: .description)
////        location = try container.decode(LocationData.self, forKey: .location)
////
////        // Custom date decoding
////        let dateString = try container.decode(String.self, forKey: .sightingDate)
////        let formatter = DateFormatter()
////        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // Specify your JSON date format here
////        guard let date = formatter.date(from: dateString) else {
////            throw DecodingError.dataCorruptedError(forKey: .sightingDate, in: container, debugDescription: "Invalid date format")
////        }
////        sightingDate = date
////    }
//}


import Foundation
import CoreLocation

struct PetSighting: Identifiable, Codable {
    let id: String
    let petId: String
    let sightingDate: Date
    let location: LocationData
    let description: String
}
