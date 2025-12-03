//
//  AppPhase.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum AppPhase: Equatable {
    case splash  // Always first screen: warm cache, hydrate local state, etc.
    case welcome  // Entry screen.
    case phoneAuth  // Enter phone number.
    case onboarding  // Minimal onboarding (displayName, DOB, optional gender/tags/permissions).
    case home  // Main app.
}
