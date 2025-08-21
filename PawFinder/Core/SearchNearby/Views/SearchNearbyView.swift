import SwiftUI
import MapKit

struct SearchNearbyView: View {
    @StateObject private var viewModel = SearchNearbyViewModel.shared
    @StateObject private var locationManager = LocationManager()
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    VStack {
                        ProgressView("Loading lost pets...")
                            .scaleEffect(1.2)
                        Text("Searching for pets in your area")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Oops! Something went wrong")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Try Again") {
                            viewModel.loadPetsFromDatabase()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Map View - Fixed parameters
                        MapView(
                            region: $viewModel.mapRegion,
                            pets: viewModel.filteredPets,
                            userLocation: locationManager.currentLocation,
                            onPetSelected: { pet in
                                viewModel.selectPet(pet)
                            }
                        )
                        .frame(height: 300)
                        
                        // Pet List
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Lost Pets Nearby")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingFilters = true
                                }) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 12)
                            
                            if viewModel.filteredPets.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "pawprint.circle")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    
                                    Text("No lost pets found in your area")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    Text("Try adjusting your search filters or check back later")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.filteredPets) { pet in
                                            // Fixed PetCardView - using custom implementation
                                            PetListCardView(pet: pet) {
                                                viewModel.showPetDetail(pet)
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationTitle("Search Nearby")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.loadPetsFromDatabase()
            }
        }
        .onAppear {
            viewModel.requestLocationPermission()
            viewModel.loadPetsFromDatabase()
        }
        .sheet(isPresented: $showingFilters) {
            FilterView()
        }
        .sheet(isPresented: $viewModel.showingPetDetail) {
            if let pet = viewModel.selectedPet {
                PetDetailView(pet: pet)
            }
        }
        .sheet(isPresented: $viewModel.showingSightingReport) {
            if let pet = viewModel.selectedPet {
                SightingReportView(pet: pet)
            }
        }
    }
}

// MARK: - Custom Pet List Card View
struct PetListCardView: View {
    let pet: LostPet
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Pet Photo
                AsyncImage(url: URL(string: pet.photos.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: pet.species.iconName)
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .cornerRadius(12)
                .clipped()
                
                // Pet Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(pet.breed) • \(pet.species.rawValue)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Last seen: \(pet.lastSeenLocation.address)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(pet.species.emoji)
                            .font(.system(size: 16))
                        
                        if let rewardAmount = pet.rewardAmount, rewardAmount > 0 {
                            Text("$\(Int(rewardAmount)) reward")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Distance and Arrow
                VStack(alignment: .trailing, spacing: 4) {
                    if let distance = pet.distanceFromUser, distance > 0 {
                        Text(String(format: "%.1f mi", distance))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SearchNearbyView()
}
