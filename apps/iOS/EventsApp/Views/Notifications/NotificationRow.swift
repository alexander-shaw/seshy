//
//  NotificationRow.swift
//  EventsApp
//
//  Created by Шоу on 11/3/25.
//

import SwiftUI
import CoreData
import Kingfisher

struct NotificationRow: View {
    let notification: NotificationItem

    @Environment(\.theme) private var theme
    @Environment(\.managedObjectContext) private var viewContext
    @State private var event: EventItem?
    
    private let repository: EventItemRepository = CoreEventItemRepository()
    
    // Single media size for all notification types
    private var cardSize: CGFloat {
        theme.sizes.screenWidth / 6
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                handleRowTap()
            }) {
                HStack(alignment: .center, spacing: theme.spacing.small) {
                    // Unread Indicator:
                    /*
                    if notification.isUnread {
                        Circle()
                            .fill(theme.colors.accent)
                            .frame(width: theme.spacing.small * 3 / 4, height: theme.spacing.small * 3 / 4)
                    } else {
                        Spacer()
                            .frame(width: theme.spacing.small * 3 / 4)
                    }
                     */

                    // Media:
                    notificationMedia
                        .frame(width: cardSize, height: cardSize)

                    // Content:
                    VStack(alignment: .leading, spacing: theme.spacing.small / 2) {
                        Text(notification.title)
                            .bodyTextStyle()
                            .multilineTextAlignment(.leading)

                        if let subtitle = notification.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .captionTextStyle()
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer()

                    // Timestamp:
                    Text(EventDateTimeFormatter.notificationTimestamp(for: notification.timestamp))
                        .captionTitleStyle()
                }
            }
            
            // Action Buttons (only for yes/no, accept/decline notifications):
            if isActionable {
                HStack(spacing: theme.spacing.small) {
                    Spacer()
                        .frame(width: cardSize + theme.spacing.small)  // theme.spacing.small * 3 / 4

                    if let primaryAction = notification.primaryAction {
                        PrimaryButton(title: primaryAction) {
                            handleAction(primaryAction)
                        }
                    }
                    
                    if let secondaryAction = notification.secondaryAction {
                        PrimaryButton(title: secondaryAction, backgroundColor: AnyShapeStyle(theme.colors.surface)) {
                            handleAction(secondaryAction)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, theme.spacing.small)
            }
        }
        .task {
            if let eventID = notification.eventID {
                await loadEvent(id: eventID)
            }
        }
    }
    
    // MARK: - Media Components
    
    @ViewBuilder
    private var notificationMedia: some View {
        // Event-related notifications
        if notification.eventID != nil {
            eventPreviewCard
        }
        // Multiple users (metadata might contain user count)
        else if hasMultipleUsers {
            stackedAvatars
        }
        // Single user profile
        else if notification.userAvatar != nil || notification.userName != nil {
            profilePicture
        }
        // System notifications
        else {
            systemIcon
        }
    }
    
    @ViewBuilder
    private var eventPreviewCard: some View {
        // MARK: Media:
        Group {
            if let event = event, let firstMedia = getFirstMedia(from: event) {
                RemoteMediaImage(
                    media: firstMedia,
                    targetSize: CGSize(width: cardSize, height: cardSize)
                )
                .cornerRadius(theme.spacing.small)
            } else {
                // Fallback:
                ZStack {
                    RoundedRectangle(cornerRadius: theme.spacing.small)
                        .fill(theme.colors.surface)

                    // Bottom Blur Gradient.
                    VStack {
                        Spacer()

                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                theme.colors.background.opacity(0.80)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .frame(width: cardSize, height: cardSize)
            }
        }
        .shadow(radius: theme.spacing.small)
    }
    
    @ViewBuilder
    private var profilePicture: some View {
        Group {
            if let avatarURL = notification.userAvatar, !avatarURL.isEmpty, let url = URL(string: avatarURL) {
                KFImage(url)
                    .placeholder {
                        Circle()
                            .fill(theme.colors.surface)
                            .overlay {
                                if let name = notification.userName, !name.isEmpty {
                                    Text(String(name.prefix(1)).uppercased())
                                        .iconStyle()
                                } else {
                                    Image(systemName: "person.fill")
                                        .iconStyle()
                                        .foregroundStyle(theme.colors.offText)
                                }
                            }
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardSize, height: cardSize)
                    .clipShape(Circle())
            } else {
                // Fallback: circle with initials or icon.
                Circle()
                    .fill(theme.colors.surface)
                    .overlay {
                        if let name = notification.userName, !name.isEmpty {
                            Text(String(name.prefix(1)).uppercased())
                                .iconStyle()
                        } else {
                            Image(systemName: "person.fill")
                                .iconStyle()
                                .foregroundStyle(theme.colors.offText)
                        }
                    }
                    .frame(width: cardSize, height: cardSize)
            }
        }
    }
    
    @ViewBuilder
    private var stackedAvatars: some View {
        let avatarSize = cardSize * 0.75
        ZStack(alignment: .leading) {
            // First avatar.
            Circle()
                .fill(theme.colors.surface)
                .frame(width: avatarSize, height: avatarSize)
                .overlay {
                    Image(systemName: "person.fill")
                        .iconStyle()
                        .foregroundStyle(theme.colors.offText)
                }
            
            // Second avatar (offset)
            Circle()
                .fill(theme.colors.surface.opacity(0.8))
                .frame(width: avatarSize, height: avatarSize)
                .offset(x: avatarSize * 0.6)
                .overlay {
                    Image(systemName: "person.fill")
                        .iconStyle()
                        .foregroundStyle(theme.colors.offText)
                }
            
            // Third avatar (if more than 2)
            if userCount > 2 {
                Circle()
                    .fill(theme.colors.surface.opacity(0.6))
                    .frame(width: avatarSize, height: avatarSize)
                    .offset(x: avatarSize * 1.2)
                    .overlay {
                        if userCount > 3 {
                            Text("+\(userCount - 2)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(theme.colors.mainText)
                        } else {
                            Image(systemName: "person.fill")
                                .iconStyle()
                                .foregroundStyle(theme.colors.offText)
                        }
                    }
            }
        }
        .frame(width: avatarSize + (userCount > 1 ? avatarSize * 0.6 : 0) + (userCount > 2 ? avatarSize * 0.6 : 0), height: avatarSize)
    }
    
    @ViewBuilder
    private var systemIcon: some View {
        ZStack {
            Circle()
                .fill(theme.colors.surface)
            
            Image(systemName: iconName)
                .iconStyle()
                .foregroundStyle(theme.colors.offText)
        }
        .frame(width: cardSize, height: cardSize)
    }
    
    // MARK: - Computed Properties
    
    private var hasMultipleUsers: Bool {
        // Check metadata for user count or multiple user info
        if let metadata = notification.metadata,
           let countStr = metadata["userCount"],
           let count = Int(countStr), count > 1 {
            return true
        }
        // Check notification type for multiple users
        return notification.type == .newMemberJoined && notification.metadata?["userCount"] != nil
    }
    
    private var userCount: Int {
        if let metadata = notification.metadata,
           let countStr = metadata["userCount"],
           let count = Int(countStr) {
            return count
        }
        return 2 // Default for stacked avatars
    }
    
    // Only show buttons for yes/no, accept/decline notifications
    private var isActionable: Bool {
        switch notification.type {
        case .inviteReceived, .joinRequestReceived:
            return true // These need Accept/Decline buttons
        default:
            return false // All others are informative (tappable row)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFirstMedia(from event: EventItem) -> Media? {
        guard let mediaSet = event.media, !mediaSet.isEmpty else { return nil }
        let sorted = Array(mediaSet).sorted(by: { $0.position < $1.position })
        return sorted.first(where: { !$0.url.isEmpty })
    }
    
    private func loadEvent(id: UUID) async {
        do {
            event = try await repository.getEvent(by: id)
        } catch {
            print("Failed to load event for notification: \(error)")
        }
    }
    
    private func handleAction(_ action: String) {
        // TODO: Implement action handling
        print("Action tapped: \(action) for notification \(notification.id)")
    }
    
    private func handleRowTap() {
        // Handle tap on informative notifications
        // TODO: Implement navigation/action based on notification type
        if let primaryAction = notification.primaryAction {
            handleAction(primaryAction)
        } else {
            // Default action based on notification type
            switch notification.type {
            case .eventStartingSoon, .eventUpdated, .eventCancelled:
                if let eventID = notification.eventID {
                    // Navigate to event
                    print("Navigate to event: \(eventID)")
                }
            case .newMediaAdded:
                if let eventID = notification.eventID {
                    // Navigate to event media
                    print("Navigate to event media: \(eventID)")
                }
            case .newMemberJoined:
                if let eventID = notification.eventID {
                    // Navigate to event
                    print("Navigate to event: \(eventID)")
                }
            case .newFollower:
                if let userName = notification.userName {
                    // Navigate to user profile
                    print("Navigate to profile: \(userName)")
                }
            case .eventLiked:
                if let eventID = notification.eventID {
                    // Navigate to event
                    print("Navigate to event: \(eventID)")
                }
            default:
                break
            }
        }
    }

    private var iconName: String {
        switch notification.type {
            case .eventStartingSoon: return "bell.fill"
            case .eventUpdated: return "pencil"
            case .eventCancelled: return "xmark.circle.fill"
            case .newMediaAdded: return "photo.stack.fill"
            case .newMemberJoined: return "person.2.fill"
            case .newFollower: return "person.fill.badge.plus"
            case .eventLiked: return "heart.fill"
            case .joinRequestReceived: return "person.badge.plus"
            case .joinRequestApproved: return "checkmark.seal.fill"
            case .joinRequestDeclined: return "xmark.seal.fill"
            case .inviteReceived: return "envelope.fill"
            case .inviteAccepted: return "checkmark.seal.fill"
            case .inviteDeclined: return "xmark.seal.fill"
            case .systemWelcome: return "sparkles"
            case .accountVerified: return "checkmark.seal.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type {
            case .eventCancelled, .joinRequestDeclined, .inviteDeclined: return theme.colors.error
            case .joinRequestApproved, .inviteAccepted, .accountVerified, .eventStartingSoon: return theme.colors.success
            default: return theme.colors.accent
        }
    }
}
