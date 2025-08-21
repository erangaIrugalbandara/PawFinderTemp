import Foundation
import MapKit
import CoreLocation

class SearchNearbyViewModel: NSObject, ObservableObject {
    // Singleton instance
    static let shared = SearchNearbyViewModel()

    @Published var lostPets: [LostPet] = []
    @Published var pets: [LostPet] = []
    @Published var filteredPets: [LostPet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userLocation: CLLocation?
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    @Published var selectedPet: LostPet?
    @Published var showingPetDetail = false
    @Published var showingSightingReport = false

    // Filter properties
    @Published var searchRadius: Double = 10.0 // km
    @Published var selectedSpecies: PetSpecies?
    @Published var selectedSizes: Set<PetSize> = []
    @Published var showRecentOnly = false
    @Published var showWithRewardOnly = false

    private let locationManager = CLLocationManager()

    private override init() {
        super.init()
        setupLocationManager()
        loadSampleData() // Replace with loadMockData() if mocking data
    }

    // MARK: - Setup Location Manager
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func centerMapOnUser() {
        guard let location = userLocation else { return }

        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    func selectPet(_ pet: LostPet) {
        selectedPet = pet
        showingPetDetail = true
    }

    func reportSighting(for pet: LostPet) {
        print("Sighting reported for pet: \(pet.name)")
    }

    func updateSearchRadius(_ radius: Double) {
        searchRadius = radius
        applyFilters()
    }

    func updateSpeciesFilter(_ species: PetSpecies?) {
        selectedSpecies = species
        applyFilters()
    }

    func updateSizeFilter(_ sizes: Set<PetSize>) {
        selectedSizes = sizes
        applyFilters()
    }

    func updateRecentFilter(_ showRecent: Bool) {
        showRecentOnly = showRecent
        applyFilters()
    }

    func updateRewardFilter(_ showWithReward: Bool) {
        showWithRewardOnly = showWithReward
        applyFilters()
    }

    private func applyFilters() {
        filteredPets = pets.filter { pet in
            // Species filter
            if let selectedSpecies = selectedSpecies, pet.species != selectedSpecies {
                return false
            }

            // Size filter
            if !selectedSizes.isEmpty && !selectedSizes.contains(pet.size) {
                return false
            }

            // Recent filter (last 7 days)
            if showRecentOnly {
                let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                if pet.lastSeenDate < sevenDaysAgo {
                    return false
                }
            }

            // Reward filter
            if showWithRewardOnly {
                if pet.rewardAmount == nil || pet.rewardAmount! <= 0 {
                    return false
                }
            }

            // Distance filter
            if let userLocation = userLocation {
                let distance = userLocation.distance(from: CLLocation(
                    latitude: pet.lastSeenLocation.latitude,
                    longitude: pet.lastSeenLocation.longitude
                )) / 1000 // Convert to km

                if distance > searchRadius {
                    return false
                }
            }

            return true
        }
    }

    func filterPetsByLocation() {
        guard let userLocation = userLocation else {
            filteredPets = lostPets
            return
        }

        var filtered = lostPets.compactMap { pet -> LostPet? in
            let petLocation = CLLocation(latitude: pet.lastSeenLocation.latitude, longitude: pet.lastSeenLocation.longitude)
            let distance = userLocation.distance(from: petLocation) / 1000 // Convert to km

            guard distance <= searchRadius else { return nil }

            var updatedPet = pet
            updatedPet.distanceFromUser = distance
            return updatedPet
        }

        if let selectedSpecies = selectedSpecies {
            filtered = filtered.filter { $0.species == selectedSpecies }
        }

        filtered.sort { $0.distanceFromUser ?? 0 < $1.distanceFromUser ?? 0 }
        filteredPets = filtered
    }

    func addReportedPet(_ report: PetReport) {
        let newPet = LostPet(
            id: UUID().uuidString,
            name: report.petName,
            breed: report.breed,
            species: PetSpecies(rawValue: report.petType.rawValue) ?? .other,
            age: Int(report.petAge) ?? 0,
            color: report.petColor,
            size: PetSize(rawValue: report.petSize) ?? .medium,
            description: report.description,
            lastSeenLocation: LocationData(
                latitude: report.lastSeenLocation.latitude,
                longitude: report.lastSeenLocation.longitude,
                address: report.lastSeenLocation.address,
                city: "",
                state: ""
            ),
            lastSeenDate: report.lastSeenDate,
            contactInfo: ContactInfo(
                phone: "",
                email: "",
                preferredContactMethod: .both
            ),
            ownerName: "",
            photos: report.photos,
            isActive: true,
            reportedDate: report.dateReported,
            rewardAmount: Double(report.reward ?? "") ?? nil,
            distinctiveFeatures: [],
            temperament: ""
        )

        lostPets.append(newPet)
        filterPetsByLocation()
    }

    @MainActor
    func loadNearbyPets() async {
        guard let userLocation = userLocation else { return }

        isLoading = true
        errorMessage = nil

        // Simulate loading nearby pets
        await Task.sleep(2 * 1_000_000_000) // Simulate 2-second delay
        pets = [] // Clear previous list and load new pets
        applyFilters()

        isLoading = false
    }

    // MARK: - Sample Data
    private func loadSampleData() {
        pets = [
            LostPet(
                id: "1",
                name: "Buddy",
                breed: "Golden Retriever",
                species: .dog,
                age: 3,
                color: "Golden",
                size: .large,
                description: "Friendly golden retriever, very social",
                lastSeenLocation: LocationData(
                    latitude: 37.7849,
                    longitude: -122.4094,
                    address: "Golden Gate Park, San Francisco",
                    city: "San Francisco",
                    state: "CA"
                ),
                lastSeenDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                contactInfo: ContactInfo(
                    phone: "(555) 123-4567",
                    email: "owner@email.com",
                    preferredContactMethod: .phone
                ),
                ownerName: "Sarah Johnson",
                photos: ["buddy1"],
                isActive: true,
                reportedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                rewardAmount: 500.0,
                distinctiveFeatures: ["Blue collar", "Scar on left ear"],
                temperament: "Friendly and energetic"
            )
        ]

        applyFilters()
    }
}

// MARK: - CLLocationManagerDelegate
extension SearchNearbyViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        userLocation = location
        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )

        Task {
            await loadNearbyPets()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            errorMessage = "Location access is required to find nearby pets"
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }
}

// MARK: - PetReport Type
struct PetReport {
    let petName: String
    let petType: PetSpecies
    let breed: String
    let description: String
    let lastSeenDate: Date
    let petAge: String
    let petSize: String
    let petColor: String
    let photos: [String]
    let reward: String?
    let dateReported: Date
}
