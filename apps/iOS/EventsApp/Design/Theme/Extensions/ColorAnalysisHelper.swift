//
//  ColorAnalysisHelper.swift
//  EventsApp
//
//  Created by Шоу on 11/27/25.
//

import CoreImage
import SwiftUI
import UIKit

enum ColorAnalysisHelper {
    /// Shared CIContext to avoid rebuilding per call.
    private static let ciContext = CIContext(options: [.workingColorSpace: NSNull()])
    
    /// Computes the average color hex from a `UIImage`.
    static func averageColorHex(from image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        return averageColorHex(from: cgImage)
    }
    
    /// Computes the average color hex from raw image `Data`.
    static func averageColorHex(from data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        return averageColorHex(from: image)
    }
    
    /// Computes the average color hex from a `CGImage`.
    static func averageColorHex(from cgImage: CGImage) -> String? {
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        var pixelData = [UInt8](repeating: 0, count: 4)
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        ciContext.render(
            outputImage,
            toBitmap: &pixelData,
            rowBytes: 4,
            bounds: rect,
            format: .RGBA8,
            colorSpace: nil
        )
        
        let r = pixelData[0]
        let g = pixelData[1]
        let b = pixelData[2]
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}


















