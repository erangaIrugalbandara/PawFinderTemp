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
    
    private var users: [User] = []
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let context = LAContext()
    
    // Keys for storing biometric preferences
    private let biometricEnabledKey = "biometric_enabled"
    private let storedEmailKey = "stored_email_for_biometric"
    
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
                    UserDefaults.standard.set(email, forKey: self.storedEmailKey)
                    self.saveBiometricSettings()
                    self.errorMessage = "\(self.biometricTypeName) enabled successfully"
                } else {
                    self.errorMessage = "Failed to enable \(self.biometricTypeName)"
                }
            }
        }
    }
    
    func disableBiometricAuthentication() {
        isBiometricEnabled = false
        UserDefaults.standard.removeObject(forKey: storedEmailKey)
        saveBiometricSettings()
    }
    
    func authenticateWithBiometrics(reason: String = "Authenticate to access PawFinder") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"
        
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async {
                self.errorMessage = error?.localizedDescription ?? "Biometric authentication not available"
            }
            return false
        }
        
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
    
    func authenticateWithDevicePasscode() async -> Bool {
        let context = LAContext()
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to access PawFinder"
            )
            
            return success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func signInWithBiometrics() {
        guard let storedEmail = UserDefaults.standard.string(forKey: storedEmailKey) else {
            errorMessage = "Please sign in with email and password first to set up \(biometricTypeName)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            let success = await authenticateWithBiometrics()
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    // Check if user is already signed in with Firebase
                    if let currentFirebaseUser = self.auth.currentUser,
                       currentFirebaseUser.email == storedEmail {
                        // User is already authenticated with Firebase
                        self.fetchUserData(uid: currentFirebaseUser.uid)
                        self.isBiometricAuthenticated = true
                    } else {
                        // Need to sign in with Firebase (this shouldn't happen in normal flow)
                        self.errorMessage = "Please sign in with your password first to enable biometric authentication"
                    }
                }
            }
        }
    }
    
    func setBiometricAuthenticated(_ authenticated: Bool) {
        self.isBiometricAuthenticated = authenticated
    }
    
    // MARK: - Original Authentication Methods
    
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.fetchUserData(uid: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                    self?.isBiometricAuthenticated = false
                }
            }
        }
    }
    
    func signUp(email: String, password: String, fullName: String) {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error during account creation: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let firebaseUser = result?.user else {
                    print("Error: Failed to create Firebase user.")
                    self?.errorMessage = "Failed to create user"
                    return
                }
                
                // Create user document in Firestore
                self?.createUserDocument(firebaseUser: firebaseUser, fullName: fullName)
                
                // After successful signup, store email for potential biometric setup
                UserDefaults.standard.set(email, forKey: self?.storedEmailKey ?? "stored_email_for_biometric")
                
                // Set biometric authenticated to true since they just signed up
                self?.isBiometricAuthenticated = true
            }
        }
    }
    
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }

        isLoading = true
        errorMessage = nil

        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("Error during login: \(error.localizedDescription)")
                    self?.errorMessage = "Login failed: \(error.localizedDescription)"
                    return
                }

                guard let firebaseUser = result?.user else {
                    print("Error: Firebase user not found")
                    self?.errorMessage = "Login failed: User not found"
                    return
                }

                // Fetch user data from Firestore
                self?.fetchUserData(uid: firebaseUser.uid)
                
                // Set biometric authentication as completed since user signed in with password
                self?.isBiometricAuthenticated = true

                // Store email for potential biometric setup
                UserDefaults.standard.set(email, forKey: self?.storedEmailKey ?? "stored_email_for_biometric")

                // Trigger login notification
                self?.notifyLoginSuccess()
                
                // Auto-enable biometric authentication if available and not already enabled
                if self?.biometricType != .none && self?.isBiometricEnabled == false {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.enableBiometricAuthentication(email: email)
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
            isAuthenticated = false
            isBiometricAuthenticated = false
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    func resetPassword(email: String) {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        auth.sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.errorMessage = "Password reset email sent!"
                }
            }
        }
    }
    
    private func createUserDocument(firebaseUser: FirebaseAuth.User, fullName: String) {
        let user = User(firebaseUser: firebaseUser, fullName: fullName)
        
        do {
            try db.collection("users").document(firebaseUser.uid).setData(from: user) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error during Firestore document creation: \(error.localizedDescription)")
                        self?.errorMessage = "Failed to save user data: \(error.localizedDescription)"
                    } else {
                        self?.currentUser = user
                        self?.isAuthenticated = true
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                print("Error during user serialization: \(error.localizedDescription)")
                self.errorMessage = "Failed to create user: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to fetch user data: \(error.localizedDescription)"
                    return
                }
                
                guard let document = document, document.exists else {
                    self?.errorMessage = "User document not found"
                    return
                }
                
                do {
                    let user = try document.data(as: User.self)
                    self?.currentUser = user
                    self?.isAuthenticated = true
                } catch {
                    self?.errorMessage = "Failed to decode user data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateProfile(fullName: String, phoneNumber: String?) {
        guard let currentUser = currentUser else { return }
        
        isLoading = true
        
        let updateData: [String: Any] = [
            "fullName": fullName,
            "phoneNumber": phoneNumber ?? ""
        ]
        
        db.collection("users").document(currentUser.id).updateData(updateData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                } else {
                    // Refresh user data
                    self?.fetchUserData(uid: currentUser.id)
                }
            }
        }
    }
    
    func notifyLoginSuccess() {
        let content = UNMutableNotificationContent()
        content.title = "Welcome!"
        content.body = "You have successfully logged in."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "loginSuccess", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling login notification: \(error.localizedDescription)")
            }
        }
    }
}
