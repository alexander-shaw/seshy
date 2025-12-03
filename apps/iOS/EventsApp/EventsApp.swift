//
//  EventsApp.swift
//  EventsApp
//
//  Created by Шоу on 9/29/25.
//

import SwiftUI
import Combine  // Required for @Published and ObservableObject.
import CoreData
import UIKit  // Required for UIApplication notifications.

@main
struct EventsApp: App {

    @StateObject private var themeManager = ThemeManager()
    @StateObject private var userSession: UserSessionViewModel
    @StateObject private var tabManager = TabManager()
    
    @State private var discoverPath = NavigationPath()
    @State private var calendarPath = NavigationPath()
    @State private var newEventPath = NavigationPath()
    @State private var notificationsPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    
    // Sync engine for data synchronization.
    private let sync: SyncContainer
    
    init() {
        _userSession = StateObject(
            wrappedValue: UserSessionViewModel()
        )
        
        // Initialize sync engine with API client and repositories.
        let coreData = CoreDataStack.shared
        let api = HTTPAPIClient()
        let repos = Repos(
            publicProfileRepo: CorePublicProfileRepository(coreDataStack: coreData),
            settingsRepo: CoreUserSettingsRepository(coreDataStack: coreData),
            loginRepo: CoreUserLoginRepository(coreDataStack: coreData),
            stack: coreData
        )
        self.sync = SyncContainer(api: api, repos: repos)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch userSession.appPhase {
                    case .splash:
                        SplashView()
                            .onAppear {
                                // A small delay for splash screen.
                                // TODO: Should be based on real data loading and caching.
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    Task {
                                        await userSession.evaluateSessionState()
                                    }
                                }
                            }
                    
                    case .welcome:
                        WelcomeView(userSession: userSession)
                    
                    case .phoneAuth:
                        PhoneAuthView(userSession: userSession) {}

                    case .onboarding:
                        OnboardingStepsView(userSession: userSession)
                    
                    case .home:
                        MainContainerView(
                            tabManager: tabManager,
                            discoverPath: $discoverPath,
                            calendarPath: $calendarPath,
                            newEventPath: $newEventPath,
                            notificationsPath: $notificationsPath,
                            profilePath: $profilePath
                        )
                        .onOpenURL { handleDeepLink($0) }
                }
            }
            .theme(themeManager.currentTheme)
            .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
            .environmentObject(themeManager)
            .environmentObject(userSession)
            .environmentObject(userSession.userProfileViewModel)
            .observeSystemAppearance(themeManager)
            .onAppear {
                sync.engine.start()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                sync.engine.kick(reason: "foreground")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                sync.engine.stop()
            }
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
        case path.hasPrefix("/calendar"): tabManager.select(.calendarTab)
            case path.hasPrefix("/profile"): tabManager.select(.profileTab)
            default: break
        }
    }
}
