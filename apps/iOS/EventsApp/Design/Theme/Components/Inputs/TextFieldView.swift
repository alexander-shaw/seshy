//
//  TextFieldType.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//


import SwiftUI

public enum TextFieldType {
    case enterName
    case enterDigits
    case enterDollars
    case enterPhoneNumber
    case enterLocation
    case bigNumber
}

public struct TextFieldView: View {
    @Environment(\.theme) private var theme
    
    public var icon: Image?
    public var placeholder: String = ""
    public var specialType: TextFieldType = .enterName

    @Binding public var text: String
    public var autofocus: Bool = true
    public var onSubmit: (() -> Void)? = nil
    public var isLoading: Bool = false
    public var showSuccessIndicator: Bool = false

    @State private var displayedText: String = ""
    @FocusState private var isFocused: Bool

    public init(
        icon: Image? = nil,
        placeholder: String = "",
        specialType: TextFieldType = .enterName,
        text: Binding<String>,
        autofocus: Bool = false,
        onSubmit: (() -> Void)? = nil,
        isLoading: Bool = false,
        showSuccessIndicator: Bool = false
    ) {
        self.icon = icon
        self.placeholder = placeholder
        self.specialType = specialType
        self._text = text
        self.autofocus = autofocus
        self.onSubmit = onSubmit
        self.isLoading = isLoading
        self.showSuccessIndicator = showSuccessIndicator
    }

    public var body: some View {
        Group {
            switch specialType {
            case .bigNumber:
                bigNumberField
            default:
                standardField
            }
        }
        .onAppear {
            isFocused = autofocus
            if specialType == .enterPhoneNumber {
                syncPhoneDisplayText()
            }
        }
        .onSubmit {
            onSubmit?()
        }
    }
    
    // MARK: - Standard Field Layout (with icon and underline)
    @ViewBuilder
    private var standardField: some View {
        HStack(spacing: theme.spacing.small * 3 / 4) {
            if let icon = icon {
                icon
                    .foregroundStyle(isFocused ? theme.colors.mainText : theme.colors.offText)
                    .iconStyle()
            }

            textFieldContent
        }
        .padding(.vertical, theme.spacing.small * 3 / 4)
        .overlay(
            Group {
                VStack {
                    Spacer()
                    Capsule()
                        .fill(isFocused ? theme.colors.mainText : theme.colors.offText)
                        .frame(height: 2)
                }
            }
        )
    }
    
    // MARK: - Big Number Field (centered, no underline)
    @ViewBuilder
    private var bigNumberField: some View {
        HStack {
            Spacer()
            textFieldContent
            Spacer()
        }
        .padding(.vertical, theme.spacing.small * 3 / 4)
    }
    
    @ViewBuilder
    private var textFieldContent: some View {
        switch specialType {
        case .enterName:
            enterNameField
            
        case .enterDigits:
            enterDigitsField
            
        case .enterDollars:
            enterDollarsField
            
        case .enterPhoneNumber:
            enterPhoneNumberField
            
        case .enterLocation:
            enterLocationField
            
        case .bigNumber:
            bigNumberTextField
        }
    }
    
    // MARK: - Enter Name Field
    @ViewBuilder
    private var enterNameField: some View {
        TextField(placeholder, text: $text)
            .font(theme.typography.title)
            .minimumScaleFactor(0.67)
            .foregroundStyle(isFocused ? theme.colors.mainText : theme.colors.offText)
            .focused($isFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .onChange(of: text) {
                text = text.trimmingCharacters(in: .newlines)
            }
    }
    
    // MARK: - Enter Digits Field
    @ViewBuilder
    private var enterDigitsField: some View {
        TextField(placeholder, text: $text)
            .font(theme.typography.title)
            .minimumScaleFactor(0.67)
            .foregroundStyle(isFocused ? theme.colors.mainText : theme.colors.offText)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .onChange(of: text) { oldValue, newValue in
                // Only allow digits
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    text = filtered
                }
            }
    }
    
    // MARK: - Enter Dollars Field
    @ViewBuilder
    private var enterDollarsField: some View {
        TextField(placeholder, text: $text)
            .font(theme.typography.title)
            .minimumScaleFactor(0.67)
            .foregroundStyle(isFocused ? theme.colors.mainText : theme.colors.offText)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .onChange(of: text) { oldValue, newValue in
                // Allow digits and one decimal point
                var filtered = newValue.filter { $0.isNumber || $0 == "." }
                // Ensure only one decimal point
                let components = filtered.split(separator: ".")
                if components.count > 2 {
                    filtered = String(components[0]) + "." + components[1...].joined()
                }
                // Limit to 2 decimal places
                if let dotIndex = filtered.firstIndex(of: ".") {
                    let afterDot = String(filtered[filtered.index(after: dotIndex)...])
                    if afterDot.count > 2 {
                        filtered = String(filtered.prefix(through: filtered.index(dotIndex, offsetBy: 2)))
                    }
                }
                if filtered != newValue {
                    text = filtered
                }
            }
    }
    
    // MARK: - Enter Phone Number Field
    @ViewBuilder
    private var enterPhoneNumberField: some View {
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
    }
    
    // MARK: - Enter Location Field
    @ViewBuilder
    private var enterLocationField: some View {
        HStack(spacing: theme.spacing.small) {
            TextField(placeholder, text: $text)
                .font(theme.typography.title)
                .minimumScaleFactor(0.67)
                .foregroundStyle(isFocused ? theme.colors.mainText : theme.colors.offText)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .padding(.horizontal, theme.spacing.medium)
                .padding(.vertical, theme.spacing.medium * 0.75)
                .background(theme.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: theme.spacing.medium))
                .overlay(
                    Group {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.7)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, theme.spacing.medium)
                        } else if showSuccessIndicator {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.colors.accent)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, theme.spacing.medium)
                        }
                    }
                )
        }
    }
    
    // MARK: - Big Number Text Field (centered)
    @ViewBuilder
    private var bigNumberTextField: some View {
        TextField(placeholder, text: $text)
            .foregroundStyle(isFocused ? theme.colors.mainText : theme.colors.offText)
            .largeTitleStyle()
            .minimumScaleFactor(0.67)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .onChange(of: text) { oldValue, newValue in
                // Only allow digits
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    text = filtered
                }
            }
    }
    
    private func syncPhoneDisplayText() {
        // Always sync displayedText with text binding on appear.
        // This ensures the phone number is visible when returning to the view.
        if !text.hasPrefix("+") {
            displayedText = text
        } else if text.isEmpty {
            displayedText = ""
        }
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
