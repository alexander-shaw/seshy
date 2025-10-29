//
//  RemoteMedia.swift
//  EventsApp
//
//  Created by Шоу on 10/12/25.
//

import SwiftUI
import Kingfisher

struct RemoteMediaImage: View {
    let urlString: String
    let targetSize: CGSize  // The actual size the image will render at.

    var body: some View {
        KFImage(URL(string: urlString))
            .setProcessor(ImagePipeline.downsampler(for: targetSize))
            .cacheOriginalImage(false)  // Store only downsampled version.
            .targetCache(ImagePipeline.cache)
            .fade(duration: 0.25)  // 0.15
            .resizable()
            .scaledToFill()
            .clipped()
            .redacted(reason: .placeholder)  // Optional skeleton while loading.
    }
}

/*
 MARK: TO USE:
 RemoteMediaImage(urlString: media.url, targetSize: CGSize(width: 160, height: 160))
     .frame(width: 160, height: 160)
     .cornerRadius(12)
 */
