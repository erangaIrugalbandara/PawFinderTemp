import Foundation
import SwiftUI

class MyReportsViewModel: ObservableObject {
    @Published var userPets: [LostPet] = []
    @Published var userSightings: [PetSighting] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService()
    
    func loadUserData(userId: String) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadUserPets(userId: userId)
            }
            
            group.addTask {
                await self.loadUserSightings(userId: userId)
            }
        }
    }
    
    @MainActor
    private func loadUserPets(userId: String) async {
        isLoading = true
        
        do {
            userPets = try await firebaseService.fetchUserPets(userId: userId)
        } catch {
            errorMessage = "Failed to load your pets: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadUserSightings(userId: String) async {
        // This would need a new Firebase method to fetch sightings by reporter
        // For now, using empty array
        userSightings = []
    }
    
    @MainActor
    func markPetAsFound(petId: String) async {
        do {
            try await firebaseService.updatePetStatus(petId: petId, isActive: false)
            
            // Update local data
            if let index = userPets.firstIndex(where: { $0.id == petId }) {
                var updatedPet = userPets[index]
                userPets[index] = LostPet(
                    id: updatedPet.id,
                    name: updatedPet.name,
                    breed: updatedPet.breed,
                    species: updatedPet.species,
                    age: updatedPet.age,
                    color: updatedPet.color,
                    size: updatedPet.size,
                    description: updatedPet.description,
                    lastSeenLocation: updatedPet.lastSeenLocation,
                    lastSeenDate: updatedPet.lastSeenDate,
                    contactInfo: updatedPet.contactInfo,
                    ownerName: updatedPet.ownerName,
                    photos: updatedPet.photos,
                    isActive: false,
                    reportedDate: updatedPet.reportedDate,
                    rewardAmount: updatedPet.rewardAmount,
                    distinctiveFeatures: updatedPet.distinctiveFeatures,
                    temperament: updatedPet.temperament
                )
            }
        } catch {
            errorMessage = "Failed to update pet status: \(error.localizedDescription)"
        }
    }
}
