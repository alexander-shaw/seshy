//
//  EventsAppApp.swift
//  EventsApp
//
//  Created by Шоу on 9/29/25.
//

import SwiftUI
import Combine  // Required for @Published and ObservableObject.
import CoreData

@main
struct EventsApp: App {
    
    private let coreDataStack: CoreDataStack
    @StateObject private var tabManager = TabManager()
    
    @State private var discoverPath = NavigationPath()
    @State private var messagesPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    
    init() {
        let stack = CoreDataStack()
        self.coreDataStack = stack
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                MainContainerView(
                    tabManager: tabManager,
                    discoverPath: $discoverPath,
                    messagesPath: $messagesPath,
                    profilePath: $profilePath
                )
                .onOpenURL { handleDeepLink($0) }
            }
            .environment(\.managedObjectContext, coreDataStack.viewContext)
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Custom scheme.
        if url.scheme?.lowercased() == "invited" {
            route(fromPath: url.path.lowercased())
            return
        }

        // Universal link.
        if url.scheme?.lowercased() == "https",
           let host = url.host?.lowercased(),
           host == "downloadevents.app" || host == "www.downloadevents.app" {
            route(fromPath: url.path.lowercased())
        }
    }

    private func route(fromPath path: String) {
        switch true {
            case path.hasPrefix("/discover"): tabManager.select(.discoverTab)
        case path.hasPrefix("/messages"): tabManager.select(.messagesTab)
            case path.hasPrefix("/profile"): tabManager.select(.profileTab)
            default: break
        }
    }
}
