//
//  MediaKind.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation

public enum MediaKind {
    case image
    case video
    case audio
    case document
    case other

    public var displayName: String {
        switch self {
            case .image: return "Image"
            case .video: return "Video"
            case .audio: return "Audio"
            case .document: return "Document"
            case .other: return "Other"
        }
    }
}
