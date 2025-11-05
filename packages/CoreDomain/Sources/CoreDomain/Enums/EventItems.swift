//
//  EventItems.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum EventStatus: Int16 {
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

public enum EventVisibility: Int16 {
    case onlyUser = 0  // An event only visible to the user.
    case directInvites = 1  // Invite specific users.
    case requiresApproval = 2  // Invite specific users and anyone else can request to join.
    case openToAll = 3  // Anyone can join, without being invited or requesting to join.

    public var descriptionText: String {
        switch self {
            case .onlyUser: return "Only visible to you."
            case .directInvites: return "Only direct invites."
            case .requiresApproval: return "Those not directly invited can request to join."
            case .openToAll: return "Discoverable and accessible by all users."
        }
    }
}
