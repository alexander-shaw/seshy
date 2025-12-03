//
//  DateOfBirthStepView.swift
//  EventsApp
//
//  Created by Шоу on 10/16/25.
//

import SwiftUI

struct DateOfBirthStepView: View {
    @ObservedObject var userSession: UserSessionViewModel
    @Environment(\.theme) private var theme

    @FocusState private var isFocused: Bool
    @State private var input: String = ""
    @State private var isValidDate = false
    @State private var parsedDate: Date? = nil

    let maxDigits = 8  // MMDDYYYY
    var digits: [String] {
        let chars = Array(input.prefix(maxDigits))
        return (0..<maxDigits).map { index in
            index < chars.count ? String(chars[index]) : ""
        }
    }

    var formattedInput: String {
        let raw = input.filter(\.isNumber)
        return formatInput(raw)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            Text("Your b-day?")
                .headlineStyle()

            Text("You cannot change this later.")
                .fontWeight(.bold)
                .bodyTextStyle()
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer()

            ZStack {
                VStack(spacing: theme.spacing.medium) {
                    HStack(spacing: theme.spacing.small) {
                        ForEach(0..<4, id: \.self) { index in
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: theme.spacing.small)
                                    .fill(index == input.count ? theme.colors.mainText.opacity(0.25) : theme.colors.offText.opacity(0.25))
                                    .frame(width: theme.sizes.digitField.width, height: theme.sizes.digitField.height)
                                    .overlay(
                                        Text(digits[index].isEmpty ? ["M", "M", "D", "D"][index] : digits[index])
                                            .font(theme.typography.title)
                                            .foregroundStyle(digits[index].isEmpty ? theme.colors.offText.opacity(0.75) : theme.colors.mainText)
                                    )

                                if index == 1 {
                                    Spacer()
                                        .frame(maxWidth: theme.spacing.small)
                                }
                            }
                        }

                        Spacer()
                    }

                    HStack(spacing: theme.spacing.small) {
                        ForEach(4..<8, id: \.self) { index in
                            RoundedRectangle(cornerRadius: theme.spacing.small)
                                .fill(index == input.count ? theme.colors.mainText.opacity(0.33) : theme.colors.offText.opacity(0.25))
                                .frame(width: theme.sizes.digitField.width, height: theme.sizes.digitField.height)
                                .overlay(
                                    Text(digits[index].isEmpty ? ["Y", "Y", "Y", "Y"][index - 4] : digits[index])
                                        .font(theme.typography.title)
                                        .fontDesign(.monospaced)
                                        .foregroundStyle(digits[index].isEmpty ? theme.colors.offText.opacity(0.75) : theme.colors.mainText)
                                )
                        }
                        Spacer()
                    }
                }

                TextField("", text: $input)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .accentColor(.clear)
                    .foregroundStyle(.clear)
                    .background(.clear)
                    .onChange(of: input) {
                        input = String(input.prefix(maxDigits).filter(\.isNumber))

                        guard input.count == maxDigits else {
                            isValidDate = false
                            parsedDate = nil
                            userSession.userProfileViewModel.dateOfBirthInput = nil
                            return
                        }

                        let formatted = formatInput(input)
                        if let date = parseDate(formatted) {
                            parsedDate = date
                            isValidDate = true
                            userSession.userProfileViewModel.dateOfBirthInput = date
                        } else {
                            isValidDate = false
                            parsedDate = nil
                            userSession.userProfileViewModel.dateOfBirthInput = nil
                        }
                    }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }

            Toggle(isOn: $userSession.userProfileViewModel.showAgeToggle) {
                Text(userSession.userProfileViewModel.showAgeToggle ? "Your age is public" : "Your age is hidden")
                    .captionTitleStyle()
            }
            .toggleStyle(SwitchToggleStyle(tint: theme.colors.accent))
            .padding(.top, theme.spacing.small)

            Spacer()
        }
        .onAppear {
            isFocused = true

            // Only preload if profile is already created or resuming from onboarding.
            if let savedDOB = userSession.userProfileViewModel.dateOfBirthInput {
                input = formatRaw(savedDOB)
                parsedDate = savedDOB
            } else {
                input = ""
                parsedDate = nil
                isValidDate = false
                userSession.userProfileViewModel.dateOfBirthInput = nil
            }
        }
    }

    private func formatInput(_ raw: String) -> String {
        var result = ""
        for (i, char) in raw.prefix(8).enumerated() {
            if i == 2 || i == 4 { result.append("/") }
            result.append(char)
        }
        return result
    }

    private func formatRaw(_ date: Date) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "MMddyyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.date(from: string)
    }
}
