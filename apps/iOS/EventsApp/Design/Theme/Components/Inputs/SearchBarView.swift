//
//  SearchBarView.swift
//  EventsApp
//
//  Created by Шоу on 11/1/25.
//

import SwiftUI

public struct SearchBarView: View {
    @Environment(\.theme) private var theme
    
    @Binding public var text: String
    public let placeholder: String
    public var autofocus: Bool = false
    public var onNotFound: (() -> Void)? = nil  // Stub for edge case handling.
    
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        placeholder: String,
        autofocus: Bool = false,
        onNotFound: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.autofocus = autofocus
        self.onNotFound = onNotFound
    }
    
    public var body: some View {
        HStack(spacing: theme.spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(isFocused ? theme.colors.mainText : theme.colors.offText)
                .iconStyle()
            
            TextField(placeholder, text: $text)
                .bodyTextStyle()
                .focused($isFocused)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, theme.spacing.medium)
        .padding(.vertical, theme.spacing.medium)
        .background(theme.colors.surface)
        .clipShape(Capsule())
        .shadow(color: theme.colors.background.opacity(0.20), radius: 4, x: 0, y: 2)
        .onAppear {
            if autofocus {
                isFocused = true
            }
        }
    }
}
