//
//  BottomBarView.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI
import Combine

struct BottomBarView: View {
    @ObservedObject var tabManager: TabManager
    @StateObject private var connectivity = ConnectivityViewModel.shared
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Spacer()

                TabButton(icon: "location.north.fill", tab: .discoverTab, selectedTab: tabManager.currentTab) {
                    tabManager.select(.discoverTab)
                }
                .hapticFeedback(.light)

                Spacer()

                // square.stack.3d.up.fill
                // calendar.day.timeline.left
                TabButton(icon: "checkmark.circle.fill", tab: .calendarTab, selectedTab: tabManager.currentTab) {
                    tabManager.select(.calendarTab)
                }
                .hapticFeedback(.light)

                Spacer()

                TabButton(icon: "plus", tab: .newEventTab, selectedTab: tabManager.currentTab) {
                    tabManager.select(.newEventTab)
                }
                .hapticFeedback(.light)

                Spacer()

                TabButton(icon: "bell.fill", tab: .notificationsTab, selectedTab: tabManager.currentTab) {
                    tabManager.select(.notificationsTab)
                }
                .hapticFeedback(.light)

                Spacer()

                TabButton(icon: "person.fill", tab: .profileTab, selectedTab: tabManager.currentTab) {
                    tabManager.select(.profileTab)
                }
                .hapticFeedback(.light)

                Spacer()
            }
            .background(theme.colors.background)

            if !connectivity.isOnline {
                HStack {
                    Spacer()

                    Text("You're offline.")
                        .captionTitleStyle()
                        .padding(.vertical, theme.spacing.small)
                    
                    Spacer()
                }
                .background(theme.colors.background)
                .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            Divider()
                .foregroundStyle(theme.colors.surface)
        }
        .animation(.easeInOut(duration: 0.25), value: connectivity.isOnline)
    }
}

struct TabButton: View {
    var icon: String
    var tab: TabType
    var selectedTab: TabType
    var action: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            ZStack {
                // Filled background when selected.
                if selectedTab == tab {
                    Circle()
                        .fill(theme.colors.surface)
                        .frame(width: theme.sizes.iconButton, height: theme.sizes.iconButton)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: theme.sizes.iconButton, height: theme.sizes.iconButton)
                }

                Image(systemName: icon)
                    .font(tab == .newEventTab ? theme.typography.title : theme.typography.headline)
                    .foregroundStyle(selectedTab == tab ? theme.colors.mainText : theme.colors.offText)
            }
            .frame(minWidth: theme.sizes.iconButton)
            .contentShape(Circle())
        }
        .padding(.top, theme.spacing.small)
        .padding(.bottom, theme.spacing.small / 2)
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(.light)
    }
}
