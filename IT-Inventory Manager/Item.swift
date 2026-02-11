//
//  Item.swift
//  IT-Inventory Manager — "TechVault"
//
//  Created by Egor Pylkov on 10.02.26.
//
//  MARK: - Data Model
//  This file defines the core data model for the TechVault app.
//  We use SwiftData's @Model macro for automatic persistence.
//  The two enums (DeviceCategory, DeviceStatus) conform to
//  String + Codable so SwiftData can store them natively.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - DeviceCategory Enum
/// Represents the type of IT hardware.
/// Each case carries a user-facing label, an SF Symbol icon name,
/// a gradient for premium card styling, and a sort order.
enum DeviceCategory: String, Codable, CaseIterable, Identifiable {
    case laptop = "Laptop"
    case monitor = "Monitor"
    case phone = "Phone"
    case accessory = "Accessory"

    var id: String { rawValue }

    /// SF Symbol name matching Apple's icon library.
    var icon: String {
        switch self {
        case .laptop: return "laptopcomputer"
        case .monitor: return "display"
        case .phone: return "iphone"
        case .accessory: return "keyboard"
        }
    }

    /// Sort order so categories appear in a logical sequence.
    var sortOrder: Int {
        switch self {
        case .laptop: return 0
        case .monitor: return 1
        case .phone: return 2
        case .accessory: return 3
        }
    }

    /// Premium gradient colors for category badges and cards.
    var gradient: [Color] {
        switch self {
        case .laptop:
            return [
                Color(red: 0.35, green: 0.5, blue: 1.0), Color(red: 0.55, green: 0.3, blue: 0.95),
            ]
        case .monitor:
            return [
                Color(red: 0.0, green: 0.8, blue: 0.7), Color(red: 0.0, green: 0.55, blue: 0.8),
            ]
        case .phone:
            return [
                Color(red: 1.0, green: 0.55, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.35),
            ]
        case .accessory:
            return [
                Color(red: 0.65, green: 0.35, blue: 0.9), Color(red: 0.9, green: 0.3, blue: 0.6),
            ]
        }
    }
}

// MARK: - DeviceStatus Enum
/// Tracks the current operational status of a device.
/// Each case provides a color and icon for quick visual identification.
enum DeviceStatus: String, Codable, CaseIterable, Identifiable {
    case available = "Available"
    case inUse = "In Use"
    case broken = "Broken"

    var id: String { rawValue }

    /// SF Symbol for the status badge.
    var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .inUse: return "person.fill"
        case .broken: return "exclamationmark.triangle.fill"
        }
    }

    /// Semantic SwiftUI Color for status indicators.
    var color: Color {
        switch self {
        case .available: return .green
        case .inUse: return .blue
        case .broken: return .red
        }
    }
}

// MARK: - Device Model
/// The main data entity persisted by SwiftData.
/// @Model generates the schema automatically — no manual
/// Core Data stack setup needed.
@Model
final class Device {
    var name: String
    var category: DeviceCategory
    var serialNumber: String
    var purchaseDate: Date
    var status: DeviceStatus

    /// Designated initializer with sensible defaults.
    init(
        name: String,
        category: DeviceCategory,
        serialNumber: String,
        purchaseDate: Date = .now,
        status: DeviceStatus = .available
    ) {
        self.name = name
        self.category = category
        self.serialNumber = serialNumber
        self.purchaseDate = purchaseDate
        self.status = status
    }
}
