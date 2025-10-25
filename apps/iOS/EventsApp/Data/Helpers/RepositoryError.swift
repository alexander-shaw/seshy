//
//  RepositoryError.swift
//  EventsApp
//
//  Created by Шоу on 10/18/25.
//

// MARK: - RepositoryError:
// This file defines common errors that can occur in repository operations.
// Used across all repositories for consistent error handling.

import Foundation

public enum RepositoryError: Error, LocalizedError {
    case userNotFound
    case eventNotFound
    case inviteNotFound
    case memberNotFound
    case placeNotFound
    case tagNotFound
    case mediaNotFound
    case profileNotFound
    case settingsNotFound

    case invalidData
    case saveFailed
    case fetchFailed
    case deleteFailed
    case updateFailed
    case syncFailed
    case networkError(String)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .eventNotFound:
            return "Event not found"
        case .inviteNotFound:
            return "Invite not found"
        case .memberNotFound:
            return "Member not found"
        case .placeNotFound:
            return "Place not found"
        case .tagNotFound:
            return "Tag not found"
        case .mediaNotFound:
            return "Media not found"
        case .profileNotFound:
            return "Profile not found"
        case .settingsNotFound:
            return "Settings not found"

        case .invalidData:
            return "Invalid data provided"
        case .saveFailed:
            return "Failed to save data"
        case .fetchFailed:
            return "Failed to fetch data"
        case .deleteFailed:
            return "Failed to delete data"
        case .updateFailed:
            return "Failed to update data"
        case .syncFailed:
            return "Failed to sync data"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}


