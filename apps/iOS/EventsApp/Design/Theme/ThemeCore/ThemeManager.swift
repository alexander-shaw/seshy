//
//  ThemeManager.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI
import Combine
import CoreDomain

@MainActor
public class ThemeManager: ObservableObject {
    @Published public var currentTheme: AppTheme

    public init(initialTheme: AppTheme = .darkTheme) {
        self.currentTheme = initialTheme
    }
    
    // MARK: - THEME SWITCHING:

    public func switchToDark() {
        currentTheme = .darkTheme
    }
    
    public func switchToLight() {
        currentTheme = .lightTheme
    }
}

// MARK: - ENVIRONMENT INTEGRATION:

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

public extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

public extension View {
    func themeManager(_ manager: ThemeManager) -> some View {
        environment(\.themeManager, manager)
    }
}
