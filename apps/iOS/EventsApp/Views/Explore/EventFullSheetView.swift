//
//  EventFullSheetView.swift
//  EventsApp
//
//  Created by Шоу on 10/28/25.
//

import SwiftUI

struct EventFullSheetView: View {
    let event: EventItem

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSession: UserSessionViewModel
    
    @StateObject private var viewModel: EventViewModel
    @State private var joinViewModel: JoinEventViewModel?
    @State private var showJoinSheet = false
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    init(event: EventItem) {
        self.event = event
        _viewModel = StateObject(wrappedValue: EventViewModel())
    }

    private var mediaSize: CGFloat {
        theme.sizes.screenWidth
    }

    // Materialized and sorted media items.
    private var sortedMedia: [Media] {
        // Force materialization of media relationship to ensure it's loaded
        // Accessing event.media will trigger fault resolution if needed
        let mediaSet = event.media
        
        // Check if relationship exists
        guard let mediaSet = mediaSet else {
            print("EventFullSheetView | Event '\(event.name)' (ID: \(event.id)) has nil media relationship")
            return []
        }
        
        // Force fault resolution by accessing count and iterating
        let count = mediaSet.count
        print("EventFullSheetView | Event '\(event.name)' has \(count) media items in relationship")
        
        guard count > 0 else {
            print("EventFullSheetView | Event '\(event.name)' has empty media set")
            return []
        }
        
        // Convert to array and sort
        let sorted = Array(mediaSet).sorted(by: { $0.position < $1.position })
        
        // Force materialization of all media properties
        for media in sorted {
            let _ = media.id
            let url = media.url
            let _ = media.position
            let _ = media.mimeType
            
            // Log media resolution status
            let source = MediaURLResolver.resolveURL(for: media)
            switch source {
                case .remote(let remoteURL):
                    print("EventFullSheetView | Media \(media.id) - Remote URL: \(remoteURL)")
                case .missing:
                    print("EventFullSheetView | Media \(media.id) - Missing/invalid URL (will show placeholder): '\(url)'")
            }
        }
        
        print("EventFullSheetView | Returning \(sorted.count) sorted media items for carousel")
        return sorted
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: Media Carousel.
                    ZStack {
                        // Always show carousel if media items exist, even if URLs are invalid
                        // Carousel will show placeholders for missing/invalid URLs
                        if !sortedMedia.isEmpty {
                            MediaCarouselView(
                                mediaItems: sortedMedia,
                                imageWidth: theme.sizes.screenWidth,
                                imageHeight: mediaSize
                            )
                            .onAppear {
                                print("EventFullSheetView | MediaCarouselView appeared with \(sortedMedia.count) items")
                            }
                        } else {
                            Rectangle()
                                .fill(theme.colors.surface)
                                .frame(width: mediaSize, height: mediaSize)
                                .onAppear {
                                    print("EventFullSheetView | Showing placeholder rectangle - no media items")
                                }
                        }
                        
                        // MARK: Content Overlay.
                        VStack(alignment: .leading, spacing: theme.spacing.small) {
                            HStack {
                                Spacer()
                                
                                // Context Menu Button
                                Menu {
                                    Button(action: {
                                        Task {
                                            await viewModel.toggleBookmark()
                                        }
                                    }) {
                                        Label(viewModel.isBookmarked ? "Unwatch" : "Watch",
                                              systemImage: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                                    }
                                    
                                    Button(action: reportEvent) {
                                        Label("Report Event", systemImage: "exclamationmark.triangle")
                                    }
                                    
                                    if viewModel.isUserHost {
                                        Button(action: { showEditSheet = true }) {
                                            Label("Edit Event", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                                            Label("Delete Event", systemImage: "trash")
                                        }
                                    }
                                } label: {
                                    IconButton(icon: "ellipsis", style: .secondary) {}
                                }
                            }
                            
                            Spacer()

                            HStack {
                                Text(event.name)
                                    .titleStyle()
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(2)
                                    .truncationMode(.tail)

                                Spacer()
                            }
                        }
                        .padding(theme.spacing.medium)
                    }
                    .shadow(radius: theme.spacing.small)
                    
                    // MARK: Event Details:
                    VStack(alignment: .leading, spacing: theme.spacing.medium) {
                        // Date/s & Time/s.
                        if let startTime = event.startTime {
                            let dateDescription: String = {
                                if event.isAllDay {
                                    let dayLabel = EventDateTimeFormatter.calendarHeader(for: startTime)
                                    return "\(dayLabel) • All Day"
                                } else if let endTime = event.endTime {
                                    return EventDateTimeFormatter.detailRange(start: startTime, end: endTime)
                                } else {
                                    return EventDateTimeFormatter.cardPreview(for: startTime, isAllDay: event.isAllDay)
                                }
                            }()

                            HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                                Image(systemName: "calendar")
                                    .bodyTextStyle()
                                
                                Text(dateDescription)
                                    .bodyTextStyle()
                                    .foregroundStyle(theme.colors.accent)
                                
                                Spacer()
                            }
                            .onTapGesture {
                                // TODO: Open Calendar.
                            }
                        }
                        
                        // Location.
                        if let place = event.location {
                            HStack(alignment: .center, spacing: theme.spacing.small / 2) {
                                Image(systemName: "map")
                                    .bodyTextStyle()
                                
                                Text(place.name)
                                    .bodyTextStyle()
                                
                                Spacer()
                            }
                            .onTapGesture {
                                // TODO: Open Apple Maps.
                            }
                        }
                    }
                    .padding([.top, .horizontal], theme.spacing.medium)
                    
                    Divider()
                        .foregroundStyle(theme.colors.surface)
                        .padding(theme.spacing.medium)
                    
                    // Description.
                    if let details = event.details, !details.isEmpty {
                        Text(details)
                            .headlineStyle()
                            .padding(.horizontal, theme.spacing.medium)
                    }

                    Divider()
                        .foregroundStyle(theme.colors.surface)
                        .padding(theme.spacing.medium)

                    // Tags.
                    if let vibes = event.vibes, !vibes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.small) {
                                ForEach(Array(vibes), id: \.objectID) { vibe in
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
            
            // MARK: RSVP Buttons.
            VStack(spacing: theme.spacing.small) {
                if let joinVM = joinViewModel {
                    PrimaryButton(
                        title: joinVM.buttonTitle,
                        isDisabled: joinVM.isButtonDisabled
                    ) {
                        Task {
                            await handleJoinButtonTap()
                        }
                    }
                } else {
                    PrimaryButton(title: "Join", isDisabled: true) {}
                }
            }
            .padding(.horizontal, theme.spacing.medium)
            .padding(.bottom, theme.spacing.small)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        theme.colors.background.opacity(0.05),
                        theme.colors.background.opacity(0.50),
                        theme.colors.background
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinEventSheet(
                event: event,
                currentUserID: userSession.currentUser?.id
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            // TODO: Implement Edit Event sheet
            Text("Edit Event")
                .presentationDetents([.large])
        }
        .confirmationDialog("Delete Event", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteEvent(id: event.id)
                        dismiss()
                    } catch {
                        errorMessage = "Failed to delete event: \(error.localizedDescription)"
                        showError = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .task {
            // Load the event into the view model
            await viewModel.loadEvent(id: event.id)
            await viewModel.checkIfUserIsHost(userSession: userSession)
            
            // Force materialization of media relationship to ensure it's loaded
            // This helps ensure the carousel displays even if media URLs are invalid
            let _ = sortedMedia.count
            print("EventFullSheetView | Task: Materialized \(sortedMedia.count) media items for event '\(event.name)'")
        }
        .onAppear {
            // Initialize joinViewModel with current user ID
            joinViewModel = JoinEventViewModel(
                event: event,
                currentUserID: userSession.currentUser?.id
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleJoinButtonTap() async {
        guard let joinVM = joinViewModel else { return }
        
        // If multiple tickets, show sheet
        if joinVM.shouldShowTicketSheet {
            showJoinSheet = true
            return
        }
        
        // Otherwise, handle directly (free or single paid ticket)
        do {
            try await joinVM.handleJoinButtonTap()
            // Success - dismiss if needed (joinViewModel handles this internally)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func reportEvent() {
        // TODO: Implement report event functionality
        print("Report event: \(event.id)")
    }
}
