//
//  MediaUploadService.swift
//  EventsApp
//
//  Created by Auto on 12/6/24.
//

import Foundation

/// Helper function to add timeout to async operations
private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T?) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        // Add the actual operation task
        group.addTask {
            await operation()
        }
        
        // Add the timeout task
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return nil as T? // Signal timeout
        }
        
        // Get the first completed result (either operation or timeout)
        let result = await group.next()
        // Cancel remaining tasks
        group.cancelAll()
        // Return the result (nil if timeout occurred first)
        return result ?? nil
    }
}

/// Service for uploading media to cloud storage via API
public final class MediaUploadService {
    private let apiClient: APIClient
    
    public init(apiClient: APIClient = HTTPAPIClient()) {
        self.apiClient = apiClient
    }
    
    /// Uploads a media item to cloud storage
    /// - Parameters:
    ///   - mediaItem: The media item to upload (must have imageData)
    ///   - eventID: Optional event ID if media belongs to an event
    ///   - userProfileID: Optional user profile ID if media belongs to a user profile
    ///   - publicProfileID: Optional public profile ID if media belongs to a public profile
    ///   - position: Position/order of the media item
    /// - Returns: MediaDTO with cloud URL and metadata
    /// - Throws: MediaUploadError or APIError if upload fails
    public func uploadMedia(
        _ mediaItem: MediaItem,
        eventID: UUID? = nil,
        userProfileID: UUID? = nil,
        publicProfileID: UUID? = nil,
        position: Int16
    ) async throws -> MediaDTO {
        // Validate media item has data
        guard let imageData = mediaItem.imageData else {
            throw MediaUploadError.noImageData
        }
        
        // Extract colors if not already extracted (non-blocking, with timeout)
        // Colors should already be extracted in MediaSelectionHelper, but if missing, extract here
        var primaryColorHex = mediaItem.primaryColorHex
        var secondaryColorHex = mediaItem.secondaryColorHex
        
        if primaryColorHex == nil || secondaryColorHex == nil {
            // Extract colors from image data off main thread with timeout
            // Don't block upload if extraction fails or times out
            let colorResult = await withTimeout(seconds: 3) {
                await Task.detached(priority: .utility) {
                    DominantColorExtractor.extractColors(from: imageData)
                }.value
            }
            
            if let colorResult = colorResult {
                primaryColorHex = colorResult.primaryColorHex
                secondaryColorHex = colorResult.secondaryColorHex
            }
            // If extraction fails or times out, continue without colors (upload won't be blocked)
        }
        
        // Determine file name and mime type
        let mimeType = mediaItem.mimeType ?? "image/jpeg"
        let fileExtension = fileExtension(for: mimeType)
        let fileName = "\(UUID().uuidString)\(fileExtension)"
        
        // Upload to API
        let result: APIResult<MediaDTO> = try await apiClient.uploadMedia(
            "/media",
            fileData: imageData,
            fileName: fileName,
            mimeType: mimeType,
            eventID: eventID,
            userProfileID: userProfileID,
            publicProfileID: publicProfileID,
            position: position,
            headers: [:]
        )
        
        switch result.status {
        case .ok(let mediaDTO, _):
            // If server didn't return colors, use the ones we extracted
            let finalPrimaryHex = mediaDTO.primaryColorHex ?? primaryColorHex
            let finalSecondaryHex = mediaDTO.secondaryColorHex ?? secondaryColorHex
            
            // Create a new DTO with the correct colors
            return MediaDTO(
                id: mediaDTO.id,
                url: mediaDTO.url,
                position: mediaDTO.position,
                mimeType: mediaDTO.mimeType,
                averageColorHex: mediaDTO.averageColorHex,
                primaryColorHex: finalPrimaryHex,
                secondaryColorHex: finalSecondaryHex,
                eventID: mediaDTO.eventID,
                userProfileID: mediaDTO.userProfileID,
                publicProfileID: mediaDTO.publicProfileID,
                createdAt: mediaDTO.createdAt,
                updatedAt: mediaDTO.updatedAt,
                deletedAt: mediaDTO.deletedAt,
                syncStatusRaw: mediaDTO.syncStatusRaw,
                lastCloudSyncedAt: mediaDTO.lastCloudSyncedAt,
                schemaVersion: mediaDTO.schemaVersion
            )
        case .notModified:
            throw MediaUploadError.unexpectedResponse
        }
    }
    
    private func fileExtension(for mimeType: String) -> String {
        switch mimeType.lowercased() {
        case "image/jpeg", "image/jpg":
            return ".jpg"
        case "image/png":
            return ".png"
        case "image/gif":
            return ".gif"
        case "image/webp":
            return ".webp"
        default:
            return ".jpg" // Default fallback
        }
    }
}

public enum MediaUploadError: LocalizedError {
    case noImageData
    case unexpectedResponse
    case uploadFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .noImageData:
            return "Media item has no image data to upload"
        case .unexpectedResponse:
            return "Unexpected response from server"
        case .uploadFailed(let error):
            return "Failed to upload media: \(error.localizedDescription)"
        }
    }
}

