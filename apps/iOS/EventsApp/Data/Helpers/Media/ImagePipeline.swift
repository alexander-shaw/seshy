//
//  ImagePipeline.swift
//  EventsApp
//
//  Created by Шоу on 10/12/25.
//

// Lightweight Kingfisher pipeline: ~24MB in-memory (2-min TTL) and 300MB on-disk (14-day TTL).
// Downsamples to view size to cut decode cost and keep scrolling smooth.
// Automatically evicts old/unused images to balance performance and footprint.

import Kingfisher
import UIKit

enum ImagePipeline {
    static let cache: ImageCache = {
        let c = ImageCache(name: "app-media")

        // Kingfisher evicts older entries when the sum of decoded image costs goes above this amount.
        c.memoryStorage.config.totalCostLimit = 24 * 1024 * 1024  // 24 MB.

        // An image becomes eligible for removal at the next cleanup if not accessed in this amount of time.
        c.memoryStorage.config.expiration = .seconds(120)  // 2 minutes.

        // Older files are deleted to get back under this limit when the cache exceeds this size.
        c.diskStorage.config.sizeLimit = 300 * 1024 * 1024  // 300 MB.

        // Files are purged during cleanup if older than this amount of time.
        c.diskStorage.config.expiration = .days(14)  // 14 days.

        return c
    }()

    static func downsampler(for target: CGSize, scale: CGFloat = UIScreen.main.scale) -> DownsamplingImageProcessor {
        DownsamplingImageProcessor(size: CGSize(width: target.width * scale, height: target.height * scale))
    }
}
