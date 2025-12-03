//
//  DiscoverSection.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation
import CoreData

// Represents a discover section with its own fetch strategy.
enum DiscoverSection: Identifiable, CaseIterable {
    case tonight
    case yourInvites
    case trending
    case friendsGoing
    
    var id: String {
        switch self {
        case .tonight: return "tonight"
        case .yourInvites: return "yourInvites"
        case .trending: return "trending"
        case .friendsGoing: return "friendsGoing"
        }
    }
    
    var title: String {
        switch self {
        case .tonight: return "Tonight"
        case .yourInvites: return "Your invites"
        case .trending: return "Trending"
        case .friendsGoing: return "Friends are going"
        }
    }
    
    var previewLimit: Int {
        switch self {
        case .tonight: return 6
        case .yourInvites: return 6
        case .trending: return 6
        case .friendsGoing: return 10
        }
    }
    
    /// Fetch function for this section. Returns all events for this section.
    /// In production, each section would have its own optimized fetch request.
    func fetchEvents(repository: EventItemRepository) async throws -> [EventItem] {
        switch self {
        case .tonight:
            // TODO: Fetch events happening tonight
            // Example: repository.getEventsForTonight()
            return try await repository.getPublishedEvents()
            
        case .yourInvites:
            // TODO: Fetch user's invited events
            // Example: repository.getInvitedEvents(for: userID)
            return try await repository.getPublishedEvents()
            
        case .trending:
            // TODO: Fetch trending events (based on views, engagement, etc.)
            // Example: repository.getTrendingEvents()
            return try await repository.getPublishedEvents()
            
        case .friendsGoing:
            // TODO: Fetch events where friends are attending
            // Example: repository.getEventsWithFriendsAttending()
            return try await repository.getPublishedEvents()
        }
    }
}