import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        NavigationView {
            if authViewModel.isAuthenticated {
                DashboardView()
                    .environmentObject(authViewModel)
            } else {
                WelcomeView()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ContentView()
}
