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
    var tab: Tab
    var selectedTab: Tab
    var action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(theme.typography.icon)
                .foregroundStyle(selectedTab == tab ? theme.colors.mainText : theme.colors.offText)
                .frame(minWidth: theme.sizes.iconButton)
                .contentShape(Rectangle())
        }
        .padding(.top, theme.spacing.small)
        .padding(.bottom, theme.spacing.small)
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(.light)
    }
}
