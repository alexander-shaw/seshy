//
//  TabManager.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI
import Combine

enum Tab: String, CaseIterable {
    case discoverTab = "Discover"
    case calendarTab = "Calendar"
    case newEventTab = "New"
    case notificationsTab = "Notifications"
    case profileTab = "Profile"
}

enum DiscoverViewMode {
    case map
    case list
}

class TabManager: ObservableObject {
    @Published var currentTab: Tab = .discoverTab
    @Published var discoverViewMode: DiscoverViewMode = .map
    var lastTab: Tab = .discoverTab

    func select(_ newTab: Tab) {
        // If tapping the same tab, toggle discoverViewMode.
        if currentTab == newTab && newTab == .discoverTab {
            discoverViewMode = discoverViewMode == .map ? .list : .map
        } else {
            lastTab = currentTab
            currentTab = newTab
        }
    }
}
