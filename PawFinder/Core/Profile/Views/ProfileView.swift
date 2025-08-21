import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileViewModel()

    @State private var newName: String = ""
    @State private var newPassword: String = ""
    @State private var notificationGeneral: Bool = true
    @State private var notificationLostPets: Bool = false
    @State private var notificationMessages: Bool = true
    @State private var showSavedAlert = false

    var hasChanges: Bool {
        newName != viewModel.userName ||
        notificationGeneral != viewModel.notificationGeneral ||
        notificationLostPets != viewModel.notificationLostPets ||
        notificationMessages != viewModel.notificationMessages ||
        !newPassword.isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
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
                    VStack(spacing: 32) {
                        // Back Button
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Back")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(.leading, 4)
                            }
                            Spacer()
                        }
                        .padding(.top, 30)
                        .padding(.leading, 16)

                        // Profile Section
                        VStack {
                            // Replace with image picker if needed
                            Image("profile_photo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(color: Color.black.opacity(0.16), radius: 8)
                            Text(viewModel.userName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            Text("Pet Parent • Community Helper")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.top, 14)

                        // Profile Details Card
                        VStack(spacing: 22) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.gray)
                                TextField("Your Name", text: $newName)
                                    .font(.system(size: 17))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                            // Email field (disabled)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.gray)
                                TextField("Your Email", text: .constant(viewModel.email))
                                    .font(.system(size: 17))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .disabled(true)
                            }
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.gray)
                                SecureField("Enter new password", text: $newPassword)
                                    .font(.system(size: 17))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 18)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(18)

                        // Notification Preferences Card
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Notification Preferences")
                                .font(.system(size: 16, weight: .bold))
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $notificationGeneral) {
                                    Text("General Notifications")
                                        .font(.system(size: 15))
                                }
                                .tint(Color(red: 0.54, green: 0.33, blue: 0.95))
                                Toggle(isOn: $notificationLostPets) {
                                    Text("Lost Pets Alerts")
                                        .font(.system(size: 15))
                                }
                                .tint(Color(red: 0.54, green: 0.33, blue: 0.95))
                                Toggle(isOn: $notificationMessages) {
                                    Text("Messages")
                                        .font(.system(size: 15))
                                }
                                .tint(Color(red: 0.54, green: 0.33, blue: 0.95))
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)

                        // Save Button
                        Button(action: {
                            viewModel.saveProfile(
                                newName: newName,
                                newPassword: newPassword.isEmpty ? nil : newPassword,
                                notificationGeneral: notificationGeneral,
                                notificationLostPets: notificationLostPets,
                                notificationMessages: notificationMessages
                            ) { success in
                                if success {
                                    showSavedAlert = true
                                    newPassword = ""
                                }
                            }
                        }) {
                            Text("Save")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(hasChanges ? Color(red: 0.4, green: 0.3, blue: 0.8) : Color.gray)
                                .cornerRadius(13)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                        .disabled(!hasChanges)
                        .alert(isPresented: $showSavedAlert) {
                            Alert(title: Text("Saved"), message: Text("Your profile has been updated."), dismissButton: .default(Text("OK")))
                        }

                        // Log Out Button
                        Button(action: {
                            // Firebase sign out logic
                            try? Auth.auth().signOut()
                        }) {
                            Text("Log Out")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.red)
                                .cornerRadius(13)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 32)
                }
                .onAppear {
                    viewModel.fetchProfile()
                    newName = viewModel.userName
                    notificationGeneral = viewModel.notificationGeneral
                    notificationLostPets = viewModel.notificationLostPets
                    notificationMessages = viewModel.notificationMessages
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
    }
}
