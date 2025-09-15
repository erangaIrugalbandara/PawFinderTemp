import SwiftUI
import Foundation
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import LocalAuthentication

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let createdAt: Date
    let profileImageURL: String?
    let phoneNumber: String?
    let isEmailVerified: Bool
    
    var firstName: String {
        fullName.components(separatedBy: " ").first ?? fullName
    }
    
    init(firebaseUser: FirebaseAuth.User, fullName: String, profileImageURL: String? = nil, phoneNumber: String? = nil) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.fullName = fullName
        self.createdAt = Date()
        self.profileImageURL = profileImageURL
        self.phoneNumber = phoneNumber
        self.isEmailVerified = firebaseUser.isEmailVerified
    }
}

// MARK: - Auth View Model
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isBiometricAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var biometricType: LABiometryType = .none
    @Published var isBiometricEnabled = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let context = LAContext()
    
    // Keys for storing biometric preferences
    private let biometricEnabledKey = "biometric_enabled"
    private let storedEmailKey = "stored_email_for_biometric"
    private let rememberedEmailKey = "remembered_email"
    
    init() {
        setupAuthStateListener()
        checkBiometricAvailability()
        loadBiometricSettings()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State Management
    
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.fetchUserData(uid: user.uid)
                    // If biometric is enabled and user is authenticated, mark biometric as authenticated too
                    if self?.isBiometricEnabled == true {
                        self?.isBiometricAuthenticated = true
                    }
                } else {
                    self?.currentUser = nil
                    self?.isBiometricAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Biometric Authentication Setup
    
    private func checkBiometricAvailability() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
    
    private func loadBiometricSettings() {
        isBiometricEnabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
    }
    
    private func saveBiometricSettings() {
        UserDefaults.standard.set(isBiometricEnabled, forKey: biometricEnabledKey)
    }
    
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric Authentication"
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "lock.fill"
        }
    }
    
    // MARK: - Biometric Authentication Methods
    
    func enableBiometricAuthentication(email: String) {
        guard biometricType != .none else {
            errorMessage = "Biometric authentication is not available on this device"
            return
        }
        
        Task {
            let success = await authenticateWithBiometrics(reason: "Enable \(biometricTypeName) for PawFinder")
            
            DispatchQueue.main.async {
                if success {
                    self.isBiometricEnabled = true
                    self.saveBiometricSettings()
                    UserDefaults.standard.set(email, forKey: self.storedEmailKey)
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "Failed to enable \(self.biometricTypeName)"
                }
            }
        }
    }
    
    func disableBiometricAuthentication() {
        isBiometricEnabled = false
        saveBiometricSettings()
        UserDefaults.standard.removeObject(forKey: storedEmailKey)
        isBiometricAuthenticated = false
    }
    
    @MainActor
    func signInWithBiometrics() async -> Bool {
        guard isBiometricEnabled, biometricType != .none else {
            errorMessage = "Biometric authentication is not enabled"
            return false
        }
        
        guard let storedEmail = UserDefaults.standard.string(forKey: storedEmailKey) else {
            errorMessage = "No stored email found for biometric authentication"
            return false
        }
        
        let success = await authenticateWithBiometrics(reason: "Sign in to PawFinder")
        
        if success {
            // Check if user is already signed in to Firebase
            if auth.currentUser != nil {
                isBiometricAuthenticated = true
                errorMessage = nil
                return true
            } else {
                // If not signed in, redirect to email/password login
                errorMessage = "Please sign in with your email and password first"
                return false
            }
        } else {
            errorMessage = "Biometric authentication failed"
            return false
        }
    }
    
    func authenticateWithBiometrics(reason: String = "Authenticate to access PawFinder") async -> Bool {
        guard biometricType != .none else { return false }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func setBiometricAuthenticated(_ authenticated: Bool) {
        isBiometricAuthenticated = authenticated
    }
    
    // MARK: - Firebase Authentication Methods
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = self?.getErrorMessage(from: error)
                } else {
                    // Save email for remember me functionality
                    UserDefaults.standard.set(email, forKey: self?.rememberedEmailKey ?? "")
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    func signUp(email: String, password: String, fullName: String) {
        isLoading = true
        errorMessage = nil
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = self?.getErrorMessage(from: error)
                } else if let firebaseUser = result?.user {
                    self?.createUserDocument(firebaseUser: firebaseUser, fullName: fullName)
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            isBiometricAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = "Failed to sign out"
        }
    }
    
    func resetPassword(email: String) {
        auth.sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = self?.getErrorMessage(from: error)
                } else {
                    self?.errorMessage = "Password reset email sent successfully"
                }
            }
        }
    }
    
    // MARK: - Firestore Methods
    
    private func createUserDocument(firebaseUser: FirebaseAuth.User, fullName: String) {
        let user = User(firebaseUser: firebaseUser, fullName: fullName)
        
        do {
            try db.collection("users").document(user.id).setData(from: user)
            currentUser = user
        } catch {
            errorMessage = "Failed to create user profile"
        }
    }
    
    private func fetchUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    do {
                        self?.currentUser = try document.data(as: User.self)
                    } catch {
                        print("Error decoding user: \(error)")
                    }
                }
            }
        }
    }
    
    // Add this method to your AuthViewModel class if it doesn't exist
    func authenticateWithDevicePasscode() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if device passcode is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async {
                self.errorMessage = "Device passcode authentication is not available"
            }
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Use device passcode to sign in to PawFinder"
            )
            
            if success {
                DispatchQueue.main.async {
                    self.isBiometricAuthenticated = true
                    self.errorMessage = nil
                }
            }
            
            return success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func getErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email is already registered"
        case AuthErrorCode.weakPassword.rawValue:
            return "Password should be at least 6 characters"
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address"
        case AuthErrorCode.userNotFound.rawValue, AuthErrorCode.wrongPassword.rawValue:
            return "Invalid email or password"
        case AuthErrorCode.userDisabled.rawValue:
            return "This account has been disabled"
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please try again later"
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection"
        default:
            return error.localizedDescription
        }
    }
}
