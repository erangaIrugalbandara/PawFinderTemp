import SwiftUI

struct LoginView: View {
    @Binding var showingLogin: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isAuthenticatingBiometric = false
    
    var body: some View {
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
                    Spacer()
                    
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 35))
                                .foregroundColor(.white)
                        }
                        
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Sign in to continue helping pets")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 20)
                    
                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 24)
                    }
                    
                    // 🔥 MAIN BIOMETRIC LOGIN BUTTON - This is where you click to use Face ID/Touch ID
                    if authViewModel.isBiometricEnabled && authViewModel.biometricType != .none {
                        VStack(spacing: 20) {
                            // Large Biometric Button
                            Button(action: {
                                authenticateWithBiometrics()
                            }) {
                                VStack(spacing: 16) {
                                    if isAuthenticatingBiometric {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                    } else {
                                        Image(systemName: authViewModel.biometricIcon)
                                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(isAuthenticatingBiometric ? "Authenticating..." : "Sign in with \(authViewModel.biometricTypeName)")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                        )
                                )
                            }
                            .disabled(isAuthenticatingBiometric || authViewModel.isLoading)
                            .padding(.horizontal, 24)
                            
                            // Divider
                            HStack {
                                VStack { Divider().background(Color.white.opacity(0.3)) }
                                Text("or continue with email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                VStack { Divider().background(Color.white.opacity(0.3)) }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // Email/Password Form
                    VStack(spacing: 16) {
                        CustomTextField(placeholder: "Email", text: $email, icon: "envelope.fill")
                        CustomSecureField(placeholder: "Password", text: $password)
                        
                        // Remember Me & Forgot Password
                        HStack {
                            Button(action: {
                                rememberMe.toggle()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Text("Remember me")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            
                            Spacer()
                            
                            Button("Forgot Password?") {
                                if !email.isEmpty {
                                    authViewModel.resetPassword(email: email)
                                } else {
                                    authViewModel.errorMessage = "Please enter your email first"
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 24)
                    
                    // Email Sign In Button
                    Button(action: {
                        authViewModel.signIn(email: email, password: password)
                        if rememberMe && authViewModel.biometricType != .none {
                            // Enable biometric after successful login
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                if authViewModel.isAuthenticated {
                                    authViewModel.enableBiometricAuthentication(email: email)
                                }
                            }
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.4, green: 0.3, blue: 0.8)))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(28)
                        } else {
                            Text("Sign In with Email")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(28)
                        }
                    }
                    .disabled(!isFormValid || authViewModel.isLoading || isAuthenticatingBiometric)
                    .opacity(isFormValid && !authViewModel.isLoading && !isAuthenticatingBiometric ? 1.0 : 0.6)
                    .padding(.horizontal, 24)
                    
                    // Compact Biometric Button (Alternative style)
                    if authViewModel.biometricType != .none && !authViewModel.isBiometricEnabled {
                        Button(action: {
                            // This will prompt to enable biometric after they log in
                            if !email.isEmpty {
                                authViewModel.signIn(email: email, password: password)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    if authViewModel.isAuthenticated {
                                        authViewModel.enableBiometricAuthentication(email: email)
                                    }
                                }
                            } else {
                                authViewModel.errorMessage = "Please enter your email first to set up \(authViewModel.biometricTypeName)"
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: authViewModel.biometricIcon)
                                    .font(.system(size: 16))
                                Text("Set up \(authViewModel.biometricTypeName)")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Sign Up") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingLogin = false
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Load saved email if remember me was enabled
            if let savedEmail = UserDefaults.standard.string(forKey: "remembered_email") {
                email = savedEmail
                rememberMe = true
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    // 🔥 THIS IS THE FUNCTION THAT RUNS WHEN YOU TAP THE FACE ID BUTTON
    private func authenticateWithBiometrics() {
        isAuthenticatingBiometric = true
        authViewModel.errorMessage = nil
        
        Task {
            let success = await authViewModel.signInWithBiometrics()
            
            DispatchQueue.main.async {
                self.isAuthenticatingBiometric = false
                if success {
                    // Success! User will be automatically navigated to dashboard
                    print("✅ Biometric authentication successful!")
                } else {
                    // Failed - error message will be shown automatically
                    print("❌ Biometric authentication failed")
                }
            }
        }
    }
}

#Preview {
    LoginView(showingLogin: .constant(true))
        .environmentObject(AuthViewModel())
}
