//
//  NewEventView.swift
//  EventsApp
//
//  Created by Шоу on 11/26/25.
//

import SwiftUI

enum NewEventNavigationDestination: Hashable {
    case invites
}

// Main view for composing and editing events.
// Uses EventViewModel directly for all state management.
struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @StateObject private var viewModel = EventViewModel()
    @State private var activeSheet: EventComposerType?
    @State private var showExitConfirmation = false
    @State private var showSelectGuests = false
    private let tabManager: TabManager?
    private let requiresLocationForGuests: Bool

    init(tabManager: TabManager? = nil, requiresLocationForGuests: Bool = false) {
        self.tabManager = tabManager
        self.requiresLocationForGuests = requiresLocationForGuests
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                TitleView(
                    titleText: TabType.newEventTab.rawValue,
                    canGoBack: true,
                    backIcon: "chevron.left",
                    onBack: {
                        handleBackButton()
                    },
                    trailing: {
                        if !viewModel.drafts.isEmpty {
                            Menu {
                                ForEach(viewModel.drafts) { draft in
                                    Button(action: {
                                        Task {
                                            await viewModel.loadDraft(id: draft.id)
                                        }
                                    }) {
                                        Text(draft.name)
                                    }
                                }
                            } label: {
                                IconButton(icon: "folder") {}
                            }
                        }
                    }
                )
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: theme.spacing.small) {
                            MediaGridPicker(
                                mediaItems: $viewModel.selectedMediaItems,
                                maxItems: 4,
                                onMediaChanged: {
                                    viewModel.refreshThemeDefaults()
                                }
                            )

                            TextFieldView(
                                placeholder: "Event",
                                specialType: .enterName,
                                text: $viewModel.name,
                                autofocus: true
                            )
                            .id("eventNameField")

                            ForEach(optionRows) { row in
                                EventOptionRow(
                                    optionName: row.name,
                                    displayValue: row.displayValue,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            setActiveSheet(row.sheet)
                                        }
                                    }
                                )

                                if row.id != optionRows.last?.id {
                                    Divider()
                                        .foregroundStyle(theme.colors.surface)
                                }
                            }

                        }
                        .padding(.top, theme.spacing.medium)
                        .padding(.horizontal, theme.spacing.medium)
                        .padding(.bottom, 100)  // Space for bottom buttons.
                    }
                    .onAppear {
                        // Scroll to position the field in the top third of the screen.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                // Calculate anchor to position in top third (approximately 0.33 from top).
                                // Using UnitPoint(x: 0.5, y: 0.33) positions at 33% from top, centered horizontally.
                                proxy.scrollTo("eventNameField", anchor: UnitPoint(x: 0.5, y: 0.5))
                            }
                        }
                    }
                }
            }
            .background(theme.colors.background)
            
            // Bottom buttons.
            HStack(spacing: theme.spacing.medium) {
                Spacer()
                
                PrimaryButton(
                    title: "Send to →",
                    isDisabled: !viewModel.isReadyForGuests
                ) {
                    showSelectGuests = true
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
        .sheet(isPresented: $showSelectGuests) {
            SelectGuestsView(viewModel: viewModel, tabManager: tabManager)
                .presentationDetents([.large])
                .presentationBackgroundInteraction(.disabled)
                .presentationCornerRadius(theme.spacing.medium)
                .presentationDragIndicator(.hidden)
        }
        .sheet(item: $activeSheet) { sheet in
            sheetView(for: sheet)
                .presentationDetents([.large])
                .presentationBackgroundInteraction(.disabled)
                .presentationCornerRadius(theme.spacing.medium)
                .presentationDragIndicator(.hidden)
        }
        .task {
            await viewModel.loadDrafts()
        }
        .alert("Are you sure?", isPresented: $showExitConfirmation) {
            Button("Save Draft", role: .none) {
                Task {
                    await viewModel.saveDraftAndExit()
                    exitComposer()
                }
            }

            if viewModel.id != nil && viewModel.scheduleStatus == .draft {
                Button("Delete", role: .destructive) {
                    Task {
                        // Delete the event if it is a saved draft (has an ID and is draft status).
                        if viewModel.id != nil && viewModel.scheduleStatus == .draft {
                            await viewModel.deleteEvent()
                        }
                        exitComposer()
                    }
                }
            } else {
                Button("Cancel", role: .cancel) {
                    // Do nothing; just dismiss the alert.
                }
            }
        } message: {
            if viewModel.id != nil && viewModel.scheduleStatus == .draft {
                Text("Deleting cannot be undone.")
            } else {
                Text("Your event will not be saved.")
            }
        }
    }
}

private extension NewEventView {

