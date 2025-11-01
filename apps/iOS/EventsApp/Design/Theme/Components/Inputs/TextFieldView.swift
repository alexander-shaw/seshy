//
//  TextFieldType.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//


import SwiftUI

public enum TextFieldType {
    case regular, phoneNumber
}

public struct TextFieldView: View {
    @Environment(\.theme) private var theme
    
    public var icon: Image?
    public var placeholder: String = ""
    public var specialType: TextFieldType = .regular
    @Binding public var text: String
    public var autofocus: Bool = false
    public var onSubmit: (() -> Void)? = nil

    @State private var displayedText: String = ""
    @FocusState private var isFocused: Bool

    public init(
        icon: Image? = nil,
        placeholder: String = "",
        specialType: TextFieldType = .regular,
        text: Binding<String>,
        autofocus: Bool = false,
        onSubmit: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.placeholder = placeholder
        self.specialType = specialType
        self._text = text
        self.autofocus = autofocus
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                icon
                    .font(theme.typography.icon)
                    .foregroundStyle(isFocused ? theme.colors.mainText : theme.colors.offText)
            }

            switch specialType {
            case .regular:
                TextField(placeholder, text: $text)
                    .font(theme.typography.title)
                    .minimumScaleFactor(0.67)
                    .foregroundStyle(isFocused ? theme.colors.mainText : theme.colors.offText)
                    .focused($isFocused)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: text) {
                        text = text.trimmingCharacters(in: .newlines)
                    }

            case .phoneNumber:
                TextField(placeholder, text: $displayedText)
                    .font(theme.typography.title)
                    .minimumScaleFactor(0.67)
                    .foregroundStyle(isFocused ? theme.colors.mainText : theme.colors.offText)
                    .keyboardType(.phonePad)
                    .focused($isFocused)
                    .onChange(of: displayedText) { oldValue, newValue in
                        // Preserve + and digits for autofill parsing (parent will parse country code).
                        // Remove everything except + and digits.
                        let cleaned = newValue.replacingOccurrences(of: "[^+0-9]", with: "", options: .regularExpression)
                        
                        // If the input contains a country code with digits, pass it to parent immediately.
                        // Don't update text binding if cleaned is empty - parent will handle formatting.
                        if !cleaned.isEmpty && cleaned != text {
                            // Update text binding so parent can parse it.
                            text = cleaned
                            // Parent will parse and update phoneInputText with formatted local number.
                            // We'll sync displayedText when parent updates via onChange(of: text).
                        } else if cleaned.isEmpty && !newValue.isEmpty {
                            // If cleaning removed everything but we had input, something went wrong.
                            // Don't update text binding with empty - preserve current value.
                            return
                        } else if cleaned == text {
                            // No change needed.
                            return
                        }
                    }
                    .onChange(of: text) { oldValue, newValue in
                        // Immediately sync displayedText when parent updates (e.g., after parsing/formatting).
                        // This ensures formatted local number (without country code) is shown immediately.
                        // Always update if the value is different and doesn't contain a country code.
                        if newValue != displayedText {
                            // Only show if it doesn't have a country code (parent handles that).
                            // If it's empty or just digits/formatted, show it.
                            if !newValue.hasPrefix("+") || newValue.isEmpty {
                                displayedText = newValue
                            }
                        }
                    }
                    .onAppear {
                        // Always sync displayedText with text binding on appear.
                        // This ensures the phone number is visible when returning to the view.
                        if !text.hasPrefix("+") {
                            displayedText = text
                        } else if text.isEmpty {
                            displayedText = ""
                        }
                    }
            }
        }
        .padding(.vertical, 8)
        .overlay(
            VStack {
                Spacer()
                Capsule()
                    .fill(isFocused ? theme.colors.mainText : theme.colors.offText)
                    .frame(height: 2)
            }
        )
        .onAppear { isFocused = autofocus }
        .onSubmit { onSubmit?() }
    }
    
    // Format up to 10 digits as local number: "000 000 0000".
    // Parent handles parsing country code and ensures only local number digits are passed here.
    private func formatPhoneNumber(_ digits: String) -> String {
        let clipped = String(digits.prefix(10))
        var formatted = ""
        for (index, digit) in clipped.enumerated() {
            if index == 3 || index == 6 { formatted += " " }
            formatted.append(digit)
        }
        return formatted
    }
}
