//
//  MediaLike.swift
//  EventsApp
//
//  Created by Шоу on 10/9/25.
//

// MARK: Protocol.

import Foundation

// UI-facing, source-agnostic interface for any media row (owned or cached).
public protocol MediaLike {
    var urlString: String { get }
    var mimeType: String? { get }
    var position: Int16 { get }
    var averageColorHex: String? { get }

    var widthValue: Int? { get }
    var heightValue: Int? { get }
    var durationMillisecondsValue: Int? { get }
}

public extension MediaLike {
    var isVideo: Bool { mimeType?.starts(with: "video/") == true }
    var isImage: Bool { mimeType?.starts(with: "image/") == true }
}
