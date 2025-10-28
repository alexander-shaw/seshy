//
//  EventColorPicker.swift
//  EventsApp
//
//  Created by Шоу on 10/26/25.
//

import SwiftUI
import UIKit

struct EventColorPicker: View {
    @Environment(\.theme) private var theme

    @Binding var selectedColorHex: String  // ViewModel binding: stores "#RRGGBB".

    @State private var hexInput: String = ""
    @State private var isHexValid: Bool = true

    // Curated palette (RRGGBB, no '#').
    private let palette: [String] = [
        "FF2D55", "FF3B30", "FF9500", "FFCC00",
        "34C759", "5AC8FA", "0A84FF", "007AFF",
        "5856D6", "AF52DE", "E5E5EA", "8E8E93"
    ]

    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.small) {
                    ForEach(palette, id: \.self) { hex in
                        let swatchColor = Color(hex: hex) ?? Color.clear
                        ColorSwatchView(
                            color: swatchColor,
                            isSelected: swatchColor.matches(Color(hex: selectedColorHex) ?? Color.clear)
                        ) {
                            // Persist as "#RRGGBB".
                            selectedColorHex = "#\(hex.uppercased())"
                            hexInput = hex.uppercased()
                            isHexValid = true
                        }
                        .hapticFeedback(.light)
                    }

                    // Input as Hex Value:
                    HStack(spacing: theme.spacing.small) {
                        Spacer(minLength: 0)

                        Image(systemName: "number")
                            .foregroundStyle(theme.colors.mainText)
                            .frame(width: theme.sizes.iconButton * 1 / 4, height: theme.sizes.iconButton * 1 / 4)

                        TextField("FFFFFF", text: $hexInput)
                            .foregroundStyle(theme.colors.mainText)
                            .fontWeight(.bold)
                            .captionTitleStyle()
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled(true)
                            .keyboardType(.asciiCapable)
                            .onChange(of: hexInput) { _, newValue in
                                normalizeAndApplyHex(newValue)
                            }

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, theme.spacing.small / 2)
                    .padding(.horizontal, theme.spacing.small)
                    .frame(height: theme.sizes.iconButton)
                    .background(Color(hex: selectedColorHex) ?? Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .hapticFeedback(.light)
                }
                .padding(.horizontal, theme.spacing.medium)
            }
        }
        .onAppear {
            // Seed the text field from the binding (strip '#').
            if let six = selectedColorHex.strippedHex6 {
                hexInput = six
            } else if let sixFromColor = Color(hex: selectedColorHex)?.hex6 {
                hexInput = sixFromColor
            }
        }
    }

    // Persist "#RRGGBB" in the binding as the user types.
    private func normalizeAndApplyHex(_ raw: String) {
        let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()

        // Soft clamp to 6 visible chars.
        hexInput = cleaned.count > 6 ? String(cleaned.prefix(6)) : cleaned

        if hexInput.count == 6, hexInput.isValidHex6 {
            isHexValid = true
            selectedColorHex = "#\(hexInput)"
        } else if hexInput.isEmpty {
            isHexValid = true
        } else {
            isHexValid = false
        }
    }
}

private struct ColorSwatchView: View {
    @Environment(\.theme) private var theme

    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: theme.sizes.iconButton, height: theme.sizes.iconButton)

                if isSelected {
                    Circle()
                        .fill(theme.colors.mainText)
                        .frame(width: theme.sizes.iconButton * 0.3, height: theme.sizes.iconButton * 0.3)
                }
            }
        }
    }
}
