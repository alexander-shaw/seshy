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
            Text("Pick your photos & videos")
                .headlineStyle()

            Text("At least one required—tap to delete, drag to recorder.")
                .bodyTextStyle()

            Spacer()
            
            MediaGridPicker(
                mediaItems: $userSession.userProfileViewModel.selectedMediaItems,
                maxItems: 4,
                title: nil,
                subtitle: nil
            )
            
            Spacer()
        }
    }
}


