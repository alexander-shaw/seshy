//
//  VerificationCodeView.swift
//  EventsApp
//
//  Created by Шоу on 10/16/25.
//

import SwiftUI

struct VerificationCodeView: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool
    @Environment(\.theme) private var theme

    // TODO: Implement logic for resend code.

    var maxDigits: Int = 6
    var digits: [String] {
        let chars = Array(code.prefix(maxDigits))
        return (0..<maxDigits).map { index in
            index < chars.count ? String(chars[index]) : ""
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                HStack(spacing: theme.spacing.small) {
                    ForEach(0..<maxDigits, id: \.self) { index in
                        RoundedRectangle(cornerRadius: theme.spacing.small)
                            .fill(index == code.count ? theme.colors.mainText.opacity(0.33) : theme.colors.offText.opacity(0.25))
                            .frame(width: theme.sizes.digitField.width, height: theme.sizes.digitField.height)
                            .overlay(
                                Text(digits[index])
                                    .font(theme.typography.title)
                                    .fontDesign(.monospaced)
                                    .foregroundStyle(theme.colors.mainText)
                            )
                    }

                    Spacer()
                }

                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .accentColor(.clear)
                    .foregroundStyle(.clear)
                    .background(.clear)
                    .onChange(of: code) {
                        code = String(code.prefix(maxDigits).filter(\.isNumber))
                    }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
        .statusBarHidden(true)
        .onAppear {
            isFocused = true
        }
    }
}
