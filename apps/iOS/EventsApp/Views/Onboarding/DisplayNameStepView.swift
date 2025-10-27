//
//  DisplayNameStepView.swift
//  EventsApp
//
//  Created by Шоу on 10/16/25.
//

import SwiftUI

struct DisplayNameStepView: View {
    @ObservedObject var userSession: UserSessionViewModel
    @Environment(\.theme) private var theme
    var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Text("What's your name?")
                .headlineStyle()

            Text("Be yourself.  Being real starts with being you.")
                .bodyTextStyle()

            Spacer()

            TextFieldView(
                placeholder: "Name",
                text: $userSession.userProfileViewModel.displayNameInput,
                autofocus: isFocused
            )
            .textContentType(.givenName)
            .keyboardType(.default)
            .submitLabel(.done)

            Spacer()
        }
    }
}
