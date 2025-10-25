//
//  UserSettingsViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// Manages user preferences and settings including appearance mode, map style, and units.
// Provides a reactive interface for SwiftUI views to observe and modify user settings.

import Foundation
import CoreData
import SwiftUI
import Combine
import CoreDomain

@MainActor
final class UserSettingsViewModel: ObservableObject {
    @Published var appearanceMode: AppearanceMode = .system
    @Published var mapStyle: MapStyle = .darkMap
    @Published var preferredUnits: Units = .imperial

    private let context: NSManagedObjectContext
    private var userSettings: UserSettings?

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
        loadSettings()
    }

    private func loadSettings() {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        do {
            if let existing = try context.fetch(request).first {
                userSettings = existing
                appearanceMode = existing.appearanceMode
                mapStyle = existing.mapStyle
                preferredUnits = existing.preferredUnits
            } else {
                createDefaultSettings()
            }
        } catch {
            print("Failed to fetch UserSettings:  ", error)
        }
    }

    func createDefaultSettings() {
        let new = UserSettings(context: context)
        new.appearanceMode = .system
        new.mapStyle = .darkMap
        new.preferredUnits = .imperial
        new.createdAt = Date()
        new.updatedAt = Date()
        save()
    }

    func save() {
        let settings = userSettings ?? UserSettings(context: context)
        settings.appearanceMode = appearanceMode
        settings.mapStyle = mapStyle
        settings.preferredUnits = preferredUnits
        settings.updatedAt = Date()
        do {
            try context.save()
            userSettings = settings
        } catch {
            print("Failed to save UserSettings:  ", error)
        }
    }
}
