//
//  SplashViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// Manages splash boot logic.  Transitions user session.

// TODO: Data loading and caching.
// TODO: Animated ring could be affected by inertial data!

import Foundation
import SwiftUI
import Combine

@MainActor
final class SplashViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var nextPhase: AppPhase = .splash

    private let vibeHydrator: SystemVibeHydrator
    private var hasStarted = false

    init(vibeHydrator: SystemVibeHydrator = SystemVibeHydrator()) {
        self.vibeHydrator = vibeHydrator
    }

    func performStartupSequence(using userSession: UserSessionViewModel) async {
        guard !hasStarted else { return }
        hasStarted = true

        isLoading = true

        do {
            try await vibeHydrator.refresh()
        } catch {
            print("\(error.localizedDescription)")
        }

        await userSession.evaluateSessionState()
        nextPhase = userSession.appPhase
        isLoading = false
    }
}
