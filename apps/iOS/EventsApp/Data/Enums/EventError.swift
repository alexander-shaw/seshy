//
//  EventError.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum EventError: LocalizedError {
    case emptyName
    case endTimeBeforeStartTime
    case eventAlreadyEnded
    case atMaxCapacity

    public var errorDescription: String? {
        switch self {
            case .emptyName: return "Event name cannot be empty."
            case .endTimeBeforeStartTime: return "End time must be after start time."
            case .eventAlreadyEnded: return "Cannot modify ended events."
            case .atMaxCapacity: return "Event is at maximum capacity."
        }
    }
}
