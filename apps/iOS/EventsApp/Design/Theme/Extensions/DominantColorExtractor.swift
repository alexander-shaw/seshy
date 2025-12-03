//
//  DominantColorExtractor.swift
//  EventsApp
//
//  Created by Auto on 1/25/25.
//

import CoreImage
import UIKit

/// Extracts dominant primary and secondary colors from images using a fast, simplified approach.
/// Uses aggressive downsampling and simple k-means clustering for speed.
public enum DominantColorExtractor {
    /// Target size for downsampling (very small for speed)
    private static let targetSize: CGFloat = 50
    
    /// Result containing primary and secondary color hex strings
    public struct ColorResult {
        public let primaryColorHex: String
        public let secondaryColorHex: String
        
        public init(primaryColorHex: String, secondaryColorHex: String) {
            self.primaryColorHex = primaryColorHex
            self.secondaryColorHex = secondaryColorHex
        }
    }
    
    /// Extracts dominant colors from a UIImage
    /// - Parameter image: The image to analyze
    /// - Returns: ColorResult with primary and secondary hex colors, or nil if extraction fails
    public static func extractColors(from image: UIImage) -> ColorResult? {
        guard let cgImage = image.cgImage else { return nil }
        return extractColors(from: cgImage)
    }
    
    /// Extracts dominant colors from raw image data
    /// - Parameter data: The image data
    /// - Returns: ColorResult with primary and secondary hex colors, or nil if extraction fails
    public static func extractColors(from data: Data) -> ColorResult? {
        guard let image = UIImage(data: data) else { return nil }
        return extractColors(from: image)
    }
    
    /// Extracts dominant colors from a CGImage using fast k-means clustering
    /// - Parameter cgImage: The CGImage to analyze
    /// - Returns: ColorResult with primary and secondary hex colors, or nil if extraction fails
    public static func extractColors(from cgImage: CGImage) -> ColorResult? {
        // Step 1: Aggressively downsample to 50x50 for speed
        guard let downsampled = downsampleToSize(cgImage, targetSize: targetSize) else { return nil }
        
        // Step 2: Extract pixel data from downsampled image
        guard let pixelData = extractPixelData(from: downsampled) else { return nil }
        
        // Step 3: Simple k-means clustering to find top 3-5 colors
        let clusters = simpleKMeans(pixelData: pixelData, k: 5)
        
        // Step 4: Pick the two most prominent colors
        guard clusters.count >= 2 else {
            if let singleColor = clusters.first {
                return ColorResult(primaryColorHex: singleColor.hex, secondaryColorHex: singleColor.hex)
            }
            return nil
        }
        
        // Sort by count (most common first)
        let sorted = clusters.sorted { $0.count > $1.count }
        let primary = sorted[0]
        let secondary = sorted[1]
        
        return ColorResult(primaryColorHex: primary.hex, secondaryColorHex: secondary.hex)
    }
    
    // MARK: - Private Helpers
    
    /// Aggressively downsamples the image to target size (e.g., 50x50) for maximum speed
    private static func downsampleToSize(_ cgImage: CGImage, targetSize: CGFloat) -> CGImage? {
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let maxDim = max(width, height)
        
        // Calculate scale to fit within target size
        let scale = targetSize / maxDim
        let newWidth = max(1, Int(width * scale))
        let newHeight = max(1, Int(height * scale))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        // Use low quality for speed
        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        return context.makeImage()
    }
    
    /// Extracts pixel data from a CGImage
    private static func extractPixelData(from cgImage: CGImage) -> [UInt8]? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: &pixelData,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelData
    }
    
    /// Simple color cluster for k-means
    private struct ColorCluster {
        var r: Double
        var g: Double
        var b: Double
        var count: Int
        
        var hex: String {
            String(format: "#%02X%02X%02X", UInt8(r), UInt8(g), UInt8(b))
        }
        
        func distance(to other: ColorCluster) -> Double {
            let dr = r - other.r
            let dg = g - other.g
            let db = b - other.b
            return sqrt(dr * dr + dg * dg + db * db)
        }
    }
    
    /// Simple k-means clustering to find dominant colors
    /// - Parameters:
    ///   - pixelData: Raw pixel data (RGBA format)
    ///   - k: Number of clusters (typically 3-5)
    /// - Returns: Array of color clusters sorted by frequency
    private static func simpleKMeans(pixelData: [UInt8], k: Int) -> [ColorCluster] {
        guard pixelData.count >= 12 else { return [] } // Need at least 3 pixels
        
        // Step 1: Sample pixels (every 4th pixel for speed)
        var samples: [(r: Double, g: Double, b: Double)] = []
        for i in stride(from: 0, to: pixelData.count - 2, by: 16) { // Sample every 4th pixel
            samples.append((
                r: Double(pixelData[i]),
                g: Double(pixelData[i + 1]),
                b: Double(pixelData[i + 2])
            ))
        }
        
        guard samples.count >= k else { return [] }
        
        // Step 2: Initialize k centroids randomly
        var centroids: [ColorCluster] = []
        let step = samples.count / k
        for i in 0..<k {
            let idx = min(i * step, samples.count - 1)
            centroids.append(ColorCluster(
                r: samples[idx].r,
                g: samples[idx].g,
                b: samples[idx].b,
                count: 0
            ))
        }
        
        // Step 3: Simple k-means iteration (max 10 iterations for speed)
        for _ in 0..<10 {
            var newCentroids = centroids.map { _ in ColorCluster(r: 0, g: 0, b: 0, count: 0) }
            
            // Assign each sample to nearest centroid
            for sample in samples {
                var minDist = Double.infinity
                var nearestIdx = 0
                for (idx, centroid) in centroids.enumerated() {
                    let dist = sqrt(
                        pow(sample.r - centroid.r, 2) +
                        pow(sample.g - centroid.g, 2) +
                        pow(sample.b - centroid.b, 2)
                    )
                    if dist < minDist {
                        minDist = dist
                        nearestIdx = idx
                    }
                }
                
                newCentroids[nearestIdx].r += sample.r
                newCentroids[nearestIdx].g += sample.g
                newCentroids[nearestIdx].b += sample.b
                newCentroids[nearestIdx].count += 1
            }
            
            // Update centroids
            var converged = true
            for i in 0..<k {
                if newCentroids[i].count > 0 {
                    let count = Double(newCentroids[i].count)
                    newCentroids[i].r /= count
                    newCentroids[i].g /= count
                    newCentroids[i].b /= count
                    
                    // Check if centroid moved significantly
                    if centroids[i].distance(to: newCentroids[i]) > 1.0 {
                        converged = false
                    }
                }
                centroids[i] = newCentroids[i]
            }
            
            if converged { break }
        }
        
        // Filter out empty clusters and return
        return centroids.filter { $0.count > 0 }
    }
}


