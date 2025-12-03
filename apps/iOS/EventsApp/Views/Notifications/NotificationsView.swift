//
//  NotificationsView.swift
//  EventsApp
//
//  Created by Шоу on 10/28/25.
//

import SwiftUI

struct NotificationsView: View {
    @Binding var bottomBarHeight: CGFloat
    
    @State private var notifications: [NotificationItem] = []

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            TitleView(titleText: TabType.notificationsTab.rawValue)

            if notifications.isEmpty {
                VStack {
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: theme.spacing.medium) {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                                .hapticFeedback(.light)
                        }
                    }
                    .padding(.vertical, theme.spacing.medium)
                    .padding(.horizontal, theme.spacing.medium)
                    .padding(.bottom, bottomBarHeight)
                }
            }
        }
        .background(theme.colors.background)
        .refreshable {
            loadNotifications()
        }
        .onAppear {
            loadNotifications()
        }
    }
    
    private func loadNotifications() {
        notifications = NotificationItem.generateFakeNotifications()
    }
}
