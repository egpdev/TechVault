//
//  IT_Inventory_ManagerApp.swift
//  IT-Inventory Manager — "TechVault"
//
//  Created by Egor Pylkov on 10.02.26.
//
//  MARK: - App Entry Point
//  Uses @AppStorage to track whether the user has completed
//  onboarding. On first launch → OnboardingView, otherwise → ContentView.
//

import SwiftData
import SwiftUI

@main
struct IT_Inventory_ManagerApp: App {

    // MARK: - Onboarding State
    // @AppStorage persists a Bool into UserDefaults.
    // On the very first launch this defaults to false,
    // so the onboarding flow is shown.
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    // MARK: - SwiftData Container
    /// Configures the persistent store for the Device model.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Device.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            // Smooth cross-fade between onboarding and main app.
            Group {
                if hasSeenOnboarding {
                    ContentView()
                        .transition(.opacity)
                } else {
                    OnboardingView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: hasSeenOnboarding)
        }
        .modelContainer(sharedModelContainer)
    }
}
