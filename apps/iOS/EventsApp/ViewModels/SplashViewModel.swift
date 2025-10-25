//
//  SplashViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// MARK: - SplashViewModel
// Manages the app startup and splash screen logic.
// Provides a reactive interface for SwiftUI views to handle app initialization including:
// - Startup sequence coordination;
// - Data loading and caching;
// - User session state determination; and
// - Transition to appropriate app phase.

// TODO: Animated ring could be affected by inertial data!

import Foundation
import SwiftUI
import CoreData
import Combine
import CoreDomain

// Manages splash boot logic.
// Ensures cached data and transitions user session.
@MainActor
final class SplashViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var statusMessage: String = "Initializing..."
    @Published var nextPhase: AppPhase = .splash

    private let context: NSManagedObjectContext
    @StateObject private var userSessionVM = UserSessionViewModel()

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func performStartupSequence() async {
        isLoading = true
        statusMessage = "Loading user session..."
        await Task.sleep(500_000_000)  // 0.5s mock delay.

        await userSessionVM.evaluateSessionState()

        // Mirror the userSessionVM phase after evaluation.
        nextPhase = userSessionVM.appPhase
        isLoading = false
    }
}
