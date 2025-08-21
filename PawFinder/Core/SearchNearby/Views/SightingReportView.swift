import SwiftUI
import CoreLocation
import MapKit

struct SightingReportView: View {
    @State private var selectedConfidence: SightingConfidence = .medium
    @State private var description = ""
    @State private var reporterName = ""
    @State private var reporterContact = ""
    @State private var sightingLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @State private var selectedDate = Date()
    @State private var showingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    
    let pet: LostPet
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pet Info Header
                    petInfoSection
                    
                    // Sighting Details Form
                    sightingDetailsForm
                    
                    // Submit Button
                    submitButton
                }
                .padding()
            }
            .navigationTitle("Report Sighting")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Sighting Reported!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for reporting this sighting. The pet owner has been notified.")
        }
    }
    
    // MARK: - Pet Info Section
    private var petInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                // Pet Species Icon
                Image(systemName: pet.species.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(pet.breed) • \(pet.species.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Lost: \(formatDate(pet.lastSeenDate))")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Sighting Details Form
    private var sightingDetailsForm: some View {
        VStack(spacing: 20) {
            // Confidence Level
            VStack(alignment: .leading, spacing: 8) {
                Text("How confident are you?")
                    .font(.headline)
                
                Picker("Confidence", selection: $selectedConfidence) {
                    ForEach(SightingConfidence.allCases, id: \.self) { confidence in
                        Text(confidence.rawValue).tag(confidence)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Date and Time
            VStack(alignment: .leading, spacing: 8) {
                Text("When did you see this pet?")
                    .font(.headline)
                
                DatePicker("Sighting Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            // Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Where did you see this pet?")
                    .font(.headline)
                
                Button(action: {
                    // TODO: Implement location picker
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Select Location")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .foregroundColor(.primary)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            // Contact Information
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Contact Information")
                    .font(.headline)
                
                TextField("Your Name", text: $reporterName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Phone or Email", text: $reporterContact)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Photos Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Photos (Optional)")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Add Photo Button
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .foregroundColor(.blue)
                        }
                        
                        // Selected Images
                        ForEach(0..<selectedImages.count, id: \.self) { index in
                            Image(uiImage: selectedImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: submitSighting) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isSubmitting ? "Submitting..." : "Submit Sighting Report")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isSubmitting)
    }
    
    // MARK: - Helper Properties
    private var isFormValid: Bool {
        !reporterName.isEmpty && !reporterContact.isEmpty && !description.isEmpty
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func submitSighting() {
        isSubmitting = true
        
        // TODO: Implement actual submission logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSubmitting = false
            showingSuccessAlert = true
        }
    }
}

// MARK: - Preview
struct SightingReportView_Previews: PreviewProvider {
    static var previews: some View {
        SightingReportView(
            pet: LostPet(
                id: "1",
                name: "Buddy",
                breed: "Golden Retriever",
                species: .dog,
                age: 3,
                color: "Golden",
                size: .large,
                description: "Friendly golden retriever",
                lastSeenLocation: LocationData(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    address: "San Francisco, CA",
                    city: "San Francisco",
                    state: "CA"
                ),
                lastSeenDate: Date(),
                contactInfo: ContactInfo(
                    phone: "(555) 123-4567",
                    email: "owner@email.com",
                    preferredContactMethod: .phone
                ),
                ownerName: "John Doe",
                photos: [],
                isActive: true,
                reportedDate: Date(),
                rewardAmount: 500.0,
                distinctiveFeatures: ["Blue collar"],
                temperament: "Friendly"
            )
        )
    }
}
