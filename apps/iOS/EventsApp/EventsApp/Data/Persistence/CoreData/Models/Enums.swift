//
//  Enums.swift
//  EventsApp
//
//  Created by Шоу on 10/6/25.
//

import Foundation
import UIKit

// MARK: - LOCATION & MOTION:

public enum MotionType: Int16 {
    case unknown = 0, walking = 1, running = 2, cycling = 3, driving = 4, flying = 5
}

// MARK: - PARTY EVENT:

@objc public enum PartyEventStatus: Int16 {
    case draft = 0
    case upcoming = 1  // Published and happening in the future.
    case live = 2  // Happening now.
    case ended = 3
    case cancelled = 4  // Explicitly ended.

    public var isFinal: Bool { self == .ended || self == .cancelled }

    public var displayName: String {
        switch self {
            case .draft: return "Draft"
            case .upcoming: return "Upcoming"
            case .live: return "Live"
            case .ended: return "Ended"
            case .cancelled: return "Cancelled"
        }
    }
}

@objc public enum PartyEventVisibility: Int16 {
    case directInvites = 0
    case requiresApproval = 1
    case openToAll = 2

    public var descriptionText: String {
        switch self {
            case .directInvites: return "Only direct invites."
            case .requiresApproval: return "Those not directly invited can request to join."
            case .openToAll: return "Discoverable and accessible by all users."
        }
    }
}

// MARK: - INVITES:

@objc public enum InviteType: Int16 {
    case invite = 0  // Host directly invites user.
    case request = 1  // User requests to join.
}

@objc public enum InviteStatus: Int16 {
    case pending = 0
    case approved = 1
    case declined = 2
    case expired = 3
    case revoked = 4
}

// MARK: - MEMBER:

// TODO: Pivot to MemberRole entity.
@objc public enum MemberRole: Int16 {
    case host = 0
    case staff = 1
    case guest = 2
}

@objc public enum MemberStatus: Int16 {
    case active = 0
    case pending = 1
    case removed = 2
}

// MARK: - GENDER:

public enum GenderCategory: Int16, CaseIterable, Codable {
    case male = 0
    case female = 1
    case nonbinary = 2
    case other = 3
}

// MARK: - TAGS:

@objc public enum TagCategory: Int16 {
    case custom = 0  // User-created.
    case vibe = 1  // High energy, chill, dancer, always laughing, chaotic fun, etc.
    case localePreference = 2  // House parties, rooftop, basement, etc.
    case hobbies = 3  // House music, cooking, surfing, philosophy, travel, etc.
    case musicTaste = 4  // EDM, jazz, indie rock, classic rock, lo-fi, classical, etc.
    case culturalTaste = 5  // Nostalgia binger, bookworm, reality TV addict, gamer, etc.
}

// MARK: - SETTINGS:

@objc public enum MapStyle: Int16 {
    case darkMap = 0  // Default.
    case lightMap = 1
    case streets = 2
    case outdoors = 3
    case satellite = 4
    case satelliteStreets = 5
}

extension MapStyle {
    static let displayOrder: [MapStyle] = [.darkMap, .lightMap, .streets, .outdoors, .satellite, .satelliteStreets]

    // Whether this map type is allowed in a given appearance.
    fileprivate func supports(_ mode: AppearanceMode) -> Bool {
        switch self {
            case .darkMap:
                return mode == .darkMode
            case .lightMap:
                return mode == .lightMode
            case .streets, .outdoors, .satellite, .satelliteStreets:
                return true  // Available in all AppearanceModes.
        }
    }
}

@objc public enum AppearanceMode: Int16 {
    case system = 0  // Default.
    case darkMode = 1
    case lightMode = 2
}

extension AppearanceMode {
    static func from(_ style: UIUserInterfaceStyle) -> AppearanceMode {
        switch style {
            case .light: return .lightMode
            case .dark: return .darkMode
            default: return .darkMode
        }
    }
}

@objc public enum Units: Int16 {
    case imperial = 0  // Default.
    case metric = 1
}

// MARK: - LOCAL AND CLOUD STORAGE:

@objc public enum SyncStatus: Int16 {
    case pending = 0
    case syncing = 1
    case synced = 2
    case failed = 3
    case conflict = 4
}

// MARK: - ERROR MESSAGES:

enum EventValidationError: LocalizedError {
    case emptyName
    case startTimeInPast
    case endTimeBeforeStartTime
    case eventAlreadyEnded
    case atMaxCapacity

    var errorDescription: String? {
        switch self {
            case .emptyName: return "Event name cannot be empty."
            case .startTimeInPast: return "Start time must be in the future."
            case .endTimeBeforeStartTime: return "End time must be after start time."
            case .eventAlreadyEnded: return "Cannot modify ended events."
            case .atMaxCapacity: return "Event is at maximum capacity."
        }
    }
}
