import SwiftUI
import MapKit

struct SightingReportView: View {
    let pet: LostPet
    let viewModel = SearchNearbyViewModel.shared // Use the shared singleton instance
    @Environment(\.dismiss) private var dismiss
    
    @State private var reporterName = ""
    @State private var reporterContact = ""
    @State private var sightingDescription = ""
    @State private var confidence: SightingConfidence = .medium
    @State private var sightingDate = Date()
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var locationAddress = ""
    @State private var showingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Reporter Information
                    reporterInfoSection
                    
                    // Sighting Details
                    sightingDetailsSection
                    
                    // Location Selection
                    locationSection
                    
                    // Photos Section
                    photoSection
                    
                    // Submit Button
                    submitButton
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(images: $selectedImages)
            }
            .alert("Sighting Reported!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for reporting this sighting. The owner has been notified.")
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: pet.species.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Did you see \(pet.name)?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(pet.breed) • \(pet.color)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Missing \(pet.timeSinceLastSeen)")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
            
            Text("Your report helps bring \(pet.name) home safely. Please provide as much detail as possible.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Reporter Info Section
    private var reporterInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Your Information", icon: "person.fill")
            
            VStack(spacing: 12) {
                CustomInputField(
                    title: "Your Name",
                    text: $reporterName,
                    placeholder: "Enter your full name",
                    icon: "person"
                )
                
                CustomInputField(
                    title: "Contact Info",
                    text: $reporterContact,
                    placeholder: "Phone number or email",
                    icon: "phone"
                )
            }
        }
    }
    
    // MARK: - Sighting Details Section
    private var sightingDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Sighting Details", icon: "eye.fill")
            
            VStack(spacing: 16) {
                // Confidence Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("How confident are you?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Picker("Confidence", selection: $confidence) {
                        ForEach(SightingConfidence.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Date and Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("When did you see them?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    DatePicker("Sighting Date", selection: $sightingDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $sightingDescription)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text("Describe the pet's behavior, condition, and surroundings")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Location", icon: "location.fill")
            
            VStack(spacing: 12) {
                CustomInputField(
                    title: "Address",
                    text: $locationAddress,
                    placeholder: "Enter the address where you saw them",
                    icon: "location"
                )
                
                // Fixed Map for location selection
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: selectedLocation ?? pet.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: selectedLocation != nil ? [MapLocation(coordinate: selectedLocation!)] : []) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                Text("Tap on the map to mark the exact location")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Photo Section
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Photos (Optional)", icon: "camera.fill")
            
            if selectedImages.isEmpty {
                Button(action: {
                    showingImagePicker = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Add Photos")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Photos help verify the sighting")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<selectedImages.count, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)
                                    .clipped()
                                
                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                        
                        // Add more button
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            submitSighting()
        }) {
            if isSubmitting {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Submitting...")
                }
            } else {
                Text("Submit Sighting Report")
            }
        }
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(isFormValid ? Color.blue : Color.gray)
        .cornerRadius(12)
        .disabled(!isFormValid || isSubmitting)
    }
    
    // MARK: - Helper Properties
    private var isFormValid: Bool {
        !reporterName.isEmpty &&
        !reporterContact.isEmpty &&
        !sightingDescription.isEmpty &&
        !locationAddress.isEmpty
    }
    
    // MARK: - Actions
    private func submitSighting() {
        isSubmitting = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSubmitting = false
            showingSuccess = true
        }
    }
}

// MARK: - Helper Views
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

struct CustomInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.images.append(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    SightingReportView(
        pet: LostPet(
            id: "1",
            name: "Buddy",
            breed: "Golden Retriever",
            species: .dog,
            age: 3,
            color: "Golden",
            size: .large,
            description: "Friendly dog",
            lastSeenLocation: LocationData(
                latitude: 37.7749,
                longitude: -122.4194,
                address: "123 Oak Street",
                city: "San Francisco",
                state: "CA"
            ),
            lastSeenDate: Date(),
            contactInfo: ContactInfo(
                phone: "(555) 123-4567",
                email: "owner@email.com",
                preferredContactMethod: .phone
            ),
            ownerName: "Sarah Johnson",
            photos: [],
            isActive: true,
            reportedDate: Date(),
            rewardAmount: 500.0,
            distinctiveFeatures: [],
            temperament: "Friendly"
        )
    )
}
