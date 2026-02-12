//
//  ContentView.swift
//  IT-Inventory Manager — "TechVault"
//
//  Created by Egor Pylkov on 10.02.26.
//
//  MARK: - Premium UI — All Views
//  This file contains every view for the TechVault app:
//    1. ContentView           – Dashboard stats + card-based grouped list
//    2. StatsDashboardView    – Glassmorphism stat cards at the top
//    3. StatusFilterBar       – Horizontal pill filter for device status
//    4. DeviceCardView        – Premium card with gradient category icon
//    5. StatusBadge            – Color-coded status pill
//    6. AddDeviceSheet        – Interactive modal form
//    7. EditDeviceSheet       – Edit existing device
//    8. DeviceDetailView      – Full detail with edit/status/delete
//    9. DetailInfoCard        – Glassmorphism info tile
//   10. ConfirmationToast     – Save success feedback
//

import SwiftData
import SwiftUI

// MARK: - SortOption Enum
/// Defines how devices are sorted in the main list.
enum SortOption: String, CaseIterable, Identifiable {
    case name = "Name"
    case dateNewest = "Newest First"
    case dateOldest = "Oldest First"
    case status = "Status"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .name: return "textformat.abc"
        case .dateNewest: return "calendar.badge.clock"
        case .dateOldest: return "calendar"
        case .status: return "circle.dotted"
        }
    }
}

// ============================================================
// MARK: - 1. ContentView (Main Dashboard)
// ============================================================
/// The root view of the app — premium dashboard layout:
///   - Top: Statistics cards (glassmorphism)
///   - Middle: Status filter pills
///   - Bottom: Devices grouped by category as cards
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Device.name) private var devices: [Device]

    @State private var searchText: String = ""
    @State private var showAddSheet: Bool = false
    @State private var showSettings: Bool = false
    @State private var selectedStatusFilter: DeviceStatus? = nil
    @State private var sortOption: SortOption = .name
    @State private var showSavedToast: Bool = false

    // MARK: Computed Properties

    /// Applies search text, status filter, AND sort order.
    private var filteredDevices: [Device] {
        var result = devices

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by status (if a pill is selected)
        if let statusFilter = selectedStatusFilter {
            result = result.filter { $0.status == statusFilter }
        }

        return result
    }

    /// Sorts the filtered devices according to the selected sort option.
    private var sortedDevices: [Device] {
        switch sortOption {
        case .name:
            return filteredDevices.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .dateNewest:
            return filteredDevices.sorted { $0.purchaseDate > $1.purchaseDate }
        case .dateOldest:
            return filteredDevices.sorted { $0.purchaseDate < $1.purchaseDate }
        case .status:
            return filteredDevices.sorted { $0.status.rawValue < $1.status.rawValue }
        }
    }

    /// Groups sorted devices by category, sorted by sortOrder.
    private var groupedDevices: [(category: DeviceCategory, devices: [Device])] {
        let grouped = Dictionary(grouping: sortedDevices) { $0.category }
        return
            grouped
            .map { (category: $0.key, devices: $0.value) }
            .sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Rich tinted background gradient
                ZStack {
                    Color(.systemGroupedBackground)
                    LinearGradient(
                        colors: [
                            Color.indigo.opacity(0.07),
                            Color.blue.opacity(0.04),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()

                Group {
                    if devices.isEmpty {
                        emptyStateView
                    } else if filteredDevices.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        mainContentView
                    }
                }
            }
            // Toast overlay for save/edit confirmations
            .overlay(alignment: .bottom) {
                if showSavedToast {
                    ConfirmationToast(message: "Device Saved")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 32)
                }
            }
            .navigationTitle("TechVault")
            .fontDesign(.rounded)
            .toolbar {
                // Settings button (leading)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.body)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                // Sort menu button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases) { option in
                            Button {
                                withAnimation(.snappy) { sortOption = option }
                            } label: {
                                Label(option.rawValue, systemImage: option.icon)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.body)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                // Add device button (trailing)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search devices…")
            .sheet(isPresented: $showAddSheet) {
                AddDeviceSheet(onSave: showToast)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: Main scrollable content

    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ── Statistics Dashboard ──
                StatsDashboardView(devices: devices)
                    .padding(.horizontal)

                // ── Status Filter Bar ──
                StatusFilterBar(
                    selectedStatus: $selectedStatusFilter,
                    devices: devices
                )
                .padding(.horizontal)

                // ── Device Cards grouped by category ──
                ForEach(groupedDevices, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section header with category icon + count
                        HStack(spacing: 6) {
                            Label(group.category.rawValue, systemImage: group.category.icon)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)

                            Text("\(group.devices.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: group.category.gradient,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                        .padding(.horizontal)

                        ForEach(group.devices) { device in
                            NavigationLink(
                                destination: DeviceDetailView(device: device, onSave: showToast)
                            ) {
                                DeviceCardView(device: device)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: Toast Helper

    /// Shows a brief "saved" toast and auto-hides after 2 seconds.
    private func showToast() {
        withAnimation(.snappy) { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut) { showSavedToast = false }
        }
    }

    // MARK: Empty State

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Devices Tracked",
            systemImage: "desktopcomputer.trianglebadge.exclamationmark",
            description: Text("Tap the **+** button to start your inventory.")
        )
    }
}

// ============================================================
// MARK: - 2. StatsDashboardView (Glassmorphism)
// ============================================================
/// Three stat cards at the top of the main screen showing:
///  - Total device count
///  - Devices "In Use"
///  - Devices "Broken" (needs attention)
struct StatsDashboardView: View {
    let devices: [Device]

    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total",
                value: "\(devices.count)",
                icon: "tray.full.fill",
                gradient: [.blue, .cyan]
            )

            StatCard(
                title: "In Use",
                value: "\(devices.filter { $0.status == .inUse }.count)",
                icon: "person.fill",
                gradient: [.indigo, .purple]
            )

            StatCard(
                title: "Broken",
                value: "\(devices.filter { $0.status == .broken }.count)",
                icon: "exclamationmark.triangle.fill",
                gradient: [.orange, .red]
            )
        }
    }
}

