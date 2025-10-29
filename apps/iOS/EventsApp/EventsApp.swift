//
//  EventsAppApp.swift
//  EventsApp
//
//  Created by Шоу on 9/29/25.
//

import SwiftUI
import Combine  // Required for @Published and ObservableObject.
import CoreData
import CoreDomain

@main
struct EventsApp: App {

    private let theme = AppTheme()

    @StateObject private var userSession: UserSessionViewModel
    @StateObject private var tabManager = TabManager()
    
    @State private var discoverPath = NavigationPath()
    @State private var calendarPath = NavigationPath()
    @State private var newEventPath = NavigationPath()
    @State private var notificationsPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    
    init() {
        _userSession = StateObject(
            wrappedValue: UserSessionViewModel()
        )
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch userSession.appPhase {
                    case .splash:
                        SplashView()
                            .onAppear {
                                // Add a small delay for splash screen
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
            .theme(theme)
            .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
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
