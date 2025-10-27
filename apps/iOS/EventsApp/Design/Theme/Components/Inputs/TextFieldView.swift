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
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .onChange(of: displayedText) {
                        let digits = displayedText.filter(\.isNumber)
                        if digits != text { text = digits }
                        let formatted = formatPhoneNumber(digits)
                        if formatted != displayedText { displayedText = formatted }
                    }
                    .onAppear {
                        displayedText = formatPhoneNumber(text)
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
