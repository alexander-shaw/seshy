//
//  ProfilePicturesStepView.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import SwiftUI

struct ProfilePicturesStepView: View {
    @ObservedObject var userSession: UserSessionViewModel
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            Text("What's your energy?")
                .headlineStyle()

            Text("Discover events you love.")
                .fontWeight(.bold)
                .bodyTextStyle()
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer()
            
            MediaGridPicker(
                mediaItems: $userSession.userProfileViewModel.selectedMediaItems,
                maxItems: 4
            )
            
            Spacer()
        }
    }
}


