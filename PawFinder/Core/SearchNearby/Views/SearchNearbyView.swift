import SwiftUI
import MapKit

struct SearchNearbyView: View {
    @StateObject private var viewModel = SearchNearbyViewModel.shared
    @State private var showingFilters = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Map View
            MapView(
                region: $viewModel.mapRegion,
                pets: viewModel.filteredPets,
                userLocation: viewModel.userLocation,
                onPetSelected: { pet in
                    viewModel.selectPet(pet)
                }
            )
            .ignoresSafeArea(edges: .top)
            
            // Top Controls
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(22)
                    }
                    
                    Spacer()
                    
                    Text("Search Nearby")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    Button(action: {
                        showingFilters = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(22)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                HStack {
                    Button(action: {
                        viewModel.centerMapOnUser()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .cornerRadius(22)
                            .shadow(radius: 2)
                    }
                    
                    Spacer()
                    
                    if !viewModel.filteredPets.isEmpty {
                        Text("\(viewModel.filteredPets.count) pets found")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Finding nearby pets...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(30)
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView()
        }
        .sheet(isPresented: $viewModel.showingPetDetail) {
            if let pet = viewModel.selectedPet {
                PetDetailView(pet: pet)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingSightingReport) {
            if let pet = viewModel.selectedPet {
                SightingReportView(pet: pet)
            }
        }
        .alert("Thank You! 🎉", isPresented: $viewModel.showingSightingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your sighting report has been submitted successfully! You're helping reunite pets with their families.")
        }
        .onAppear {
            viewModel.requestLocationPermission()
        }
        .alert("Location Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    SearchNearbyView()
}
