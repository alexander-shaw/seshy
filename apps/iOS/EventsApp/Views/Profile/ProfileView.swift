//
//  ProfileView.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI
import CoreData

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
    @EnvironmentObject private var userSession: UserSessionViewModel
    @EnvironmentObject private var userProfileViewModel: UserProfileViewModel
    
    @State private var profileFlow: ProfileFlow?
    @StateObject private var settingsViewModel = UserSettingsViewModel(
        repository: CoreUserSettingsRepository()
    )

    private var mediaWidth: CGFloat {
        theme.sizes.screenWidth
    }

    private var mediaHeight: CGFloat {
        theme.sizes.screenWidth * 5 / 4
    }

    // Materialized and sorted media items.
    private var sortedMedia: [Media] {
        guard let mediaSet = userProfileViewModel.currentUserProfile?.media, !mediaSet.isEmpty else {
            print("ProfileView | Profile has no media.")
            return []
        }
        
        let sorted = Array(mediaSet).sorted(by: { $0.position < $1.position })
        
        // Forces materialization of properties and verify files exist.
        for media in sorted {
            let _ = media.id
            let url = media.url
            let _ = media.position
            let _ = media.mimeType
            
            // Verifies the media file exists.
            let source = MediaURLResolver.resolveURL(for: media)
            switch source {
                case .remote(let remoteURL):
                    print("Media \(media.id) - Remote URL:  \(remoteURL)")
                case .missing:
                    print("Media \(media.id) - FILE MISSING! URL:  \(url)")
            }
        }
        
        print("Displaying \(sorted.count) media items.")
        return sorted
    }

    var body: some View {
        VStack(spacing: 0) {
            TitleView(
                titleText: TabType.profileTab.rawValue, trailing: {
                    IconButton(icon: "gearshape.fill") {
                        profileFlow = .openSettings
                    }
                }
            )

            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // MARK: Media Carousel.
                        ZStack(alignment: .bottom) {
                            if !sortedMedia.isEmpty {
                                MediaCarouselView(
                                    mediaItems: sortedMedia,
                                    imageWidth: theme.sizes.screenWidth
                                )
                                .frame(width: mediaWidth, height: mediaHeight)
                            } else {
                                // Fallback when no media.
                                Rectangle()
                                    .fill(theme.colors.surface)
                                    .frame(width: mediaWidth, height: mediaHeight)
                            }

                            // MARK: Content Overlay.
                            VStack(alignment: .leading, spacing: theme.spacing.small) {
                                Spacer()

                                HStack {
                                    Text(userProfileViewModel.displayName)
                                        .titleStyle()
                                        .lineLimit(2)
                                        .truncationMode(.tail)

                                    Spacer()
                                    
                                    if userProfileViewModel.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(theme.colors.accent)
                                            .iconStyle()
                                    }
                                }
                            }
                            .padding(.horizontal, theme.spacing.medium)
                            .padding(.bottom, theme.spacing.medium)
                        }
                        .shadow(radius: theme.spacing.small)
                        
                        // MARK: Profile Details:
                        VStack(alignment: .leading, spacing: theme.spacing.medium) {
                            // Age:
                            if let age = userProfileViewModel.displayAge {
                                HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                                    Image(systemName: "birthday.cake")
                                        .bodyTextStyle()

                                    Text(age)
                                        .bodyTextStyle()
                                        .foregroundStyle(theme.colors.accent)

                                    Spacer()
                                }
                            }
                            
                            // Gender:
                            if let gender = userProfileViewModel.displayGender {
                                HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                                    Image(systemName: "person")
                                        .bodyTextStyle()
                                    
                                    Text(gender)
                                        .bodyTextStyle()
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding([.top, .horizontal], theme.spacing.medium)
                        
                        Divider()
                            .foregroundStyle(theme.colors.surface)
                            .padding(theme.spacing.medium)
                        
                        // Description (Bio).
                        if userProfileViewModel.hasBio {
                            Text(userProfileViewModel.bio)
                                .headlineStyle()
                                .padding(.horizontal, theme.spacing.medium)
                            
                            Divider()
                                .foregroundStyle(theme.colors.surface)
                                .padding(theme.spacing.medium)
                        }

                        // Tags (Vibes).
                        if !userProfileViewModel.vibes.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: theme.spacing.small) {
                                    ForEach(Array(userProfileViewModel.vibes), id: \.objectID) { vibe in
                                        Text(vibe.name)
                                            .font(theme.typography.caption)
                                            .foregroundStyle(theme.colors.offText)
                                            .padding(.vertical, theme.spacing.small / 2)
                                            .padding(.horizontal, theme.spacing.small / 2)
                                            .background(
                                                Capsule()
                                                    .fill(.clear)
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(theme.colors.surface, lineWidth: 1)
                                                    )
                                            )
                                    }
                                }
                                .padding(.horizontal, theme.spacing.medium)
                            }
                            .padding(.bottom, theme.spacing.large)
                        }
                    }
                    .padding(.bottom, 100)  // Space for bottom buttons.
                }
                .background(theme.colors.background)
            }
        }
        .background(theme.colors.background)
        .fullScreenCover(item: $profileFlow) { flow in
            if case .openSettings = flow {
                SettingsView(viewModel: settingsViewModel)
                    .onDisappear {
                        // Reload profile when settings view is dismissed
                        Task {
                            await userProfileViewModel.loadProfile(for: userSession.currentUser)
                        }
                    }
            }
        }
        .task {
            // Load profile when view appears
            await userProfileViewModel.loadProfile(for: userSession.currentUser)
        }
        .onChange(of: userSession.currentUser?.id) { _, _ in
            Task {
                await userProfileViewModel.loadProfile(for: userSession.currentUser)
            }
        }
    }
}