/// A single glassmorphism stat card with gradient icon.
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        VStack(spacing: 8) {
            // Gradient icon circle
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: gradient[0].opacity(0.4), radius: 6, y: 3)
                )

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            gradient[0].opacity(0.1),
                            gradient[1].opacity(0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(gradient[0].opacity(0.15), lineWidth: 1)
                )
                .shadow(color: gradient[0].opacity(0.08), radius: 8, y: 4)
        )
    }
}

// ============================================================
// MARK: - 3. StatusFilterBar
// ============================================================
/// Horizontal scrollable pills to filter devices by status.
/// Tapping a selected pill deselects it (shows all).
struct StatusFilterBar: View {
    @Binding var selectedStatus: DeviceStatus?
    let devices: [Device]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "All" pill
                FilterPill(
                    label: "All",
                    icon: "tray.full.fill",
                    count: devices.count,
                    isSelected: selectedStatus == nil,
                    color: .primary
                ) {
                    withAnimation(.snappy) { selectedStatus = nil }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                // One pill per status
                ForEach(DeviceStatus.allCases) { status in
                    FilterPill(
                        label: status.rawValue,
                        icon: status.icon,
                        count: devices.filter { $0.status == status }.count,
                        isSelected: selectedStatus == status,
                        color: status.color
                    ) {
                        withAnimation(.snappy) {
                            selectedStatus = (selectedStatus == status) ? nil : status
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
        }
    }
}

/// A single filter pill button.
struct FilterPill: View {
    let label: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? .white.opacity(0.3) : color.opacity(0.15))
                    )
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : color.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// ============================================================
// MARK: - 4. DeviceCardView
// ============================================================
/// Premium card-style row for each device with gradient
/// category icon and glassmorphism background.
struct DeviceCardView: View {
    let device: Device