    @ViewBuilder
    func sheetView(for sheet: EventComposerType) -> some View {
        switch sheet {
            case .time:
                DateTimeSheetView(
                    startTime: viewModel.startTime,
                    endTime: viewModel.endTime,
                    durationMinutes: viewModel.durationMinutes.map { Int($0) },
                    isAllDay: viewModel.isAllDay,
                    calendar: .current,
                    onChange: { snapshot, mode in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            handleTimeChange(snapshot: snapshot, mode: mode)
                        }
                    },
                    onDone: { setActiveSheet(nil) }
                )
            case .location:
                LocationSheetView(
                    selectedPlace: viewModel.selectedPlace,
                    onSelect: { place in
                        withAnimation {
                            viewModel.setLocationRepresentation(place)
                        }
                        setActiveSheet(nil)
                    },
                    onDone: { setActiveSheet(nil) }
                )
            case .details:
                DetailsSheetView(
                    text: viewModel.details,
                    onChange: { newValue in viewModel.details = newValue },
                    onDone: { setActiveSheet(nil) }
                )
            case .capacity:
                CapacitySheetView(
                    maxCapacity: Int(viewModel.maxCapacity),
                    onChange: { capacity in updateMaxCapacity(capacity) },
                    onDone: { setActiveSheet(nil) }
                )
            case .visibility:
                VisibilitySheetView(
                    selected: viewModel.visibility,
                    onChange: { visibility in
                        viewModel.visibility = visibility
                    },
                    onDone: { setActiveSheet(nil) }
                )
            case .vibes:
                VibesSheetView(
                    selectedVibes: viewModel.vibes,
                    onToggle: { vibe in toggleVibe(vibe) },
                    onDone: { setActiveSheet(nil) }
                )
            case .theme:
                ThemeSheetView(
                    viewModel: viewModel,
                    onDone: { setActiveSheet(nil) }
                )
            case .tickets:
                TicketSheetView(
                    selectedTickets: viewModel.selectedTickets,
                    onSelect: { tickets in
                        viewModel.setTickets(tickets)
                    },
                    onDone: { setActiveSheet(nil) }
                )
            case .team:
                TeamSheetView(
                    eventID: viewModel.id,
                    onDone: { setActiveSheet(nil) }
                )
        }
    }
    
    struct OptionRow: Identifiable {
        let id: String
        let name: String
        let displayValue: String?
        let sheet: EventComposerType
    }

    // Time: top, always first.
    // Place: second, when & where are always paired.
    // Visibility: who can see it in the app.
    // Tickets: right after visibility.
    // Capacity: how many bodies can actually fit (and can tie to tickets).
    // Vibes: quick taggy mood ("chill", "rager", "gamers-only", etc.).
    // Theme: stylistic / color / image theme.
    // Details: freeform text at the bottom, so it doesn't feel like homework.
    var optionRows: [OptionRow] {
        [
            OptionRow(
                id: "time",
                name: "Time",
                displayValue: viewModel.timePreviewText,
                sheet: .time
            ),
            OptionRow(
                id: "place",
                name: "Place",
                displayValue: viewModel.placePreviewText,
                sheet: .location
            ),
            OptionRow(
                id: "visibility",
                name: "Visibility",
                displayValue: viewModel.visibilityPreviewText,
                sheet: .visibility
            ),
            OptionRow(
                id: "tickets",
                name: "Tickets",
                displayValue: viewModel.ticketsPreviewText,
                sheet: .tickets
            ),
            OptionRow(
                id: "capacity",
                name: "Capacity",
                displayValue: viewModel.capacityPreviewText,
                sheet: .capacity
            ),
            OptionRow(
                id: "vibes",
                name: "Vibes",
                displayValue: viewModel.vibes.isEmpty ? nil : viewModel.vibesPreviewText,
                sheet: .vibes
            ),
            OptionRow(
                id: "theme",
                name: "Theme",
                displayValue: viewModel.themePreviewText,
                sheet: .theme
            ),
            OptionRow(
                id: "details",
                name: "Details",
                displayValue: viewModel.detailsPreviewText,
                sheet: .details
            ),
            OptionRow(
                id: "team",
                name: "Team",
                displayValue: "",  // TODO: viewModel.teamPreviewText,
                sheet: .team
            )
        ]
    }

    // MARK: - ACTIONS:
    func setActiveSheet(_ sheet: EventComposerType?) {
        activeSheet = sheet
    }
    
    func handleBackButton() {
        if viewModel.isDraftable {
            showExitConfirmation = true
        } else {
            exitComposer()
        }
    }
    
    func exitComposer() {
        if let tabManager {
            tabManager.select(tabManager.lastTab)
        } else {
            dismiss()
        }
    }

    // MARK: - SHEET HANDLERS:
    func handleTimeChange(snapshot: EventTimeSnapshot, mode: EventTimeMode) {
        let normalized = EventTimeConsistency.normalized(snapshot: snapshot, mode: mode, calendar: .current)
        viewModel.startTime = normalized.start
        viewModel.endTime = normalized.end
        viewModel.durationMinutes = normalized.durationMinutes.map { Int64($0) }
        viewModel.isAllDay = normalized.isAllDay
    }

    func updateMaxCapacity(_ capacity: Int?) {
        viewModel.maxCapacity = Int64(capacity ?? 0)  // Nil means unlimited.
    }

    func toggleVibe(_ vibe: String) {
        if viewModel.vibes.contains(vibe) {
            viewModel.vibes.remove(vibe)
        } else {
            viewModel.vibes.insert(vibe)
        }
    }
}
