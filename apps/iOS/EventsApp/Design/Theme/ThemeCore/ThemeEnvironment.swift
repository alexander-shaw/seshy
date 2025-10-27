//
//  ThemeEnvironment.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme()
}

public extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

public extension View {
    func theme(_ theme: AppTheme) -> some View { environment(\.theme, theme) }
}