    var body: some View {
        HStack(spacing: 14) {
            // Gradient category icon
            Image(systemName: device.category.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: device.category.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: device.category.gradient[0].opacity(0.4), radius: 6, y: 3)
                )

            // Device info
            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(device.serialNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Status badge + chevron
            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(status: device.status)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            device.category.gradient[0].opacity(0.06),
                            device.category.gradient[1].opacity(0.02),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(device.category.gradient[0].opacity(0.12), lineWidth: 1)
                )
                .shadow(color: device.category.gradient[0].opacity(0.1), radius: 10, y: 5)
        )
    }
}

// ============================================================
// MARK: - 5. StatusBadge
// ============================================================
/// A small color-coded pill showing the device status.
struct StatusBadge: View {
    let status: DeviceStatus

    var body: some View {
        Label(status.rawValue, systemImage: status.icon)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status.color.opacity(0.12))
            )
    }
}

// ============================================================
// MARK: - 6. AddDeviceSheet (Interactive Form)
// ============================================================
/// A modal sheet with an interactive form to create a new Device.
/// Features animated category selector and visual status picker.
struct AddDeviceSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: DeviceCategory = .laptop
    @State private var serialNumber: String = ""
    @State private var purchaseDate: Date = .now
    @State private var status: DeviceStatus = .available

    /// Optional callback fired after a successful save.
    var onSave: (() -> Void)? = nil

    /// Prevents saving empty names or serial numbers.
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !serialNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ── Interactive Category Selector ──
                    categorySelectorSection

                    // ── Device Info Fields ──
                    deviceInfoSection

                    // ── Purchase & Status ──
                    purchaseStatusSection

                    // ── Visual Status Picker ──
                    statusPickerSection
                }
                .padding()
            }
            // Dismiss keyboard when user drags the scroll view
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDevice()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }

    // MARK: Category Selector (visual grid)

    /// A horizontal grid of tappable category cards
    /// with gradient backgrounds.
    private var categorySelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATEGORY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(DeviceCategory.allCases) { cat in
                    Button {
                        withAnimation(.snappy) { category = cat }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: cat.icon)
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: cat.gradient,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .opacity(category == cat ? 1 : 0.4)
                                .scaleEffect(category == cat ? 1.1 : 1.0)

                            Text(cat.rawValue)
                                .font(.caption2)
                                .fontWeight(category == cat ? .bold : .regular)
                                .foregroundStyle(category == cat ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: Device Info Section

    private var deviceInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DEVICE INFORMATION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                // Device name field
                HStack {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Device Name", text: $name)
                        .autocorrectionDisabled()
                }
                .padding(14)

                Divider().padding(.leading, 48)

                // Serial number field
                HStack {
                    Image(systemName: "number")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Serial Number", text: $serialNumber)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                }
                .padding(14)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: Purchase & Status Section

    private var purchaseStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PURCHASE DATE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            DatePicker(
                "Purchase Date",
                selection: $purchaseDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: Visual Status Picker

    private var statusPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INITIAL STATUS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(DeviceStatus.allCases) { s in
                    Button {
                        withAnimation(.snappy) { status = s }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: s.icon)
                                .font(.title3)
                                .foregroundStyle(status == s ? .white : s.color)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(status == s ? s.color : s.color.opacity(0.12))
                                )
                                .scaleEffect(status == s ? 1.1 : 1.0)

                            Text(s.rawValue)
                                .font(.caption2)
                                .fontWeight(status == s ? .bold : .regular)
                                .foregroundStyle(status == s ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: Save

    private func saveDevice() {
        let newDevice = Device(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            serialNumber: serialNumber.trimmingCharacters(in: .whitespaces),
            purchaseDate: purchaseDate,
            status: status
        )
        modelContext.insert(newDevice)

        // Success haptic
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        dismiss()
        // Trigger toast on parent view
        onSave?()
    }
}

// ============================================================
// MARK: - 7. DeviceDetailView
// ============================================================
/// Premium detail view with:
///  - Large gradient header card
///  - Glassmorphism info tiles
///  - Visual status selector
///  - Edit + Delete actions
struct DeviceDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var device: Device

    /// Optional callback fired after a successful edit save.
    var onSave: (() -> Void)? = nil

    @State private var showDeleteAlert: Bool = false
    @State private var showEditSheet: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ── Hero Header Card ──
                heroCard

                // ── Info Grid ──
                infoGrid

                // ── Status Selector ──
                statusSection

                // ── Edit Button ──
                editButton

                // ── Delete Button ──
                deleteButton
            }
            .padding()
        }
        .background(
            ZStack {
                Color(.systemGroupedBackground)
                LinearGradient(
                    colors: [
                        device.category.gradient[0].opacity(0.08),
                        device.category.gradient[1].opacity(0.04),
                        Color.clear,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditDeviceSheet(device: device, onSave: onSave)
        }
        .alert("Delete Device?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteDevice()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Are you sure you want to delete \"\(device.name)\"? This action cannot be undone.")
        }
    }

    // MARK: Hero Card

    /// Large card with gradient background showing device name,
    /// category, and icon.
    private var heroCard: some View {
        VStack(spacing: 16) {
            // Large gradient icon
            Image(systemName: device.category.icon)
                .font(.system(size: 44))
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: device.category.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: device.category.gradient[0].opacity(0.5), radius: 12, y: 6)
                )

            VStack(spacing: 4) {
                Text(device.name)
                    .font(.title)
                    .fontWeight(.bold)

                Text(device.category.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            StatusBadge(status: device.status)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            device.category.gradient[0].opacity(0.15),
                            device.category.gradient[1].opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(device.category.gradient[0].opacity(0.2), lineWidth: 1)
                )
                .shadow(color: device.category.gradient[0].opacity(0.15), radius: 16, y: 8)
        )
    }

    // MARK: Info Grid

    /// Two-column grid of glassmorphism info tiles.
    private var infoGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12
        ) {
            DetailInfoCard(
                icon: "number",
                label: "Serial Number",
                value: device.serialNumber,
                gradient: [.blue, .cyan]
            )

            DetailInfoCard(
                icon: "calendar",
                label: "Purchase Date",
                value: device.purchaseDate.formatted(date: .abbreviated, time: .omitted),
                gradient: [.green, .mint]
            )

            DetailInfoCard(
                icon: "clock",
                label: "Device Age",
                value: deviceAge,
                gradient: [.orange, .yellow]
            )

            DetailInfoCard(
                icon: device.category.icon,
                label: "Category",
                value: device.category.rawValue,
                gradient: device.category.gradient
            )
        }
    }

    // MARK: Status Section

    /// Visual status selector — tap to change status.
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATUS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(DeviceStatus.allCases) { s in
                    Button {
                        withAnimation(.snappy) {
                            device.status = s
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: s.icon)
                                .font(.title2)
                                .foregroundStyle(device.status == s ? .white : s.color)
                                .frame(width: 52, height: 52)
                                .background(
                                    Circle()
                                        .fill(device.status == s ? s.color : s.color.opacity(0.12))
                                )
                                .scaleEffect(device.status == s ? 1.1 : 1.0)
                                .shadow(
                                    color: device.status == s ? s.color.opacity(0.4) : .clear,
                                    radius: 8, y: 4
                                )

                            Text(s.rawValue)
                                .font(.caption)
                                .fontWeight(device.status == s ? .bold : .regular)
                                .foregroundStyle(device.status == s ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: Edit Button

    private var editButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showEditSheet = true
        } label: {
            Label("Edit Device", systemImage: "pencil")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.indigo)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.indigo.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.indigo.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: Delete Button

    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } label: {
            Label("Delete Device", systemImage: "trash")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.red.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.red.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: Helpers

    /// Calculates a human-readable device age string.
    private var deviceAge: String {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: device.purchaseDate,
            to: .now
        )
        if let years = components.year, years > 0 {
            return "\(years)y \(components.month ?? 0)m"
        } else if let months = components.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s")"
        } else {
            return "\(components.day ?? 0) day\(components.day == 1 ? "" : "s")"
        }
    }

    private func deleteDevice() {
        modelContext.delete(device)
        dismiss()
    }
}

