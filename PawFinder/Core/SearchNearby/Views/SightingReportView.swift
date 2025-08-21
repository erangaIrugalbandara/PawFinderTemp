import SwiftUI
import MapKit

struct SightingReportView: View {
    let pet: LostPet
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SearchNearbyViewModel.shared
    
    @State private var sightingDate = Date()
    @State private var sightingLocation = ""
    @State private var sightingDescription = ""
    @State private var reporterName = ""
    @State private var reporterContact = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showingMapPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pet Info Header
                    petInfoHeader
                    
                    // Sighting Form
                    sightingForm
                    
                    // Submit Button
                    submitButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Report Sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingMapPicker) {
            MapPickerView(
                selectedCoordinate: $selectedCoordinate,
                selectedAddress: $sightingLocation
            )
        }
    }
    
    private var petInfoHeader: some View {
        VStack(spacing: 16) {
            // Pet Photo
            if let firstPhoto = pet.photos.first, !firstPhoto.isEmpty {
                AsyncImage(url: URL(string: firstPhoto)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: pet.species.iconName)
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 120, height: 120)
                .cornerRadius(16)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .cornerRadius(16)
                    .overlay(
                        Image(systemName: pet.species.iconName)
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(spacing: 8) {
                Text(pet.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("\(pet.breed) • \(pet.species.rawValue.capitalized)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var sightingForm: some View {
        VStack(spacing: 20) {
            // Date and Time
            VStack(alignment: .leading, spacing: 8) {
                Text("When did you see \(pet.name)?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                DatePicker("Sighting Date", selection: $sightingDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            // Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Where did you see \(pet.name)?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Button(action: {
                    showingMapPicker = true
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        
                        Text(sightingLocation.isEmpty ? "Select location on map" : sightingLocation)
                            .foregroundColor(sightingLocation.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextField("What was the pet doing? Any additional details...", text: $sightingDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            
            // Reporter Info
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextField("Your name", text: $reporterName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                TextField("Your contact (phone or email)", text: $reporterContact)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            submitSighting()
        }) {
            Text("Submit Sighting Report")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
        }
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
    }
    
    private var isFormValid: Bool {
        !sightingLocation.isEmpty && !reporterName.isEmpty && !reporterContact.isEmpty
    }
    
    private func submitSighting() {
        // Here you would typically send the sighting data to your backend
        viewModel.reportSighting(for: pet)
        dismiss()
    }
}
