import SwiftUI

struct LoginView: View {
    @Binding var showingLogin: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var isAuthenticatingBiometric = false
    
    var body: some View {
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
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 35))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 80)
                        
                        Text("Welcome Back")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Sign in to continue")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Face ID Button (show if biometric is available)
                    if authViewModel.biometricType != .none {
                        Button(action: {
                            authenticateWithBiometrics()
                        }) {
                            HStack {
                                if isAuthenticatingBiometric {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: authViewModel.biometricIcon)
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                                
                                Text(isAuthenticatingBiometric ? "Authenticating..." : "Sign in with \(authViewModel.biometricTypeName)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 28)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(isAuthenticatingBiometric)
                        .padding(.horizontal, 24)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("or")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 24)
                    }
                    
                    // Form
                    VStack(spacing: 20) {
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
                    
                    // Sign In Button
                    Button(action: {
                        authViewModel.signIn(email: email, password: password)
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.4, green: 0.3, blue: 0.8)))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(28)
                        } else {
                            Text("Sign In")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(28)
                        }
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                    .opacity(isFormValid && !authViewModel.isLoading ? 1.0 : 0.6)
                    .padding(.horizontal, 24)
                    
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
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func authenticateWithBiometrics() {
        isAuthenticatingBiometric = true
        
        Task {
            let success = await authViewModel.authenticateWithBiometrics()
            
            DispatchQueue.main.async {
                self.isAuthenticatingBiometric = false
                
                if success {
                    // If biometric auth succeeds but user isn't signed in to Firebase,
                    // we need to handle this case
                    if authViewModel.isAuthenticated {
                        authViewModel.setBiometricAuthenticated(true)
                    } else {
                        // First time using Face ID - need to set up the connection
                        authViewModel.errorMessage = "Please sign in with email and password first to set up Face ID"
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView(showingLogin: .constant(true))
        .environmentObject(AuthViewModel())
}