// ============================================================
// MARK: - 8. DetailInfoCard (Glassmorphism Tile)
// ============================================================
/// A single info tile with gradient icon, used in 2-column grid.
struct DetailInfoCard: View {
    let icon: String
    let label: String
    let value: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        )
    }
}

// ============================================================
// MARK: - 9. EditDeviceSheet
// ============================================================
/// A pre-filled modal sheet for editing an existing device's
/// name, serial number, category, purchase date, and status.
struct EditDeviceSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Bindable var device: Device

    /// Optional callback fired after a successful save.
    var onSave: (() -> Void)? = nil

    @State private var editName: String = ""
    @State private var editSerial: String = ""
    @State private var editCategory: DeviceCategory = .laptop
    @State private var editDate: Date = .now
    @State private var editStatus: DeviceStatus = .available

    private var isFormValid: Bool {
        !editName.trimmingCharacters(in: .whitespaces).isEmpty
            && !editSerial.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ── Category Selector ──
                    editCategorySection

                    // ── Device Info Fields ──
                    editInfoSection

                    // ── Purchase Date ──
                    editDateSection

                    // ── Status Picker ──
                    editStatusSection
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        applyEdits()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                // Pre-fill with current device values
                editName = device.name
                editSerial = device.serialNumber
                editCategory = device.category
                editDate = device.purchaseDate
                editStatus = device.status
            }
        }
    }

    // MARK: Category

    private var editCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATEGORY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(DeviceCategory.allCases) { cat in
                    Button {
                        withAnimation(.snappy) { editCategory = cat }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: cat.icon)
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: cat.gradient,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .opacity(editCategory == cat ? 1 : 0.4)
                                .scaleEffect(editCategory == cat ? 1.1 : 1.0)

                            Text(cat.rawValue)
                                .font(.caption2)
                                .fontWeight(editCategory == cat ? .bold : .regular)
                                .foregroundStyle(editCategory == cat ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: Info Fields

    private var editInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DEVICE INFORMATION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Device Name", text: $editName)
                        .autocorrectionDisabled()
                }
                .padding(14)

                Divider().padding(.leading, 48)

                HStack {
                    Image(systemName: "number")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Serial Number", text: $editSerial)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                }
                .padding(14)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: Date

    private var editDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PURCHASE DATE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            DatePicker(
                "Purchase Date",
                selection: $editDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: Status

    private var editStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATUS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(DeviceStatus.allCases) { s in
                    Button {
                        withAnimation(.snappy) { editStatus = s }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: s.icon)
                                .font(.title3)
                                .foregroundStyle(editStatus == s ? .white : s.color)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(editStatus == s ? s.color : s.color.opacity(0.12))
                                )
                                .scaleEffect(editStatus == s ? 1.1 : 1.0)

                            Text(s.rawValue)
                                .font(.caption2)
                                .fontWeight(editStatus == s ? .bold : .regular)
                                .foregroundStyle(editStatus == s ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    // MARK: Apply Edits

    private func applyEdits() {
        device.name = editName.trimmingCharacters(in: .whitespaces)
        device.serialNumber = editSerial.trimmingCharacters(in: .whitespaces)
        device.category = editCategory
        device.purchaseDate = editDate
        device.status = editStatus

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
        onSave?()
    }
}

// ============================================================
// MARK: - 10. ConfirmationToast
// ============================================================
/// A small floating toast shown briefly after saving or editing.
struct ConfirmationToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        )
    }
}

// ============================================================
// MARK: - Preview
// ============================================================
#Preview {
    ContentView()
        .modelContainer(for: Device.self, inMemory: true)
}
