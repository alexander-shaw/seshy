//
//  UserNotification.swift
//  EventsApp
//
//  Created by Шоу on 10/6/25.
//

// TODO: Refactor into CoreData.

import Foundation

// TODO: Move to CoreDomain.
enum NotificationType: String, CaseIterable {
    case inviteReceived = "inviteReceived"
    case inviteAccepted = "inviteAccepted"
    case inviteDeclined = "inviteDeclined"
    case joinRequestReceived = "joinRequestReceived"
    case joinRequestApproved = "joinRequestApproved"
    case joinRequestDeclined = "joinRequestDeclined"

    case eventStartingSoon = "eventStartingSoon"
    case eventUpdated = "eventUpdated"
    case eventCancelled = "eventCancelled"
    case newMediaAdded = "newMediaAdded"
    case newMemberJoined = "newMemberJoined"

    case newFollower = "newFollower"
    case eventLiked = "eventLiked"

    case systemWelcome = "systemWelcome"
    case accountVerified = "accountVerified"
}

// MARK: Notification Data Model:
struct NotificationItem: Identifiable {
    let id: UUID
    let type: NotificationType
    let timestamp: Date
    let isUnread: Bool
    
    // User-related
    let userName: String?
    let userAvatar: String?
    
    // Event-related
    let eventName: String?
    let eventID: UUID?
    let eventColor: String?
    
    // Content
    let title: String
    let subtitle: String?
    let metadata: [String: String]?
    
    // Actions
    let primaryAction: String?
    let secondaryAction: String?
}

