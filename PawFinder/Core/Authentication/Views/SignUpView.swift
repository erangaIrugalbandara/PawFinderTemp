import SwiftUI

struct SignUpView: View {
    @Binding var showingLogin: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var agreedToTerms = false
    
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
                VStack(spacing: 24) {
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
                        .padding(.top, 60)
                        
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Join the PawFind community")
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
                    
                    // Form
                    VStack(spacing: 16) {
                        CustomTextField(placeholder: "Full Name", text: $fullName, icon: "person.fill")
                        CustomTextField(placeholder: "Email", text: $email, icon: "envelope.fill")
                        CustomSecureField(placeholder: "Password", text: $password)
                        CustomSecureField(placeholder: "Confirm Password", text: $confirmPassword)
                        
                        // Terms Agreement
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: {
                                agreedToTerms.toggle()
                            }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            
                            Text("I agree to the Terms of Service and Privacy Policy")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Sign Up Button
                    Button(action: {
                        authViewModel.signUp(email: email, password: password, fullName: fullName)
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.4, green: 0.3, blue: 0.8)))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(28)
                        } else {
                            Text("Create Account")
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
                    
                    // Login Link
                    HStack {
                        Text("Already have an account?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Sign In") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingLogin = true
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
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !fullName.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        agreedToTerms &&
        email.contains("@")
    }
}

#Preview {
    SignUpView(showingLogin: .constant(false))
        .environmentObject(AuthViewModel())
}
