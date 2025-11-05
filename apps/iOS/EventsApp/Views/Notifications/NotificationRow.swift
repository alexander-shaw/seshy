//
//  NotificationRow.swift
//  EventsApp
//
//  Created by Шоу on 11/3/25.
//

import SwiftUI

struct NotificationRow: View {
    let notification: NotificationItem

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.small) {
            // Unread Indicator:
            if notification.isUnread {
                Circle()
                    .fill(theme.colors.accent)
                    .frame(width: theme.spacing.small, height: theme.spacing.small)
            } else {
                Spacer()
                    .frame(width: theme.spacing.small)
            }

            // Icon or Avatar:
            iconView

            // Content:
            VStack(alignment: .leading, spacing: theme.spacing.small) {
                Text(notification.title)
                    .bodyTextStyle()

                if let subtitle = notification.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .captionTextStyle()
                }
            }

            Spacer()

            // Timestamp:
            Text(relativeTimeString(from: notification.timestamp))
                .captionTitleStyle()
        }
    }

    private var iconView: some View {
        Group {
            // Avatar:
            if let userName = notification.userName, let first = userName.first {
                Circle()
                    .fill(theme.colors.surface)
                    .frame(width: theme.sizes.iconButton, height: theme.sizes.iconButton)
                    .overlay(
                        Text(String(first).uppercased())
                            .foregroundColor(.accentColor)
                            .iconStyle()
                    )
            }
            // Icon based on type:
            else {
                Circle()
                    .fill(iconColor)
                    .frame(width: theme.sizes.iconButton, height: theme.sizes.iconButton)
                    .overlay(
                        Image(systemName: iconName)
                            .foregroundColor(iconColor)
                            .iconStyle()
                    )
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

private func relativeTimeString(from date: Date) -> String {
    let now = Date()
    let interval = now.timeIntervalSince(date)
    
    if interval < 60 {
        return "Just now"
    } else if interval < 3600 {
        return "\(Int(interval / 60))m"
    } else if interval < 86400 {
        return "\(Int(interval / 3600))h"
    } else if interval < 604800 {
        return "\(Int(interval / 86400))d"
    } else {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
