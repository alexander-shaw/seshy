//
//  ProfileView.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI

enum ProfileFlow: Identifiable {
    case openSettings

    var id: String {
        switch self {
            case .openSettings: return "openSettings"
        }
    }
}

struct ProfileView: View {
    @Binding var bottomBarHeight: CGFloat
    @Environment(\.theme) private var theme
    
    @State private var profileFlow: ProfileFlow?
    @StateObject private var settingsViewModel = UserSettingsViewModel(
        repository: CoreUserSettingsRepository()
    )

    var body: some View {
        VStack(spacing: 0) {
            TitleView(
                titleText: "Profile", trailing: {
                    IconButton(icon: "gearshape.fill") {
                        profileFlow = .openSettings
                    }
                }
            )

            VStack {
                Spacer()
                AnimatedRingView()
                    .padding(.bottom, theme.spacing.large)
                Spacer()
            }
        }
        .background(theme.colors.background)
        .fullScreenCover(item: $profileFlow) { flow in
            if case .openSettings = flow {
                SettingsView(viewModel: settingsViewModel)
            }
        }
    }
}
