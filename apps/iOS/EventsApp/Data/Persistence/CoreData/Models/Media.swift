//
//  Media.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation
import CoreData

@objc(Media)
public class Media: NSManagedObject {}

extension Media {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Media> {
        NSFetchRequest<Media>(entityName: "Media")
    }

    @NSManaged public var id: UUID
    @NSManaged public var url: String  // Remote URL (https://...)
    @NSManaged public var position: Int16  // Ordering in a list/grid.
    
    // UX fields.
    @NSManaged public var mimeType: String?  // Example: image/jpeg.
    @NSManaged public var averageColorHex: String?  // Legacy field, kept for backward compatibility
    @NSManaged public var primaryColorHex: String?  // Dominant primary color extracted from image
    @NSManaged public var secondaryColorHex: String?  // Dominant secondary color extracted from image
    
    // Polymorphic relationships (exactly ONE must be set).
    @NSManaged public var event: EventItem?
    @NSManaged public var userProfile: UserProfile?
    @NSManaged public var publicProfile: PublicProfile?
}

extension Media {
    var inferredKind: MediaKind {
        let m = mimeType?.lowercased() ?? ""
        if m.hasPrefix("image/") { return .image }
        if m.hasPrefix("video/") { return .video }
        if m.hasPrefix("audio/") { return .audio }
        return .other
    }
    
    // Convenience type checkers for cleaner code.
    var isImage: Bool { inferredKind == .image }
    // Note: isVideo and isAudio kept for Core Data compatibility but not used in business logic
    var isVideo: Bool { inferredKind == .video }
    var isAudio: Bool { inferredKind == .audio }
    
    // Validates that exactly one relationship is set.
    func validateRelationships() throws {
        let relationshipCount = [event != nil, userProfile != nil, publicProfile != nil]
            .filter { $0 }
            .count
        
        guard relationshipCount == 1 else {
            throw MediaError.invalidRelationshipCount(actual: relationshipCount)
        }
    }
    
    // Returns the owner type of this media.
    var ownerType: MediaOwnerType? {
        if event != nil { return .event }
        if userProfile != nil { return .userProfile }
        if publicProfile != nil { return .publicProfile }
        return nil
    }
    
    // Returns the owner ID of this media.
    var ownerID: UUID? {
        if let event = event { return event.id }
        if let userProfile = userProfile { return userProfile.id }
        if let publicProfile = publicProfile { return publicProfile.id }
        return nil
    }
    
    // Gets the remote URL for this media item.
    // All media is stored in cloud - Kingfisher handles local caching automatically.
    var remoteURL: URL? {
        guard !url.isEmpty else { return nil }
        
        // Return URL if it's a valid remote URL (http/https)
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return URL(string: url)
        }
        
        // Legacy file:// URLs or invalid URLs return nil
        return nil
    }
}

public enum MediaOwnerType {
    case event
    case userProfile
    case publicProfile
}

public enum MediaError: LocalizedError {
    case invalidRelationshipCount(actual: Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidRelationshipCount(let actual):
            return "Media must have exactly one owner relationship set.  But found \(actual)"
        }
    }
}

// Local & Cloud Storage:
extension Media: SyncTrackable {
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var schemaVersion: Int16
    
    // Computed:
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
