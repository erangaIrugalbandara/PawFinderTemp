import SwiftUI
import PhotosUI
import MapKit
import CoreLocation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct ReportLostPetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    
    // Pet Information
    @State private var petName = ""
    @State private var selectedSpecies: PetSpecies = .dog
    @State private var breed = ""
    @State private var petDescription = ""
    
    // Photos
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var showingPhotoPicker = false
    
    // Location
    @State private var useCurrentLocation = true
    @State private var customLocation = ""
    @State private var showingMapPicker = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress = ""
    
    // Additional Fields
    @State private var lastSeenDate = Date()
    @State private var petAge = ""
    @State private var petSize: PetSize = .medium
    @State private var petColor = ""
    @State private var reward = ""
    @State private var contactInfo = ""
    @State private var distinctiveFeatures = ""
    
    // UI State
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.3, blue: 0.8),
                        Color(red: 0.6, green: 0.4, blue: 0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Report Lost Pet")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Help the community find your pet by providing detailed information.")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        
                        // Pet Details Form
                        Group {
                            TextField("Pet Name", text: $petName)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            Picker("Species", selection: $selectedSpecies) {
                                ForEach(PetSpecies.allCases, id: \.self) { species in
                                    Text(species.rawValue).tag(species)
                                }
                            }.pickerStyle(SegmentedPickerStyle())
                            
                            TextField("Breed", text: $breed)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            TextField("Age (in years)", text: $petAge)
                                .keyboardType(.numberPad)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            Picker("Size", selection: $petSize) {
                                ForEach(PetSize.allCases, id: \.self) { size in
                                    Text(size.rawValue).tag(size)
                                }
                            }.pickerStyle(MenuPickerStyle())
                            
                            TextField("Color", text: $petColor)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            TextField("Distinctive Features", text: $distinctiveFeatures)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            TextField("Reward (optional)", text: $reward)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            TextField("Contact Info", text: $contactInfo)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Description
                        TextField("Description", text: $petDescription, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        // Last Seen Location
                        Toggle("Use Current Location", isOn: $useCurrentLocation)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        if !useCurrentLocation {
                            Button(action: {
                                showingMapPicker = true
                            }) {
                                Text("Select Location on Map")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Photo Picker
                        PhotosPicker(selection: $selectedPhotos, matching: .images) {
                            Label("Select Photos", systemImage: "photo")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .onChange(of: selectedPhotos) { _ in loadSelectedPhotos() }
                        
                        // Submit Button
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding()
                        } else {
                            Button(action: submitReport) {
                                Text("Submit Report")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .disabled(!isFormValid)
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingMapPicker) {
                MapPickerView(selectedCoordinate: $selectedCoordinate, selectedAddress: $selectedAddress)
            }
            .alert("Report Submitted", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { dismiss() }
            } message: {
                Text("Your lost pet report has been successfully submitted.")
            }
        }
    }
    
    private var isFormValid: Bool {
        !petName.isEmpty && !breed.isEmpty && !petDescription.isEmpty && !contactInfo.isEmpty
    }
    
    private func loadSelectedPhotos() {
        Task {
            photoImages.removeAll()
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        photoImages.append(image)
                    }
                }
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        let locationData = LocationData(
            latitude: selectedCoordinate?.latitude ?? locationManager.currentLocation?.coordinate.latitude ?? 0.0,
            longitude: selectedCoordinate?.longitude ?? locationManager.currentLocation?.coordinate.longitude ?? 0.0,
            address: customLocation.isEmpty ? selectedAddress : customLocation,
            city: "Unknown",
            state: "Unknown"
        )
        
        // Upload photos and then save the report
        uploadPhotos { photoURLs, error in
            if let error = error {
                errorMessage = "Photo upload failed: \(error.localizedDescription)"
                isSubmitting = false
                return
            }
            
            let contactInfoStruct = ContactInfo(
                phone: contactInfo.isEmpty ? "(555) 123-4567" : contactInfo,
                email: "owner@example.com", // You may want to add an email field to your form
                preferredContactMethod: .phone
            )

            let lostPet = LostPet(
                id: UUID().uuidString,
                name: petName,
                breed: breed,
                species: selectedSpecies,
                age: Int(petAge) ?? 0,
                color: petColor,
                size: petSize,
                description: petDescription,
                lastSeenLocation: locationData,
                lastSeenDate: lastSeenDate,
                contactInfo: contactInfoStruct,
                ownerName: "Pet Owner", // You may want to add an owner name field
                photos: photoURLs ?? [],
                isActive: true,
                reportedDate: Date(),
                rewardAmount: Double(reward),
                distinctiveFeatures: distinctiveFeatures.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                temperament: "Friendly" // You may want to add a temperament field
            )
            
            Task {
                do {
                        let db = Firestore.firestore()
                        
                        // First save the pet using the FirebaseService method
                        try await FirebaseService().submitLostPetReport(report: lostPet)
                        
                        // Then add the ownerID field separately (since it's not in the LostPet model)
                        try await db.collection("lostPets").document(lostPet.id).updateData([
                            "ownerID": Auth.auth().currentUser?.uid ?? "unknown"
                        ])
                        
                        DispatchQueue.main.async {
                            isSubmitting = false
                            //showingSuccessAlert = true
                            
                            // Clear the form
                            petName = ""
                            breed = ""
                            petDescription = ""
                            petAge = ""
                            petColor = ""
                            distinctiveFeatures = ""
                            reward = ""
                            contactInfo = ""
                            selectedPhotos = []
                            photoImages = []
                        }
                    } catch {
                        DispatchQueue.main.async {
                            isSubmitting = false
                            errorMessage = "Failed to submit report: \(error.localizedDescription)"
                        }
                    }
            }
        }
    }
    
    private func uploadPhotos(completion: @escaping ([String]?, Error?) -> Void) {
        guard !photoImages.isEmpty else {
            completion([], nil) // No photos to upload
            return
        }
        
        var uploadedPhotoURLs: [String] = []
        let storage = Storage.storage()
        let dispatchGroup = DispatchGroup()
        
        for (index, image) in photoImages.enumerated() {
            dispatchGroup.enter()
            let storageRef = storage.reference().child("lostPetsPhotos/\(UUID().uuidString)_\(index).jpg")
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                storageRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        dispatchGroup.leave()
                        completion(nil, error)
                        return
                    }
                    
                    storageRef.downloadURL { url, error in
                        if let url = url {
                            uploadedPhotoURLs.append(url.absoluteString)
                        }
                        dispatchGroup.leave()
                    }
                }
            } else {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(uploadedPhotoURLs, nil)
        }
    }
    
    // MARK: - Custom Text Field Style
    struct CustomTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .font(.system(size: 16))
        }
    }
}
