import SwiftUI

struct BiometricSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingConfirmation = false
    @State private var pendingToggle = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: authViewModel.biometricIcon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(authViewModel.biometricTypeName)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Quick and secure app access")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { authViewModel.isBiometricEnabled },
                    set: { newValue in
                        if newValue {
                            enableBiometric()
                        } else {
                            showingConfirmation = true
                        }
                    }
                ))
                .labelsHidden()
                .disabled(authViewModel.biometricType == .none)
            }
            
            if authViewModel.biometricType == .none {
                Text("Biometric authentication is not available on this device")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.2))
        )
        .alert("Disable \(authViewModel.biometricTypeName)?", isPresented: $showingConfirmation) {
            Button("Disable", role: .destructive) {
                authViewModel.disableBiometricAuthentication()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You'll need to enter your password to sign in next time.")
        }
    }
    
    private func enableBiometric() {
        guard let email = authViewModel.currentUser?.email else { return }
        authViewModel.enableBiometricAuthentication(email: email)
    }
}
