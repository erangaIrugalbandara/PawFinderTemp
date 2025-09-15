import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if authViewModel.isAuthenticated {
                    if authViewModel.isBiometricAuthenticated {
                        DashboardView()
                            .environmentObject(authViewModel)
                    } else {
                        BiometricAuthView()
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
