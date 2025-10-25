//
//  UserEvents.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum UserEventStatus: Int16 {
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

public enum UserEventVisibility: Int16 {
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
