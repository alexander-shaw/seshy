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
        "FF3B30", "FF9500", "FFCC00", "34C759",
        "5AC8FA", "0A84FF", "007AFF", "5856D6",
        "AF52DE", "FF2D55", "E5E5EA", "8E8E93"
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

                    // Input Hex Value:
                    HStack(spacing: theme.spacing.small / 2) {
                        Spacer()

                        Text("#")
                            .captionTitleStyle()

                        TextField("HEX", text: $hexInput)
                            .captionTitleStyle()
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled(true)
                            .keyboardType(.asciiCapable)
                            .frame(height: theme.sizes.iconButton-4)
                            .onChange(of: hexInput) { _, newValue in
                                normalizeAndApplyHex(newValue)
                            }

                        Spacer()
                    }
                    .background(theme.colors.surface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: selectedColorHex) ?? Color.clear)
                            // .stroke(isHexValid ? (Color(hex: selectedColorHex) ?? Color.clear) : theme.colors.error, lineWidth: 2)
                    )
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
            Circle()
                .fill(color)
                .frame(width: theme.sizes.iconButton, height: theme.sizes.iconButton)
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? theme.colors.mainText : theme.colors.surface, lineWidth: isSelected ? 2 : 1)
                )
                // .shadow(radius: isSelected ? 2 : 0, y: isSelected ? 2 : 0)
        }
    }
}
