import SwiftUI
import Foundation
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

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
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    private var users: [User] = [] 
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.fetchUserData(uid: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
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

                // Trigger login notification
                self?.notifyLoginSuccess()
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
            isAuthenticated = false
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
