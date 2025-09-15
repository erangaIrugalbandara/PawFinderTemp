import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if authViewModel.isAuthenticated {
                    // If user is authenticated but biometric is enabled and not authenticated with biometric
                    if authViewModel.isBiometricEnabled && !authViewModel.isBiometricAuthenticated {
                        BiometricAuthView()
                            .environmentObject(authViewModel)
                    } else {
                        DashboardView()
                            .environmentObject(authViewModel)
                    }
                } else {
                    WelcomeView()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ContentView()
}
