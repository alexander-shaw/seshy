//
//  QRCodeGenerator.swift
//  EventsApp
//
//  Created by GPT-5.1 Codex on 11/28/25.
//

import Foundation
import SwiftUI
import UIKit
import CoreImage

/// Represents the data encoded inside QR codes.
/// Currently only stores the user profile ID for simplicity.
struct QRCodePayload: Codable, Equatable {
    let id: UUID
}

/// Generates standard QR code images.
struct QRCodeGenerator {
    private let context = CIContext()

    func makeQRCodeImage(from profileID: UUID, dimension: CGFloat = 320) -> UIImage? {
        // Encode the UUID as UTF-8 data, which CIQRCodeGenerator expects.
        guard let messageData = profileID.uuidString.data(using: .utf8) else {
            print("QRCodeGenerator: Failed to encode UUID to data")
            return nil
        }

        // Create standard QR code filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            print("QRCodeGenerator: CIQRCodeGenerator filter not available")
            return nil
        }

        // Set the message as raw data
        filter.setValue(messageData, forKey: "inputMessage")
        
        // Set correction level (H = High, allows up to 30% damage)
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else {
            print("QRCodeGenerator: Filter produced no output image")
            return nil
        }

        // Scale to desired dimension
        let scaleX = dimension / outputImage.extent.size.width
        let scaleY = dimension / outputImage.extent.size.height
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            print("QRCodeGenerator: Failed to create CGImage")
            return nil
        }

        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
}

