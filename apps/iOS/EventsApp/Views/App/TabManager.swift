//
//  TabManager.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI
import Combine

class TabManager: ObservableObject {
    @Published var currentTab: TabType = .discoverTab
    var lastTab: TabType = .discoverTab

    func select(_ newTab: TabType) {
        lastTab = currentTab
        currentTab = newTab
    }
}
