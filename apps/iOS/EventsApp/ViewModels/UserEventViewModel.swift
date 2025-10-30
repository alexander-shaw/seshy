//
//  UserEventViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// Manages user event creation, editing, and display.
// Provides a reactive interface for SwiftUI views to work with events including:
// - Event CRUD operations (create, read, update, delete);
// - Event scheduling and status management;
// - Location and tag association; and
// - Member and media management.

import Foundation
import Combine
import CoreData
import SwiftUI
import CoreDomain

@MainActor
final class UserEventViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var details: String = ""
    @Published var brandColor: String = "#007AFF"  // TODO: Improve this implementation.
    @Published var startTime: Date?
    @Published var endTime: Date?
    @Published var durationMinutes: Int64?
    @Published var isAllDay: Bool = false
    @Published var maxCapacity: Int64 = 50
    @Published var visibility: UserEventVisibility = .requiresApproval
    @Published var inviteLink: String?
    @Published var scheduleStatus: UserEventStatus = .upcoming
    
    @Published var location: Place
    @Published var tags: [Tag] = []
    @Published var selectedTags: [Tag] = []
    @Published var members: [Member] = []
    @Published var media: [Media] = []
    @Published var previewPhotos: [Media] = []
    @Published var invitedUsers: [UserProfile] = []
    @Published var selectedTicket: String?
    
    // Temporary media items selected but not yet uploaded
    @Published var selectedMediaItems: [MediaItem] = []
    
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private let context: NSManagedObjectContext
    private let repository: UserEventRepository
    private let mediaRepository: MediaRepository
    private var userEvent: UserEvent?
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: UserEventRepository = CoreDataUserEventRepository(), mediaRepository: MediaRepository = CoreDataMediaRepository()) {
        self.context = context
        self.repository = repository
        self.mediaRepository = mediaRepository

        // Initialize with a default place, which will need to be set before creating an event.
        self.location = Place(context: context)
        
        // Set UUID first to avoid bridging issues.
        let newUUID = UUID()
        self.location.setValue(newUUID, forKey: "id")
        
        self.location.name = "Temporary"
        self.location.latitude = 0.0
        self.location.longitude = 0.0
        self.location.radius = 10.0
        self.location.maxCapacity = NSNumber(value: 100)
        self.location.createdAt = Date()
        self.location.updatedAt = Date()
        self.location.syncStatus = .pending
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
            errorMessage = "Failed to load event: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createEvent() async {
        isSaving = true
        errorMessage = nil
        
        do {
            let event = try await repository.createEvent(
                name: name,
                details: details.isEmpty ? nil : details,
                brandColor: brandColor,
                startTime: startTime,
                endTime: endTime,
                durationMinutes: durationMinutes,
                isAllDay: isAllDay,
                location: location,
                maxCapacity: maxCapacity,
                visibility: visibility,
                inviteLink: inviteLink,
                status: .draft
            )
            
            userEvent = event
            populateFromEvent(event)
        } catch {
            errorMessage = "Failed to create event: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func saveEvent() async {
        isSaving = true
        errorMessage = nil
        
        do {
            let event = try await repository.createEvent(
                name: name,
                details: details.isEmpty ? nil : details,
                brandColor: brandColor,
                startTime: startTime,
                endTime: endTime,
                durationMinutes: durationMinutes,
                isAllDay: isAllDay,
                location: location,
                maxCapacity: maxCapacity,
                visibility: visibility,
                inviteLink: inviteLink,
                status: .draft
            )
            
            userEvent = event
            populateFromEvent(event)
            
            // Upload selected media
            if !selectedMediaItems.isEmpty {
                try await uploadSelectedMedia(for: event.id)
            }
        } catch {
            errorMessage = "Failed to save event: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func publishEvent() async {
        isSaving = true
        errorMessage = nil
        
        /*
         // FUTURE: Full publish flow with invite selection.
         // This will open a modal sheet where user can:
         // 1. Select contacts/users to invite
         // 2. Set custom max capacity (different from default)
         // 3. Choose visibility level (directInvites, requiresApproval, openToAll)
         // 4. Then publish locally and sync to cloud
         */
        
        do {
            let event = try await repository.createEvent(
                name: name,
                details: details.isEmpty ? nil : details,
                brandColor: brandColor,
                startTime: startTime,
                endTime: endTime,
                durationMinutes: durationMinutes,
                isAllDay: isAllDay,
                location: location,
                maxCapacity: maxCapacity,
                visibility: visibility,
                inviteLink: inviteLink,
                status: .upcoming
            )
            
            userEvent = event
            populateFromEvent(event)
            
            // Upload selected media
            if !selectedMediaItems.isEmpty {
                try await uploadSelectedMedia(for: event.id)
                
                // Refresh the event to pick up media relationships
                if let refreshedEvent = try await repository.getEvent(by: event.id) {
                    userEvent = refreshedEvent
                    populateFromEvent(refreshedEvent)
                }
            }
            
            // FUTURE: Sync to cloud after publishing locally.
        } catch {
            errorMessage = "Failed to publish event: \(error.localizedDescription)"
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
            event.brandColor = brandColor
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
            event.location = location
            
            if let result = try await repository.updateEvent(event) {
                userEvent = result
                populateFromEvent(result)
            }
        } catch {
            errorMessage = "Failed to update event: \(error.localizedDescription)"
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
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func updateStatus(_ status: UserEventStatus) async {
        guard let event = userEvent else { return }
        
        do {
            if let result = try await repository.updateEventStatus(event.id, status: status) {
                userEvent = result
                scheduleStatus = status
                populateFromEvent(result)
            }
        } catch {
            errorMessage = "Failed to update event status: \(error.localizedDescription)"
        }
    }
    
    func addTag(_ tag: Tag) {
        if !tags.contains(where: { $0.id == tag.id }) {
            tags.append(tag)
        }
    }
    
    func removeTag(_ tag: Tag) {
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
    
    /// Uploads selected media items and creates Media records for events
    private func uploadSelectedMedia(for eventID: UUID) async throws {
        for (index, item) in selectedMediaItems.enumerated() {
            // Verify we have data to save before creating the record
            guard item.imageData != nil || item.videoData != nil else {
                continue // Skip items without data
            }
            
            // Create Media record first to get the UUID
            let placeholderURL = "placeholder://\(UUID().uuidString)"
            let createdMedia = try await mediaRepository.createMedia(
                eventID: eventID,
                url: placeholderURL,
                mimeType: item.mimeType,
                position: Int16(index)
            )
            
            // Extract the media ID - this is now safe as the object is from view context
            let mediaID = createdMedia.id
            
            // Verify we still have data (defensive check)
            guard item.imageData != nil || item.videoData != nil else {
                // If no data, delete the created media record
                try? await mediaRepository.deleteMedia(mediaID)
                continue
            }
            
            // Save media data to persistent storage using the created media ID
            let fileURL: URL
            do {
                if let imageData = item.imageData {
                    fileURL = try MediaStorageHelper.saveMediaData(imageData, mediaID: mediaID, isVideo: false)
                    print("💾 [UserEventViewModel] Saved image to: \(fileURL.path)")
                    print("💾 [UserEventViewModel] File URL absoluteString: \(fileURL.absoluteString)")
                } else if let videoData = item.videoData {
                    fileURL = try MediaStorageHelper.saveMediaData(videoData, mediaID: mediaID, isVideo: true)
                    print("💾 [UserEventViewModel] Saved video to: \(fileURL.path)")
                    print("💾 [UserEventViewModel] File URL absoluteString: \(fileURL.absoluteString)")
                } else {
                    // This shouldn't happen due to guard above, but handle it anyway
                    try? await mediaRepository.deleteMedia(mediaID)
                    continue
                }
                
                // Verify file was actually saved
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    print("✅ [UserEventViewModel] File verified to exist at: \(fileURL.path)")
                } else {
                    print("❌ [UserEventViewModel] File NOT found after save at: \(fileURL.path)")
                }
            } catch {
                // If saving fails, clean up the media record
                print("❌ [UserEventViewModel] Failed to save media file: \(error)")
                try? await mediaRepository.deleteMedia(mediaID)
                throw error
            }
            
            // Update the media record with the actual file URL (always use file:// format for consistency)
            print("🔄 [UserEventViewModel] Updating media URL to: \(fileURL.absoluteString)")
            try await mediaRepository.updateMediaURL(mediaID, url: fileURL.absoluteString)
            
            // Verify the update
            if let updatedMedia = try? await mediaRepository.getMedia(eventID: eventID, limit: nil).first(where: { $0.id == mediaID }) {
                print("✅ [UserEventViewModel] Media URL updated successfully: '\(updatedMedia.url)'")
                
                // Verify file exists at the stored URL
                let resolver = MediaURLResolver.resolveURL(for: updatedMedia)
                switch resolver {
                case .local:
                    print("✅ [UserEventViewModel] Media file confirmed to exist (local)")
                case .remote:
                    print("⚠️ [UserEventViewModel] Media resolved as remote (unexpected for local file)")
                case .missing:
                    print("❌ [UserEventViewModel] Media file NOT FOUND after update!")
                }
            }
        }
        
        // Clear selected items after upload
        selectedMediaItems.removeAll()
        
        // CRITICAL: Refetch the event from Core Data to ensure media relationship is loaded
        // The background context saves have now merged into the view context
        // This ensures the event object has the media relationship fully loaded
        do {
            if let refreshedEvent = try await repository.getEvent(by: eventID) {
                await MainActor.run {
                    userEvent = refreshedEvent
                    populateFromEvent(refreshedEvent)
                    
                    // Force materialization of media relationship
                    if let mediaSet = refreshedEvent.media {
                        print("✅ [UserEventViewModel] Event refreshed: \(mediaSet.count) media items")
                        for media in mediaSet {
                            let _ = media.id
                            let _ = media.url
                        }
                    } else {
                        print("⚠️ [UserEventViewModel] Event refreshed but media relationship is nil")
                    }
                }
            } else {
                print("❌ [UserEventViewModel] Could not refetch event after media upload")
            }
        } catch {
            print("❌ [UserEventViewModel] Error refetching event after media upload: \(error)")
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
        
        // Location validation: must have a proper location.
        let hasValidLocation = location.name != "Temporary Place" && location.latitude != 0.0 && location.longitude != 0.0
        
        // For now, only require name and location. We'll add date/time validation later.
        // Date/time validation: at least 2 of 3 fields must be provided.
        let hasStartTime = startTime != nil
        let hasEndTime = endTime != nil
        let hasDuration = durationMinutes != nil && durationMinutes! > 0
        
        let dateTimeFieldsProvided = [hasStartTime, hasEndTime, hasDuration].filter { $0 }.count
        let hasValidDateTime = dateTimeFieldsProvided >= 2
        
        // If startTime is provided, it should be in the future.
        let isStartTimeValid = startTime == nil || startTime! >= Date()

        // Temporarily relax validation for testing - only require name and location
        return hasName && hasValidLocation // && hasValidDateTime && isStartTimeValid
    }
    
    // MARK: - PRIVATE METHODS:
    
    private func populateFromEvent(_ event: UserEvent) {
        name = event.name
        details = event.details ?? ""
        brandColor = event.brandColor
        startTime = event.startTime
        endTime = event.endTime
        durationMinutes = event.durationMinutes?.int64Value
        isAllDay = event.isAllDay
        maxCapacity = event.maxCapacity
        visibility = UserEventVisibility(rawValue: event.visibilityRaw) ?? .requiresApproval
        inviteLink = event.inviteLink
        scheduleStatus = UserEventStatus(rawValue: event.scheduleStatusRaw) ?? .upcoming
        location = event.location ?? {
            // Create a temporary place if event has no location.
            let tempPlace = Place(context: context)
            
            // Set UUID first to avoid bridging issues.
            let newUUID = UUID()
            tempPlace.setValue(newUUID, forKey: "id")
            
            tempPlace.name = "Temporary Place"
            tempPlace.latitude = 0.0
            tempPlace.longitude = 0.0
            tempPlace.radius = 10.0
            tempPlace.maxCapacity = NSNumber(value: 100)
            tempPlace.createdAt = Date()
            tempPlace.updatedAt = Date()
            tempPlace.syncStatus = .pending
            return tempPlace
        }()

        // TODO: tags, members, media, previewPhotos would need to be loaded separately.
        // They are relationships that are not included in the DTO.
    }
    
    private func resetForm() {
        name = ""
        details = ""
        brandColor = "#007AFF"
        startTime = nil
        endTime = nil
        durationMinutes = nil
        isAllDay = false
        maxCapacity = 50
        visibility = .requiresApproval
        inviteLink = nil
        scheduleStatus = .upcoming
        // Reset location to default temporary place.
        location = Place(context: context)
        
        // Set UUID first to avoid bridging issues.
        let newUUID = UUID()
        location.setValue(newUUID, forKey: "id")
        
        location.name = "Temporary Place"
        location.latitude = 0.0
        location.longitude = 0.0
        location.radius = 10.0
        location.maxCapacity = NSNumber(value: 100)
        location.createdAt = Date()
        location.updatedAt = Date()
        location.syncStatus = .pending
        tags = []
        selectedTags = []
        members = []
        media = []
        previewPhotos = []
        invitedUsers = []
        selectedTicket = nil
        selectedMediaItems = []
    }
    
    // MARK: - SCHEDULING METHODS
    
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
