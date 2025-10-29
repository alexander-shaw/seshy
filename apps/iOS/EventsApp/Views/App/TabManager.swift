//
//  TabManager.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

// TODO: Move Notifications View to Calendar Tab as a trailing button in the Title View.  Replace here and elsewhere with Messages Tab/View.

import SwiftUI
import Combine

enum Tab: String, CaseIterable {
    case discoverTab = "Discover"
    case calendarTab = "Calendar"
    case newEventTab = "New"
    case notificationsTab = "Notifications"
    case profileTab = "Profile"
}

class TabManager: ObservableObject {
    @Published var currentTab: Tab = .discoverTab
    var lastTab: Tab = .discoverTab

    func select(_ newTab: Tab) {
        lastTab = currentTab
        currentTab = newTab
    }
}
