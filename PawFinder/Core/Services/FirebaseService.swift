import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit
import CoreLocation

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func submitLostPetReport(report: LostPet) async throws {
        let data: [String: Any] = [
            "id": report.id,
            "name": report.name,
            "breed": report.breed,
            "species": report.species.rawValue,
            "age": report.age,
            "color": report.color,
            "size": report.size.rawValue,
            "description": report.description,
            "lastSeenLocation": [
                "latitude": report.lastSeenLocation.latitude,
                "longitude": report.lastSeenLocation.longitude,
                "address": report.lastSeenLocation.address
            ],
            "lastSeenDate": report.lastSeenDate,
            "contactInfo": [
                "phone": report.contactInfo.phone,
                "email": report.contactInfo.email,
                "preferredContactMethod": report.contactInfo.preferredContactMethod.rawValue
            ],
            "isActive": report.isActive,
            "reportedDate": report.reportedDate,
            "rewardAmount": report.rewardAmount ?? 0.0,
            "distinctiveFeatures": report.distinctiveFeatures,
            "temperament": report.temperament
        ]

        try await db.collection("lostPets").document(report.id).setData(data)
    }
    
    func fetchLostPets(nearLocation: LocationData, radius: Double) async throws -> [LostPet] {
        let snapshot = try await db.collection("lost_pets")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        let pets = try snapshot.documents.compactMap { document in
            try document.data(as: LostPet.self) // Requires LostPet to conform to Decodable
        }
        
        return pets.filter { pet in
            let distance = calculateDistance(
                from: CLLocationCoordinate2D(latitude: nearLocation.latitude, longitude: nearLocation.longitude),
                to: CLLocationCoordinate2D(latitude: pet.lastSeenLocation.latitude, longitude: pet.lastSeenLocation.longitude)
            )
            return distance <= radius * 1000 // Convert km to meters
        }
    }
    
    func fetchUserPets(userId: String) async throws -> [LostPet] {
        let snapshot = try await db.collection("lost_pets")
            .whereField("ownerID", isEqualTo: userId)
            .order(by: "reportedDate", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: LostPet.self) // Requires LostPet to conform to Decodable
        }
    }
    
    func updatePetStatus(petId: String, isActive: Bool) async throws {
        try await db.collection("lost_pets").document(petId).updateData([
            "isActive": isActive,
            "foundDate": isActive ? FieldValue.delete() : FieldValue.serverTimestamp()
        ])
    }
    
    func submitSighting(_ sighting: PetSighting) async throws {
        try await db.collection("sightings").document(sighting.id).setData(from: sighting) // Requires PetSighting to conform to Encodable
        
        let petRef = db.collection("lost_pets").document(sighting.petId)
        try await petRef.updateData([
            "sightingCount": FieldValue.increment(Int64(1)),
            "lastSightingDate": sighting.sightingDate
        ])
    }
    
    func fetchSightings(for petId: String) async throws -> [PetSighting] {
        let snapshot = try await db.collection("sightings")
            .whereField("petId", isEqualTo: petId)
            .order(by: "sightingDate", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: PetSighting.self) // Requires PetSighting to conform to Decodable
        }
    }
    
    func updateUserProfile(_ user: User) async throws {
        try await db.collection("users").document(user.id).setData(from: user, merge: true)
    }
    
    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> String {
        let path = "profile_photos/\(userId)/profile.jpg"
        return try await uploadImage(image, path: path)
    }
    
    private func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FirebaseServiceError.imageCompressionFailed
        }
        
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
}

enum FirebaseServiceError: LocalizedError {
    case imageCompressionFailed
    case uploadFailed
    case dataNotFound
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .uploadFailed:
            return "Failed to upload to server"
        case .dataNotFound:
            return "Requested data not found"
        }
    }
}
