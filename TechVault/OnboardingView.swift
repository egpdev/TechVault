//
//  OnboardingView.swift
//  IT-Inventory Manager — "TechVault"
//
//  Created by Egor Pylkov on 10.02.26.
//
//  MARK: - Onboarding & Settings
//  This file contains:
//    1. OnboardingView  – 3-page welcome flow (TabView page style)
//    2. OnboardingPage  – Reusable slide layout
//    3. SettingsView     – About, Replay Onboarding, App Version
//

import SwiftUI

// ============================================================
// MARK: - 1. OnboardingView (TabView Page Style)
// ============================================================
/// A 3-slide onboarding flow shown only on the first app launch.
/// Uses @AppStorage to persist completion state in UserDefaults.
struct OnboardingView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage: Int = 0

    /// Accent color used throughout the onboarding.
    private let brandColor = Color.indigo

    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    brandColor.opacity(0.08),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Paged TabView ──
                TabView(selection: $currentPage) {
                    // Slide 1: Welcome
                    OnboardingPage(
                        icon: "building.columns",
                        gradient: [.indigo, .blue],
                        title: "Welcome to\nTechVault",
                        subtitle:
                            "Your professional IT inventory management system. Track, organize, and manage every piece of hardware in one place."
                    )
                    .tag(0)

                    // Slide 2: Features
                    OnboardingPage(
                        icon: "laptopcomputer",
                        gradient: [.cyan, .teal],
                        title: "Track Your\nHardware",
                        subtitle:
                            "Add laptops, monitors, phones, and accessories. Monitor status, serial numbers, and purchase dates with ease."
                    )
                    .tag(1)

                    // Slide 3: Get Started
                    OnboardingPage(
                        icon: "checkmark.shield.fill",
                        gradient: [.green, .mint],
                        title: "Ready to\nGet Started",
                        subtitle:
                            "Your inventory data is stored securely on-device. No account needed — just tap the button below."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // ── Page Indicator + Button ──
                VStack(spacing: 28) {
                    // Custom page dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Capsule()
                                .fill(index == currentPage ? brandColor : brandColor.opacity(0.25))
                                .frame(
                                    width: index == currentPage ? 28 : 8,
                                    height: 8
                                )
                                .animation(.snappy, value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        if currentPage < 2 {
                            // Advance to next slide
                            withAnimation(.easeInOut) {
                                currentPage += 1
                            }
                        } else {
                            // Complete onboarding
                            withAnimation(.easeInOut(duration: 0.5)) {
                                hasSeenOnboarding = true
                            }
                            UINotificationFeedbackGenerator()
                                .notificationOccurred(.success)
                        }
                    } label: {
                        Text(currentPage == 2 ? "Get Started" : "Continue")
                            .font(.body)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [brandColor, brandColor.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: brandColor.opacity(0.4), radius: 12, y: 6)
                            )
                    }
                    .padding(.horizontal, 32)

                    // Skip button (only visible before last slide)
                    if currentPage < 2 {
                        Button("Skip") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                hasSeenOnboarding = true
                            }
                        }
                        .font(.subheadline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// ============================================================
// MARK: - 2. OnboardingPage (Reusable Slide)
// ============================================================
/// A single onboarding slide with a large gradient icon,
/// title, and subtitle text.
struct OnboardingPage: View {
    let icon: String
    let gradient: [Color]
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Large gradient icon circle
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundStyle(.white)
                .frame(width: 120, height: 120)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: gradient[0].opacity(0.4), radius: 20, y: 10)
                )

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

// ============================================================
// MARK: - 3. SettingsView
// ============================================================
/// A settings screen accessible from the main view toolbar.
/// Includes "About", "Replay Onboarding", and app version info.
struct SettingsView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = true
    @Environment(\.dismiss) private var dismiss

    /// The brand indigo color.
    private let brandColor = Color.indigo

    var body: some View {
        NavigationStack {
            List {
                // ── About Section ──
                Section {
                    // App header card
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [.indigo, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: brandColor.opacity(0.3), radius: 10, y: 5)
                            )

                        Text("TechVault")
                            .font(.title2)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)

                        Text("Professional IT Inventory Manager")
                            .font(.subheadline)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }

                // ── About the App ──
                Section("About") {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Developer")
                                .font(.body)
                                .fontDesign(.rounded)
                            Text("Egor Pylkov")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fontDesign(.rounded)
                        }
                    } icon: {
                        Image(systemName: "person.fill")
                            .foregroundStyle(brandColor)
                    }

                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Built With")
                                .font(.body)
                                .fontDesign(.rounded)
                            Text("SwiftUI · SwiftData · iOS 17+")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fontDesign(.rounded)
                        }
                    } icon: {
                        Image(systemName: "hammer.fill")
                            .foregroundStyle(brandColor)
                    }

                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Purpose")
                                .font(.body)
                                .fontDesign(.rounded)
                            Text("Portfolio Project — Fachinformatiker")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fontDesign(.rounded)
                        }
                    } icon: {
                        Image(systemName: "briefcase.fill")
                            .foregroundStyle(brandColor)
                    }
                }

                // ── Onboarding ──
                Section("Onboarding") {
                    Button {
                        // Reset the flag so onboarding plays again
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasSeenOnboarding = false
                        }
                    } label: {
                        Label {
                            Text("Replay Onboarding")
                                .font(.body)
                                .fontDesign(.rounded)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundStyle(brandColor)
                        }
                    }
                }

                // ── App Version ──
                Section {
                    HStack {
                        Label {
                            Text("Version")
                                .font(.body)
                                .fontDesign(.rounded)
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(brandColor)
                        }
                        Spacer()
                        Text("1.0.0")
                            .font(.body)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label {
                            Text("Build")
                                .font(.body)
                                .fontDesign(.rounded)
                        } icon: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(brandColor)
                        }
                        Spacer()
                        Text("2026.02")
                            .font(.body)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Made with ❤️ in Germany")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontDesign(.rounded)
                }
            }
        }
    }
}

// ============================================================
// MARK: - Previews
// ============================================================
#Preview("Onboarding") {
    OnboardingView()
}

#Preview("Settings") {
    SettingsView()
}
