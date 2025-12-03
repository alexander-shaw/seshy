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

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            Text("What's your name?")
                .headlineStyle()

            Text("Be yourself.  Being real starts with being you.")
                .fontWeight(.bold)
                .bodyTextStyle()
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer()

            TextFieldView(
                placeholder: "Name",
                specialType: .enterName,
                text: $userSession.userProfileViewModel.displayNameInput,
                autofocus: true
            )
            .textContentType(.givenName)
            .keyboardType(.default)
            .submitLabel(.done)

            Spacer()
        }
    }
}
