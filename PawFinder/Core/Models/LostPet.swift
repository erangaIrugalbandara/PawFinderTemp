//import Foundation
//
//struct LostPet: Identifiable {
//    let id: String
//    let name: String
//    let breed: String
//    let species: PetSpecies
//    let age: Int
//    let color: String
//    let size: PetSize
//    let description: String
//    let lastSeenLocation: LocationData
//    let lastSeenDate: Date
//    let contactInfo: ContactInfo
//    let ownerName: String
//    let photos: [String]
//    let isActive: Bool
//    let reportedDate: Date
//    let rewardAmount: Double?
//    let distinctiveFeatures: [String]
//    let temperament: String
//
//    var distanceFromUser: Double?
//
//}
//
////extension LostPet {
////    func toDictionary() -> [String: Any] {
////        return [
////            "id": id,
////            "name": name,
////            "breed": breed,
////            "species": species.rawValue,
////            "age": age,
////            "color": color,
////            "size": size.rawValue,
////            "description": description,
////            "lastSeenLocation": [
////                "latitude": lastSeenLocation.latitude,
////                "longitude": lastSeenLocation.longitude,
////                "address": lastSeenLocation.address,
////                "city": lastSeenLocation.city,
////                "state": lastSeenLocation.state
////            ],
////            "lastSeenDate": lastSeenDate,
////            "contactInfo": [
////                "phone": contactInfo.phone,
////                "email": contactInfo.email,
////                "preferredContactMethod": contactInfo.preferredContactMethod.rawValue
////            ],
////            "ownerName": ownerName,
////            "photos": photos,
////            "isActive": isActive,
////            "reportedDate": reportedDate,
////            "rewardAmount": rewardAmount ?? 0.0,
////            "distinctiveFeatures": distinctiveFeatures,
////            "temperament": temperament
////        ]
////    }
////}


import Foundation
import CoreLocation

struct LostPet: Identifiable, Codable {
    let id: String
    let name: String
    let breed: String
    let species: PetSpecies
    let age: Int
    let color: String
    let size: PetSize
    let description: String
    let lastSeenLocation: LocationData
    let lastSeenDate: Date
    let contactInfo: ContactInfo
    let isActive: Bool
    let reportedDate: Date
    let rewardAmount: Double?
    let distinctiveFeatures: [String]
    let temperament: String
}
