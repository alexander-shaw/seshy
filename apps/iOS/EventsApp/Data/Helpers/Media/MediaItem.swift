//
//  MediaItem.swift
//  EventsApp
//
//  Created by Шоу on 10/29/25.
//

import Foundation
import UIKit

// Temporary model for selected media before upload.
public struct MediaItem: Identifiable, Equatable {
    public let id: UUID
    public var imageData: Data?
    public var mimeType: String?
    public var position: Int16
    public var averageColorHex: String?  // Legacy field
    public var primaryColorHex: String?
    public var secondaryColorHex: String?
    
    public init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        mimeType: String? = nil,
        position: Int16 = 0,
        averageColorHex: String? = nil,
        primaryColorHex: String? = nil,
        secondaryColorHex: String? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.mimeType = mimeType
        self.position = position
        self.averageColorHex = averageColorHex
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
    }
    
    public var isImage: Bool {
        guard let mime = mimeType?.lowercased() else { return imageData != nil }
        return mime.hasPrefix("image/") || imageData != nil
    }
    
    public var mediaKind: MediaKind {
        if isImage { return .image }
        return .other
    }
    
    public func uiImage() -> UIImage? {
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    public func hasValidAverageColor(minContrastRatio: Double = 3.0) -> Bool {
        guard let averageColorHex else { return false }
        return ColorContrastHelper.isValidForDarkMode(hex: averageColorHex, minimumRatio: minContrastRatio)
    }
}

#if canImport(SwiftUI)
import SwiftUI

public extension MediaItem {
    static var placeholderGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.11, green: 0.11, blue: 0.13), Color(red: 0.25, green: 0.12, blue: 0.34)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
#endif
