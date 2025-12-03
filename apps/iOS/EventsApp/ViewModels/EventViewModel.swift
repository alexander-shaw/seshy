//
//  EventViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import Combine
import CoreData
import SwiftUI

@MainActor
public final class EventViewModel: ObservableObject {
    // Event ID - nil for new events, set when editing existing event
    @Published var id: UUID?
    
    @Published var name: String = ""
    @Published var details: String = ""
    @Published var themePrimaryHex: String?
    @Published var themeSecondaryHex: String?
    @Published var themeMode: String = ThemePresetHelper.ThemeMode.auto.rawValue
    @Published var startTime: Date?
    @Published var endTime: Date?
    @Published var durationMinutes: Int64?
    @Published var isAllDay: Bool = false
    @Published var maxCapacity: Int64 = 100
    @Published var visibility: EventVisibility = .requiresApproval
    @Published var inviteLink: String?
    @Published var scheduleStatus: EventStatus = .upcoming
    
    @Published var selectedPlace: Place?
    @Published var tags: [Vibe] = []
    @Published var selectedTags: [Vibe] = []
    @Published var vibes: Set<String> = []  // Vibe names as strings for UI
    @Published var members: [Member] = []
    @Published var media: [Media] = []
    @Published var previewPhotos: [Media] = []
    @Published var invitedUsers: [UserProfile] = []
    @Published var selectedTicket: String?
    @Published var selectedTickets: Set<Ticket> = []
    
    // Temporary media items selected but not yet uploaded.
    @Published var selectedMediaItems: [MediaItem] = [] {
        didSet {
            guard selectedMediaItems != oldValue else { return }
            handleSelectedMediaItemsChanged()
        }
    }
    
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var drafts: [DraftInfo] = []
    @Published private(set) var isUserHost: Bool = false
    
    public struct DraftInfo: Identifiable {
        public let id: UUID
        public let name: String
        
        public init(id: UUID, name: String) {
            self.id = id
            self.name = name
        }
    }
    
    private let context: NSManagedObjectContext
    private let repository: EventItemRepository
    private let mediaRepository: MediaRepository
    private let placeRepository: PlaceRepository
    private let mediaUploadService: MediaUploadService
    private var userEvent: EventItem?
    private var hasUserDefinedBrandColor = false

