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
    @StateObject private var connectivity = ConnectivityManager.shared

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Spacer()

                TabButton(icon: "location.north.fill", tab: .discoverTab, selectedTab: tabManager.currentTab) {
                    tabManager.select(.discoverTab)
                }

                Spacer()

                TabButton(icon: "square.stack.3d.up.fill", tab: .messagesTab, selectedTab: tabManager.currentTab) {
                    tabManager.select(.messagesTab)
                }

                Spacer()

                TabButton(icon: "person.fill", tab: .profileTab, selectedTab: tabManager.currentTab) {
                    tabManager.select(.profileTab)
                }

                Spacer()
            }
            .background(Theme.ColorPalette.background)

            if !connectivity.isOnline {
                HStack {
                    Spacer()
                    Text("You're offline.")
                        .captionTextStyle()
                        .fontWeight(.heavy)
                        .padding(.vertical, Theme.Spacing.elements)
                    Spacer()
                }
                .background(Theme.ColorPalette.background)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: connectivity.isOnline)
    }
}

struct TabButton: View {
    var icon: String
    var tab: Tab
    var selectedTab: Tab
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Theme.Font.icon)
                .foregroundStyle(selectedTab == tab ? Theme.ColorPalette.mainText : Theme.ColorPalette.offText)
                .frame(minWidth: Theme.Size.iconButton)
                .contentShape(Rectangle())
        }
        .padding(.top, Theme.Spacing.elements)
        // .padding(.bottom, Theme.Spacing.elements)
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(style: .light)
    }
}
