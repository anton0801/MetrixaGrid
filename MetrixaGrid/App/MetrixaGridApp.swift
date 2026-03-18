import SwiftUI

@main
struct MetrixaGridApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var templateStore = TemplateStore()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(store)
                .environmentObject(themeManager)
                .environmentObject(templateStore)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
//            if showSplash {
//                SplashView()
//                    .transition(.opacity)
//                    .zIndex(10)
//            } else
            if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else if !store.isAuthenticated {
                AuthView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else {
                MainTabView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
        .animation(.springy, value: showSplash)
        .animation(.springy, value: hasCompletedOnboarding)
        .animation(.springy, value: store.isAuthenticated)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation { showSplash = false }
            }
        }
    }
}
