//
//  EventVisibility.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum EventVisibility: Int16, CaseIterable, Identifiable {
    case directInvites = 0  // Invite specific users.
    case requiresApproval = 1  // Invite specific users and anyone else can request to join.
    case openToAll = 2  // Anyone can join, without being invited or requesting to join.

    public var id: Int16 { rawValue }

    public var systemName: String {
        switch self {
            case .directInvites: return "lock.fill"
            case .requiresApproval: return "person.fill.questionmark"
            case .openToAll: return "globe"
        }
    }

    public var title: String {
        switch self {
            case .directInvites: return "Private"
            case .requiresApproval: return "Request to Join"
            case .openToAll: return "Public"
        }
    }

    public var description: String {
        switch self {
            case .directInvites: return "Only direct invites.  Invisible to everyone else."
            case .requiresApproval: return "Those not directly invited can request to join."
            case .openToAll: return "Discoverable and accessible by all."
        }
    }
}
