//
//  MediaItem.swift
//  EventsApp
//
//  Created by Шоу on 10/29/25.
//

import Foundation
import UIKit
import AVFoundation
import CoreDomain

// Temporary model for selected media before upload.
public struct MediaItem: Identifiable, Equatable {
    public let id: UUID
    public var imageData: Data?
    public var videoData: Data?
    public var thumbnailData: Data?
    public var mimeType: String?
    public var position: Int16
    
    public init(id: UUID = UUID(), imageData: Data? = nil, videoData: Data? = nil, thumbnailData: Data? = nil, mimeType: String? = nil, position: Int16 = 0) {
        self.id = id
        self.imageData = imageData
        self.videoData = videoData
        self.thumbnailData = thumbnailData
        self.mimeType = mimeType
        self.position = position
    }
    
    public var isImage: Bool {
        guard let mime = mimeType?.lowercased() else { return imageData != nil }
        return mime.hasPrefix("image/") || imageData != nil
    }
    
    public var isVideo: Bool {
        guard let mime = mimeType?.lowercased() else { return videoData != nil }
        return mime.hasPrefix("video/") || videoData != nil
    }
    
    public var mediaKind: MediaKind {
        if isVideo { return .video }
        if isImage { return .image }
        return .other
    }
    
    public func uiImage() -> UIImage? {
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        if let thumbnailData = thumbnailData {
            return UIImage(data: thumbnailData)
        }
        return nil
    }
}
