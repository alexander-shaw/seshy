//
//  GenderStepView.swift
//  EventsApp
//
//  Created by Шоу on 10/16/25.
//

import SwiftUI

struct GenderStepView: View {
    @ObservedObject var userSession: UserSessionViewModel
    @Environment(\.theme) private var theme

    @State private var selectedGender: GenderCategory = .unknown

    private let genderOptions: [(GenderCategory, String)] = [
        (.male, "Man"),
        (.female, "Woman"),
        (.nonbinary, "Nonbinary"),
        (.other, "More")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            Text("What's your gender?")
                .headlineStyle()

            Text("You can always update this later.")
                .fontWeight(.bold)
                .bodyTextStyle()
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer()

            if selectedGender != .other {
                VStack(spacing: theme.spacing.small) {
                    ForEach(genderOptions, id: \.0) { option, label in
                        Button {
                            withAnimation {
                                selectedGender = option
                                userSession.userProfileViewModel.genderIdentityInput = ""
                            }
                        } label: {
                            HStack(spacing: 0) {
                                Text(label)
                                    .buttonTextStyle()
                                    .padding(.leading, theme.spacing.small / 2)

                                Spacer()

                                SelectionIcon(
                                    isSelected: selectedGender == option,
                                    isExpandable: option == .other
                                )
                            }
                            .padding(theme.spacing.medium)
                            .background(Capsule().fill(theme.colors.surface))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: theme.spacing.large) {
                    HStack {
                        Spacer()
                        IconButton(icon: "chevron.left") {
                            selectedGender = .unknown
                            userSession.userProfileViewModel.genderIdentityInput = ""
                        }
                    }

                    TextFieldView(
                        icon: nil,
                        placeholder: "Identity",
                        specialType: .enterName,
                        text: $userSession.userProfileViewModel.genderIdentityInput,
                        autofocus: selectedGender == .other
                    )
                    .keyboardType(.default)
                    .submitLabel(.done)
                }
            }

            Toggle(isOn: $userSession.userProfileViewModel.showGenderToggle) {
                Text(userSession.userProfileViewModel.showGenderToggle ? "Public" : "Hidden")
                    .captionTitleStyle()
            }
            .toggleStyle(SwitchToggleStyle(tint: theme.colors.accent))
            .padding(.top, theme.spacing.small)

            Spacer()
        }
        .onAppear {
            let current = userSession.userProfileViewModel.genderCategorySelection
            selectedGender = current
            userSession.userProfileViewModel.genderCategorySelection = current
        }
        .onChange(of: selectedGender) {
            if selectedGender != .unknown {
                userSession.userProfileViewModel.genderCategorySelection = selectedGender
            }
        }
    }
}
