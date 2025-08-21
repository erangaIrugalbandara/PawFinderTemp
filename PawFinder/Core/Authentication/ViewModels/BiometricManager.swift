import LocalAuthentication
import Foundation

class BiometricManager {
    
    struct UserCredentials {
        let email: String?
        let password: String?
    }
    
    func authenticateUser() async throws -> UserCredentials {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.biometryNotAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access your PawFind account"
            )
            
            if success {
                // In a real app, you would retrieve stored credentials from Keychain
                // For demo purposes, return mock credentials
                return UserCredentials(email: getStoredEmail(), password: getStoredPassword())
            } else {
                throw BiometricError.authenticationFailed
            }
        } catch {
            throw BiometricError.authenticationFailed
        }
    }
    
    func saveCredentials(email: String, password: String) {
        // In a real app, save to Keychain securely
        UserDefaults.standard.set(email, forKey: "biometric_email")
        // Note: Never store passwords in UserDefaults in production
        // This is just for demo purposes
    }
    
    private func getStoredEmail() -> String? {
        return UserDefaults.standard.string(forKey: "biometric_email")
    }
    
    private func getStoredPassword() -> String? {
        // In a real app, retrieve from Keychain
        return nil
    }
}

enum BiometricError: Error, LocalizedError {
    case biometryNotAvailable
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device"
        case .authenticationFailed:
            return "Biometric authentication failed"
        }
    }
}
