//
//  Media.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation
import CoreData
import CoreDomain

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
    @NSManaged public var averageColorHex: String?
    
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
    
    // Gets the actual file URL where media is stored locally.
    // Tries multiple strategies: stored URL and then expected path by ID.
    var actualFileURL: URL? {
        // First try the stored URL.
        if !url.isEmpty {
            // Try parsing as URL.
            if let storedURL = URL(string: url) {
                // If it's a file URL that exists:
                if storedURL.isFileURL && FileManager.default.fileExists(atPath: storedURL.path) {
                    return storedURL
                }
            }
            
            // Try as direct file path.
            if url.hasPrefix("file://") {
                let path = String(url.dropFirst(7))
                let fileURL = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    return fileURL
                }
            } else if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
                // Treat as file path.
                let fileURL = URL(fileURLWithPath: url)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    return fileURL
                }
            }
        }
        
        // Fallback: construct expected path by media ID.
        let expectedURL = MediaStorageHelper.getMediaFileURL(mediaID: id, isVideo: isVideo)
        if FileManager.default.fileExists(atPath: expectedURL.path) {
            return expectedURL
        }
        
        return nil
    }
    
    // Gets the media data from the file system.
    // Returns nil if file does not exist or cannot be loaded.
    var mediaData: Data? {
        guard let fileURL = actualFileURL else { return nil }
        return try? Data(contentsOf: fileURL)
    }
    
    // Determines if this media is available locally.
    var isAvailableLocally: Bool {
        return actualFileURL != nil
    }
    
    // Gets the remote URL if this is a remote media item.
    var remoteURL: URL? {
        // Only return remote URL if it is not a local file and not empty.
        guard !url.isEmpty else { return nil }
        
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return URL(string: url)
        }
        
        // If it is not a local file and not a remote URL, it is invalid.
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
