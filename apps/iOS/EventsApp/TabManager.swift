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
    case messagesTab = "Messages"
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