// MARK: Fake Data for Testing UI/UX:
extension NotificationItem {
    static func generateFakeNotifications() -> [NotificationItem] {
        let now = Date()
        var notifications: [NotificationItem] = []
        
        // Invite notifications.
        notifications.append(NotificationItem(
            id: UUID(),
            type: .inviteReceived,
            timestamp: now.addingTimeInterval(-3600),  // 1 hour ago.
            isUnread: true,
            userName: "Alex Rivera",
            userAvatar: nil,
            eventName: "Summer BBQ Party",
            eventID: UUID(),
            eventColor: "#FF6B6B",
            title: "Alex Rivera invited you",
            subtitle: "Summer BBQ Party",
            metadata: nil,
            primaryAction: "Accept",
            secondaryAction: "Decline"
        ))
        
        notifications.append(NotificationItem(
            id: UUID(),
            type: .inviteAccepted,
            timestamp: now.addingTimeInterval(-7200),  // 2 hours ago.
            isUnread: true,
            userName: "Sarah Chen",
            userAvatar: nil,
            eventName: "Dance Party",
            eventID: UUID(),
            eventColor: "#4ECDC4",
            title: "Sarah Chen accepted your invite",
            subtitle: "Dance Party",
            metadata: nil,
            primaryAction: "View Event",
            secondaryAction: nil
        ))
        
        notifications.append(NotificationItem(
            id: UUID(),
            type: .inviteDeclined,
            timestamp: now.addingTimeInterval(-10800),  // 3 hours ago.
            isUnread: false,
            userName: "Jordan Kim",
            userAvatar: nil,
            eventName: "Study Group",
            eventID: UUID(),
            eventColor: "#95E1D3",
            title: "Jordan Kim declined your invite",
            subtitle: "Study Group",
            metadata: nil,
            primaryAction: "View Event",
            secondaryAction: nil
        ))
        
        // Join request notifications.
        notifications.append(NotificationItem(
            id: UUID(),
            type: .joinRequestReceived,
            timestamp: now.addingTimeInterval(-14400),  // 4 hours ago.
            isUnread: true,
            userName: "Taylor Morgan",
            userAvatar: nil,
            eventName: "Photography Workshop",
            eventID: UUID(),
            eventColor: "#FFD93D",
            title: "Taylor Morgan wants to join",
            subtitle: "Photography Workshop",
            metadata: nil,
            primaryAction: "Approve",
            secondaryAction: "Decline"
        ))
        
        notifications.append(NotificationItem(
            id: UUID(),
            type: .joinRequestApproved,
            timestamp: now.addingTimeInterval(-18000),  // 5 hours ago.
            isUnread: false,
            userName: "Casey Lee",
            userAvatar: nil,
            eventName: "Hiking Trip",
            eventID: UUID(),
            eventColor: "#6BCF7F",
            title: "Your request to join was approved",
            subtitle: "Hiking Trip",
            metadata: ["hostName": "Casey Lee"],
            primaryAction: "View Event",
            secondaryAction: nil
        ))
        
        // Event notifications.
        notifications.append(NotificationItem(
            id: UUID(),
            type: .eventStartingSoon,
            timestamp: now.addingTimeInterval(-600),  // 10 minutes ago.
            isUnread: true,
            userName: nil,
            userAvatar: nil,
            eventName: "Summer BBQ Party",
            eventID: UUID(),
            eventColor: "#FF6B6B",
            title: "Event starting soon",
            subtitle: "Summer BBQ Party starts in 2 hours",
            metadata: ["hoursUntil": "2"],
            primaryAction: "View Event",
            secondaryAction: "Dismiss"
        ))
        
        notifications.append(NotificationItem(
            id: UUID(),
            type: .eventUpdated,
            timestamp: now.addingTimeInterval(-86400),  // 1 day ago.
            isUnread: true,
            userName: nil,
            userAvatar: nil,
            eventName: "Dance Party",
            eventID: UUID(),
            eventColor: "#4ECDC4",
            title: "Event updated",
            subtitle: "Dance Party time changed to 8:00 PM",
            metadata: ["change": "time"],
            primaryAction: "View Event",
            secondaryAction: "Dismiss"
        ))
        
        notifications.append(NotificationItem(
            id: UUID(),
            type: .eventCancelled,
            timestamp: now.addingTimeInterval(-172800),  // 2 days ago.
            isUnread: false,
            userName: "Alex Rivera",
            userAvatar: nil,
            eventName: "Beach Party",
            eventID: UUID(),
            eventColor: "#FF6B6B",
            title: "Event cancelled",
            subtitle: "Beach Party has been cancelled",
            metadata: ["hostName": "Alex Rivera"],
            primaryAction: "View Details",
            secondaryAction: "Dismiss"
        ))
        
        notifications.append(NotificationItem(
            id: UUID(),
            type: .newMediaAdded,
            timestamp: now.addingTimeInterval(-259200),  // 3 days ago.
            isUnread: false,
            userName: nil,
            userAvatar: nil,
            eventName: "Beach Party",
            eventID: UUID(),
            eventColor: "#FF6B6B",
            title: "New photos added",
            subtitle: "5 new photos added to Beach Party",
            metadata: ["mediaCount": "5"],
            primaryAction: "View Photos",
            secondaryAction: nil
        ))
        
        notifications.append(NotificationItem(
            id: UUID(),
            type: .newMemberJoined,
            timestamp: now.addingTimeInterval(-345600),  // 4 days ago.
            isUnread: false,
            userName: "Morgan Taylor",
            userAvatar: nil,
            eventName: "Photography Workshop",
            eventID: UUID(),
            eventColor: "#FFD93D",
            title: "Morgan Taylor joined",
            subtitle: "Photography Workshop",
            metadata: nil,
            primaryAction: "View Event",
            secondaryAction: nil
        ))
        
        // Social notifications.
        notifications.append(NotificationItem(
            id: UUID(),
            type: .newFollower,
            timestamp: now.addingTimeInterval(-432000),  // 5 days ago.
            isUnread: false,
            userName: "Riley Park",
            userAvatar: nil,
            eventName: nil,
            eventID: nil,
            eventColor: nil,
            title: "Riley Park started following you",
            subtitle: nil,
            metadata: nil,
            primaryAction: "View Profile",
            secondaryAction: "Follow Back"
        ))
        
        notifications.append(NotificationItem(
            id: UUID(),
            type: .eventLiked,
            timestamp: now.addingTimeInterval(-518400),  // 6 days ago.
            isUnread: false,
            userName: "Alex Rivera",
            userAvatar: nil,
            eventName: "Summer BBQ Party",
            eventID: UUID(),
            eventColor: "#FF6B6B",
            title: "Alex Rivera liked",
            subtitle: "Summer BBQ Party",
            metadata: nil,
            primaryAction: "View Event",
            secondaryAction: nil
        ))
        
        // System notifications.
        notifications.append(NotificationItem(
            id: UUID(),
            type: .accountVerified,
            timestamp: now.addingTimeInterval(-604800),  // 7 days ago.
            isUnread: false,
            userName: nil,
            userAvatar: nil,
            eventName: nil,
            eventID: nil,
            eventColor: nil,
            title: "Account verified",
            subtitle: "Your account has been verified",
            metadata: nil,
            primaryAction: "View Profile",
            secondaryAction: "Dismiss"
        ))
        
        // Sort by timestamp (newest first).
        return notifications.sorted { $0.timestamp > $1.timestamp }
    }
}