    public init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: EventItemRepository = CoreEventItemRepository(), mediaRepository: MediaRepository = CoreMediaRepository(), placeRepository: PlaceRepository = CorePlaceRepository(), mediaUploadService: MediaUploadService = MediaUploadService()) {
        self.context = context
        self.repository = repository
        self.mediaRepository = mediaRepository
        self.placeRepository = placeRepository
        self.mediaUploadService = mediaUploadService

        // selectedPlace starts as nil - will be set when user selects a place
        self.selectedPlace = nil
    }
    
    func loadEvent(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let event = try await repository.getEvent(by: id) {
                userEvent = event
                populateFromEvent(event)
            }
        } catch {
            errorMessage = "Failed to load event:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createEvent() async {
        await performSimpleEventCreation(status: .draft, actionDescription: "create event")
    }
    
    func saveEvent() async {
        await performSimpleEventCreation(status: .draft, actionDescription: "save event")
    }
    
    func publishEvent() async {
        await performSimpleEventCreation(status: .upcoming, actionDescription: "publish event")
    }
    
    private func performSimpleEventCreation(status: EventStatus, actionDescription: String) async {
        isSaving = true
        errorMessage = nil
        
        do {
            let event = try await repository.createEvent(
                name: name,
                details: details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : details,
                themePrimaryHex: themePrimaryHex,
                themeSecondaryHex: themeSecondaryHex,
                themeMode: themeMode,
                startTime: startTime,
                endTime: endTime,
                durationMinutes: durationMinutes,
                isAllDay: isAllDay,
                location: selectedPlace,
                maxCapacity: maxCapacity,
                visibility: visibility,
                inviteLink: inviteLink,
                status: status
            )
            
            userEvent = event
            populateFromEvent(event)
            
                if !selectedMediaItems.isEmpty {
                try await uploadSelectedMedia(for: event.id)
            }
            
            // Stub: Cloud upsert for published events
            if status == .upcoming {
                print("📤 [STUB] Cloud upsert: Publishing event \(event.id) to cloud")
                // TODO: Implement actual cloud sync
                // await syncEngine.upsertEvent(event)
            }
        } catch {
            errorMessage = "Failed to \(actionDescription):  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func updateEvent() async {
        guard let event = userEvent else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            // Update the existing event directly.
            event.scheduleStatusRaw = scheduleStatus.rawValue
            event.name = name
            event.details = details.isEmpty ? nil : details
            event.themePrimaryHex = themePrimaryHex
            event.themeSecondaryHex = themeSecondaryHex
            event.themeMode = themeMode
            event.startTime = startTime
            event.endTime = endTime
            event.durationMinutes = durationMinutes.map { NSNumber(value: $0) }
            event.isAllDay = isAllDay
            event.maxCapacity = maxCapacity
            event.visibilityRaw = visibility.rawValue
            event.inviteLink = inviteLink
            event.updatedAt = Date()
            event.syncStatusRaw = SyncStatus.pending.rawValue
            
            // Update location relationship if needed.
            event.location = selectedPlace
            
            if let result = try await repository.updateEvent(event) {
                userEvent = result
                populateFromEvent(result)
            }
        } catch {
            errorMessage = "Failed to update event:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func deleteEvent() async {
        guard let event = userEvent else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try await repository.deleteEvent(event.id)
            userEvent = nil
            resetForm()
        } catch {
            errorMessage = "Failed to delete event:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    /// Delete event by ID (for use when viewing an event, not editing)
    func deleteEvent(id: UUID) async throws {
        try await repository.deleteEvent(id)
    }
    
    // MARK: - Bookmark Management
    
    var isBookmarked: Bool {
        userEvent?.isBookmarked ?? false
    }
    
    func toggleBookmark() async {
        guard let event = userEvent else { return }
        
        errorMessage = nil
        
        do {
            if let updatedEvent = try await repository.toggleBookmark(event.id) {
                userEvent = updatedEvent
                objectWillChange.send()
            }
        } catch {
            errorMessage = "Failed to update bookmark: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Host Check
    
    func checkIfUserIsHost(userSession: UserSessionViewModel) async {
        guard let currentUserID = userSession.currentUser?.id,
              let event = userEvent else {
            isUserHost = false
            return
        }
        
        // Check if current user is a host of this event
        let members = event.members
        isUserHost = members.contains { member in
            member.userID == currentUserID && member.roleRaw == MemberRole.host.rawValue
        }
    }
    
    func updateStatus(_ status: EventStatus) async {
        guard let event = userEvent else { return }
        
        do {
            if let result = try await repository.updateEventStatus(event.id, status: status) {
                userEvent = result
                scheduleStatus = status
                populateFromEvent(result)
            }
        } catch {
            errorMessage = "Failed to update event status:  \(error.localizedDescription)"
        }
    }
    
    func loadDrafts() async {
        do {
            // Fetch drafts using view context to avoid threading issues
            let draftEvents = try await context.perform {
                let request: NSFetchRequest<EventItem> = EventItem.fetchRequest()
                request.predicate = NSPredicate(format: "scheduleStatusRaw == %d", EventStatus.draft.rawValue)
                request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.updatedAt, ascending: false)]
                return try self.context.fetch(request)
            }
            
            // Extract draft info - now safe since we're using view context
            let draftInfos = draftEvents.map { event in
                DraftInfo(id: event.id, name: event.name)
            }
            
            // Update on main thread (viewModel is @MainActor)
            drafts = draftInfos
        } catch {
            errorMessage = "Failed to load drafts: \(error.localizedDescription)"
            drafts = []
        }
    }
    
    func loadDraft(id: UUID) async {
        await loadEvent(id: id)
        await loadDrafts() // Refresh drafts list
    }
    
    func saveDraftAndExit() async {
        await saveEvent()
        await loadDrafts()
    }
    
    func addTag(_ tag: Vibe) {
        if !tags.contains(where: { $0.id == tag.id }) {
            tags.append(tag)
        }
    }
    
    func removeTag(_ tag: Vibe) {
        tags.removeAll { $0.id == tag.id }
    }
    
    func addMember(_ member: Member) {
        if !members.contains(where: { $0.id == member.id }) {
            members.append(member)
        }
    }
    
    func removeMember(_ member: Member) {
        members.removeAll { $0.id == member.id }
    }
    
    func addMedia(_ media: Media) {
        if !self.media.contains(where: { $0.url == media.url }) {
            self.media.append(media)
        }
    }
    
    func removeMedia(_ media: Media) {
        self.media.removeAll { $0.url == media.url }
    }
    
    func addPreviewPhoto(_ photo: Media) {
        if !self.previewPhotos.contains(where: { $0.url == photo.url }) {
            self.previewPhotos.append(photo)
        }
    }
    
    func removePreviewPhoto(_ photo: Media) {
        self.previewPhotos.removeAll { $0.url == photo.url }
    }
    
    // MARK: - SELECTED MEDIA ITEMS MANAGEMENT:
    func addSelectedMedia(_ mediaItem: MediaItem) {
        if !selectedMediaItems.contains(where: { $0.id == mediaItem.id }) {
            var item = mediaItem
            item.position = Int16(selectedMediaItems.count)
            selectedMediaItems.append(item)
        }
    }
    
    func removeSelectedMedia(at index: Int) {
        guard index < selectedMediaItems.count else { return }
        selectedMediaItems.remove(at: index)
        updateSelectedMediaPositions()
    }
    
    func moveSelectedMedia(from source: Int, to destination: Int) {
        guard source < selectedMediaItems.count && destination < selectedMediaItems.count else { return }
        let movedItem = selectedMediaItems.remove(at: source)
        selectedMediaItems.insert(movedItem, at: destination)
        updateSelectedMediaPositions()
    }
    
    private func updateSelectedMediaPositions() {
        var updatedItems: [MediaItem] = []
        for (index, item) in selectedMediaItems.enumerated() {
            var updatedItem = item
            updatedItem.position = Int16(index)
            updatedItems.append(updatedItem)
        }
        selectedMediaItems = updatedItems
    }
    
    func applyBrandColor(_ colorString: String) {
        // Legacy method - now applies to themePrimaryHex
        let normalized = ThemeColorParser.normalizedString(from: colorString)
        let hex = ThemeColorParser.primaryHex(from: normalized)
        themePrimaryHex = hex
        themeSecondaryHex = hex
        themeMode = ThemePresetHelper.ThemeMode.custom.rawValue
        hasUserDefinedBrandColor = true
    }
    
    func resetBrandColorToAutomatic() {
        hasUserDefinedBrandColor = false
        syncEventThemeFromCoverMedia()
    }
    
    func refreshThemeDefaults() {
        handleSelectedMediaItemsChanged()
    }
    
    private func handleSelectedMediaItemsChanged() {
        syncBrandColorFromMedia()
        syncEventThemeFromCoverMedia()
    }
    
    private func syncBrandColorFromMedia() {
        guard hasUserDefinedBrandColor == false else { return }
        // This method is now handled by syncEventThemeFromCoverMedia
        syncEventThemeFromCoverMedia()
    }
    
    /// Syncs event theme from cover media (first media item) when themeMode is "auto"
    private func syncEventThemeFromCoverMedia() {
        guard themeMode == ThemePresetHelper.ThemeMode.auto.rawValue else { return }
        
        // Get the first media item (cover media)
        guard let coverMedia = selectedMediaItems.first(where: { $0.mediaKind == .image }),
              let primaryHex = coverMedia.primaryColorHex,
              let secondaryHex = coverMedia.secondaryColorHex else {
            // If no cover media with colors, try to get from existing media
            if let firstMedia = media.first,
               let primaryHex = firstMedia.primaryColorHex,
               let secondaryHex = firstMedia.secondaryColorHex {
                themePrimaryHex = primaryHex
                themeSecondaryHex = secondaryHex
            }
            return
        }
        
        themePrimaryHex = primaryHex
        themeSecondaryHex = secondaryHex
    }
    
    /// Sets the cover media and updates event theme if in auto mode
    func setCoverMedia(_ mediaItem: MediaItem) {
        // Move media item to first position
        if let index = selectedMediaItems.firstIndex(where: { $0.id == mediaItem.id }) {
            selectedMediaItems.remove(at: index)
            selectedMediaItems.insert(mediaItem, at: 0)
            updateSelectedMediaPositions()
        }
        
        // Update theme if in auto mode
        if themeMode == ThemePresetHelper.ThemeMode.auto.rawValue,
           let primaryHex = mediaItem.primaryColorHex,
           let secondaryHex = mediaItem.secondaryColorHex {
            themePrimaryHex = primaryHex
            themeSecondaryHex = secondaryHex
        }
    }
    
    /// Applies a theme preset mode
    func applyThemeMode(_ mode: ThemePresetHelper.ThemeMode) {
        themeMode = mode.rawValue
        
        // If not auto, generate preset colors from base
        if mode != .auto, let basePrimary = themePrimaryHex {
            let colors = ThemePresetHelper.generateThemeColors(
                basePrimaryHex: basePrimary,
                baseSecondaryHex: themeSecondaryHex,
                mode: mode
            )
            themePrimaryHex = colors.primaryHex
            themeSecondaryHex = colors.secondaryHex
        } else if mode == .auto {
            // When switching to auto, sync from cover media
            syncEventThemeFromCoverMedia()
        }
    }
    
    /// Gets the current effective theme colors (applying mode if needed)
    func currentThemeColors() -> ThemePresetHelper.ThemeColors {
        return ThemePresetHelper.currentThemeColors(
            themePrimaryHex: themePrimaryHex,
            themeSecondaryHex: themeSecondaryHex,
            themeMode: themeMode,
            fallbackPrimaryHex: nil,
            fallbackSecondaryHex: nil
        )
    }
    
    private func firstValidMediaColor() -> String? {
        for item in selectedMediaItems where item.mediaKind == .image {
            if let color = validColor(from: item) {
                return color
            }
        }
        return nil
    }
    
    private func validColor(from item: MediaItem) -> String? {
        guard let raw = item.averageColorHex else { return nil }
        if let parsed = ThemeColorParser.parse(raw) {
            switch parsed {
            case .solid(let hex):
                return ColorContrastHelper.isValidForDarkMode(hex: hex) ? hex : nil
            case .linearGradient(_, let stops):
                if let stop = stops.first(where: { ColorContrastHelper.isValidForDarkMode(hex: $0) }) {
                    return stop
                }
            }
            return nil
        }
        let sanitized = ThemeColorParser.sanitizedHex(raw)
        return ColorContrastHelper.isValidForDarkMode(hex: sanitized) ? sanitized : nil
    }
    
    // Uploads selected media items to cloud and creates Media records for events.
    private func uploadSelectedMedia(for eventID: UUID) async throws {
        for (index, item) in selectedMediaItems.enumerated() {
            do {
                // Upload to cloud first - get cloud URL and metadata
                let mediaDTO = try await mediaUploadService.uploadMedia(
                    item,
                    eventID: eventID,
                    position: Int16(index)
                )
                
                // Create Core Data Media record with cloud URL
                let createdMedia = try await mediaRepository.createMedia(
                    eventID: eventID,
                    url: mediaDTO.url, // Cloud URL from API
                    mimeType: mediaDTO.mimeType,
                    position: mediaDTO.position,
                    averageColorHex: mediaDTO.averageColorHex,
                    primaryColorHex: mediaDTO.primaryColorHex ?? item.primaryColorHex,
                    secondaryColorHex: mediaDTO.secondaryColorHex ?? item.secondaryColorHex
                )
                
                print("Media uploaded to cloud: \(createdMedia.id) at \(mediaDTO.url)")
            } catch {
                // Log error but don't fail entire upload - continue with other items
                print("Failed to upload media item \(index): \(error.localizedDescription)")
                // Optionally: could show user-friendly error message
                errorMessage = "Failed to upload some media items. Please try again."
            }
        }
        
        // Clear selected items after upload attempt
        selectedMediaItems.removeAll()
        
        // Refetch the event from Core Data to ensure media relationship is loaded
        do {
            if let refreshedEvent = try await repository.getEvent(by: eventID) {
                await MainActor.run {
                    userEvent = refreshedEvent
                    populateFromEvent(refreshedEvent)
                    
                    // Force materialization of media relationship
                    if let mediaSet = refreshedEvent.media {
                        print("Event refreshed: \(mediaSet.count) media items")
                        for media in mediaSet {
                            let _ = media.id
                            let _ = media.url
                        }
                    } else {
                        print("Event refreshed but media relationship is nil")
                    }
                }
            } else {
                print("Could not refetch event after media upload")
            }
        } catch {
            print("Error refetching event after media upload: \(error)")
        }
    }
    
    // MARK: - DATE/TIME HELPER METHODS:
    func calculateEndTimeFromDuration() {
        guard let start = startTime, let duration = durationMinutes else { return }
        endTime = Calendar.current.date(byAdding: .minute, value: Int(duration), to: start)
    }
    
    func calculateDurationFromEndTime() {
        guard let start = startTime, let end = endTime else { return }
        let duration = Calendar.current.dateComponents([.minute], from: start, to: end).minute ?? 0
        durationMinutes = Int64(duration)
    }
    
    func setStartTime(_ date: Date) {
        startTime = date

        // If we have duration but no end time, calculate end time.
        if durationMinutes != nil && endTime == nil {
            calculateEndTimeFromDuration()
        }

        // If we have end time but no duration, calculate duration.
        else if endTime != nil && durationMinutes == nil {
            calculateDurationFromEndTime()
        }
    }
    
    func setEndTime(_ date: Date) {
        endTime = date

        // If we have start time but no duration, calculate duration.
        if startTime != nil && durationMinutes == nil {
            calculateDurationFromEndTime()
        }
    }
    
    func setDuration(_ minutes: Int64) {
        durationMinutes = minutes

        // If we have start time but no end time, calculate end time.
        if startTime != nil && endTime == nil {
            calculateEndTimeFromDuration()
        }
    }
    
    // MARK: - COMPUTED PROPERTIES:
    var isUpcoming: Bool {
        guard scheduleStatus != .cancelled, scheduleStatus != .ended else { return false }
        guard let start = startTime else { return false }
        return Date() < start
    }
    
    var isLiveNow: Bool {
        guard scheduleStatus != .cancelled else { return false }
        guard let start = startTime else { return false }
        let now = Date()
        if let end = endTime {
            return now >= start && now <= end
        } else {
            return now >= start
        }
    }
    
    var isEnded: Bool {
        if scheduleStatus == .ended || scheduleStatus == .cancelled { return true }
        if let end = endTime { return Date() > end }
        return false
    }
    
    var currentCapacity: Int {
        return members.count
    }
    
    var isAtCapacity: Bool {
        return currentCapacity >= maxCapacity
    }
    
    var remainingCapacity: Int {
        return max(0, Int(maxCapacity) - currentCapacity)
    }
    
    var canAddMoreMembers: Bool {
        return !isAtCapacity && scheduleStatus != .ended && scheduleStatus != .cancelled
    }
    
    var isValid: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPlace = selectedPlace != nil
        let hasStartTime = startTime != nil
        
        // If startTime is provided, it should be in the future.
        let isStartTimeValid = startTime == nil || startTime! >= Date()

        return hasName && hasPlace && hasStartTime && isStartTimeValid
    }
    
    // MARK: - SUMMARY TEXT PROPERTIES (for UI display):
    var isNewEvent: Bool {
        id == nil
    }
    
    var hasEssentialFields: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && startTime != nil
    }
    
    var isDraftable: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isPublishable: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        startTime != nil &&
        selectedPlace != nil
    }
    
    var isReadyForGuests: Bool {
        // Only require name to be non-empty to navigate to guest selection
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasMedia: Bool {
        !selectedMediaItems.isEmpty || !media.isEmpty
    }

    // MARK: - PREVIEW TEXT:
    var timePreviewText: String? {
        guard let startTime else { return nil }
        return EventDateTimeFormatter.composerSummary(
            start: startTime,
            end: endTime,
            durationMinutes: durationMinutes,
            isAllDay: isAllDay
        )
    }
    
    var placePreviewText: String? {
        if let place = selectedPlace {
            // Safely accesses name property.
            // Handles case where object might not be fully faulted.
            if !place.isFault {
                return place.name
            } else {
                // If object is faulted, try to access name safely.
                return place.name.isEmpty ? nil : place.name
            }
        }
        return nil
    }
    
    var capacityPreviewText: String {
        if maxCapacity <= 0 {
            return "Unlimited"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: maxCapacity)) ?? "\(maxCapacity)"
        return "up to \(formatted)"
    }
    
    var visibilityPreviewText: String {
        visibility.title
    }
    
    var vibesPreviewText: String {
        if vibes.isEmpty { return "Vibes" }
        return "\(vibes.count) tags"

        // TODO: Display all selected vibes in WrapAroundLayout!
    }
    
    var themePreviewText: String {
        let colors = currentThemeColors()
        let mode = ThemePresetHelper.ThemeMode(rawValue: themeMode) ?? .auto
        return "\(colors.primaryHex.uppercased()) · \(mode.displayName)"
    }

    var detailsPreviewText: String? {
        if !details.isEmpty {
            // Get first 3 lines, preserving line breaks
            let lines = details.components(separatedBy: .newlines)
            let firstThreeLines = Array(lines.prefix(3))
            return firstThreeLines.joined(separator: "\n")
        }
        return nil
    }

    // MARK: - COMPOSER-SPECIFIC CONVERSIONS:
    /// Converts EventStatus to EventScheduleStatus for composer UI
    var composerScheduleStatus: EventScheduleStatus {
        EventScheduleStatus(domainValue: scheduleStatus)
    }
    
    /// Sets scheduleStatus from EventScheduleStatus
    func setComposerScheduleStatus(_ status: EventScheduleStatus) {
        scheduleStatus = status.domainValue
    }
    
    /// Converts Place to PlaceRepresentation for composer UI
    var locationRepresentation: PlaceRepresentation? {
        guard let place = selectedPlace else { return nil }
        // Convert Place to PlaceRepresentation if needed
        // For now, return nil if no place selected
        return nil
    }
    
    /// Sets location from Place object directly
    func setLocationRepresentation(_ place: Place?) {
        selectedPlace = place
    }
    
    // MARK: - Ticket Management
    
    var ticketsPreviewText: String? {
        if selectedTickets.isEmpty {
            return nil
        } else if selectedTickets.count == 1 {
            return "1 ticket"
        } else {
            return "\(selectedTickets.count) tickets"
        }

        // TODO: Display tickets by price in capsules ( FREE ) ( $5 ) ( $10 )
    }
    
    func addTicket(_ ticket: Ticket) {
        selectedTickets.insert(ticket)
    }
    
    func removeTicket(_ ticket: Ticket) {
        selectedTickets.remove(ticket)
    }
    
    func setTickets(_ tickets: Set<Ticket>) {
        selectedTickets = tickets
    }
    
    func clearTickets() {
        selectedTickets.removeAll()
    }
    
    // MARK: - PRIVATE METHODS:
    private func populateFromEvent(_ event: EventItem) {
        id = event.id
        name = event.name
        details = event.details ?? ""
        themePrimaryHex = event.themePrimaryHex
        themeSecondaryHex = event.themeSecondaryHex
        themeMode = event.themeMode ?? ThemePresetHelper.ThemeMode.auto.rawValue
        hasUserDefinedBrandColor = true
        startTime = event.startTime
        endTime = event.endTime
        durationMinutes = event.durationMinutes?.int64Value
        isAllDay = event.isAllDay
        maxCapacity = event.maxCapacity
        visibility = EventVisibility(rawValue: event.visibilityRaw) ?? .requiresApproval
        inviteLink = event.inviteLink
        scheduleStatus = EventStatus(rawValue: event.scheduleStatusRaw) ?? .upcoming
        selectedPlace = event.location
        
        // Populate selectedTickets from event's tickets relationship
        if let eventTickets = event.tickets {
            selectedTickets = eventTickets
        } else {
            selectedTickets = []
        }
        
        // Populate vibes from event's vibes relationship
        if let eventVibes = event.vibes {
            vibes = Set(eventVibes.map { $0.name })
        } else {
            vibes = []
        }
        
        // Populate selectedTags from event's vibes relationship
        if let eventVibes = event.vibes {
            selectedTags = Array(eventVibes)
        } else {
            selectedTags = []
        }
    }
    
    private func resetForm() {
        id = nil
        name = ""
        details = ""
        themePrimaryHex = nil
        themeSecondaryHex = nil
        themeMode = ThemePresetHelper.ThemeMode.auto.rawValue
        hasUserDefinedBrandColor = false
        startTime = nil
        endTime = nil
        durationMinutes = nil
        isAllDay = false
        maxCapacity = 50
        visibility = .requiresApproval
        inviteLink = nil
        scheduleStatus = .upcoming
        selectedPlace = nil
        selectedTickets = []
        tags = []
        selectedTags = []
        vibes = []
        members = []
        media = []
        previewPhotos = []
        invitedUsers = []
        selectedTicket = nil
        selectedMediaItems = []
    }
    
    // MARK: - SCHEDULING METHODS:
    func setStartTime(_ date: Date?) {
        startTime = date
        // Auto-calculate end time if duration is set.
        if let start = date, let duration = durationMinutes {
            endTime = start.addingTimeInterval(TimeInterval(duration * 60))
        }
    }
    
    func setEndTime(_ date: Date?) {
        endTime = date
        // Auto-calculate duration if start time is set.
        if let start = startTime, let end = date {
            durationMinutes = Int64(end.timeIntervalSince(start) / 60)
        }
    }
    
    func setDuration(_ minutes: Int64?) {
        durationMinutes = minutes
        // Auto-calculate end time if start time is set.
        if let start = startTime, let duration = minutes {
            endTime = start.addingTimeInterval(TimeInterval(duration * 60))
        }
    }
}
