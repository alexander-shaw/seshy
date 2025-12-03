//
//  ThemeManager.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI
import Combine
import UIKit

@MainActor
public class ThemeManager: ObservableObject {
    @Published public var currentTheme: AppTheme
    @Published public var colorScheme: ColorScheme
    @Published public var shouldFollowSystem: Bool = true  // Whether to automatically follow system appearance
    
    private var cancellables = Set<AnyCancellable>()
    private var traitCollectionObserver: NSObjectProtocol?

    public init(initialTheme: AppTheme? = nil, shouldFollowSystem: Bool = true) {
        // Determine initial theme based on system appearance
        let systemColorScheme = UITraitCollection.current.userInterfaceStyle
        let initialColorScheme: ColorScheme = systemColorScheme == .dark ? .dark : .light
        self.colorScheme = initialColorScheme
        self.currentTheme = initialTheme ?? (initialColorScheme == .dark ? .darkTheme : .lightTheme)
        self.shouldFollowSystem = shouldFollowSystem
        
        // Observe system appearance changes
        observeSystemAppearance()
    }
    
    // MARK: - THEME SWITCHING:
    
    // Switch to dark theme
    public func switchToDark() {
        currentTheme = .darkTheme
        colorScheme = .dark
        shouldFollowSystem = false  // Lock to dark mode
    }
    
    // Switch to light theme
    public func switchToLight() {
        currentTheme = .lightTheme
        colorScheme = .light
        shouldFollowSystem = false  // Lock to light mode
    }
    
    // Switch theme based on system appearance and enable following system
    public func switchToSystemAppearance() {
        let systemStyle = UITraitCollection.current.userInterfaceStyle
        shouldFollowSystem = true  // Enable following system
        if systemStyle == .dark {
            currentTheme = .darkTheme
            colorScheme = .dark
        } else {
            currentTheme = .lightTheme
            colorScheme = .light
        }
    }
    
    // MARK: - SYSTEM OBSERVATION:
    
    private func observeSystemAppearance() {
        // Observe when app becomes active to catch appearance changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self = self, self.shouldFollowSystem else { return }
                self.switchToSystemAppearance()
            }
            .store(in: &cancellables)
        
        // Also observe when app enters foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self = self, self.shouldFollowSystem else { return }
                self.switchToSystemAppearance()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        if let observer = traitCollectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // Extensible for future themes (holidays, subscriber personalization, etc.)
    // Example: public func switchToHolidayTheme() { currentTheme = .holidayTheme }
    // Example: public func switchToCustomTheme(_ theme: AppTheme) { currentTheme = theme }
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

// ViewModifier to observe system color scheme changes
private struct SystemAppearanceObserver: ViewModifier {
    @Environment(\.colorScheme) private var systemColorScheme
    @ObservedObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .onChange(of: systemColorScheme) { oldValue, newValue in
                // Only update theme if we should follow system
                guard themeManager.shouldFollowSystem else { return }
                
                // Update theme when system color scheme changes
                if newValue == .dark {
                    themeManager.currentTheme = .darkTheme
                    themeManager.colorScheme = .dark
                } else {
                    themeManager.currentTheme = .lightTheme
                    themeManager.colorScheme = .light
                }
            }
            .onAppear {
                // Initial sync with system appearance if following system
                guard themeManager.shouldFollowSystem else { return }
                
                if systemColorScheme == .dark {
                    themeManager.currentTheme = .darkTheme
                    themeManager.colorScheme = .dark
                } else {
                    themeManager.currentTheme = .lightTheme
                    themeManager.colorScheme = .light
                }
            }
    }
}

public extension View {
    func themeManager(_ manager: ThemeManager) -> some View {
        environment(\.themeManager, manager)
    }
    
    // Modifier to observe system color scheme and update theme automatically
    func observeSystemAppearance(_ themeManager: ThemeManager) -> some View {
        modifier(SystemAppearanceObserver(themeManager: themeManager))
    }
}
