//
//  Theme.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

extension Theme {
    struct ColorPalette {
        static let accent: Color = Color.blue
        /*
        static let accentGradient: LinearGradient = LinearGradient(
            colors: [
                // Orange -> red:
                Color(hex: "#FF512F"), Color(hex: "#DD2476")
                // Purple -> red: Color(hex: "#6E00FF"), Color(hex: "#B000F2"), Color(hex: "#FF007A")
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
         */
        static let background: Color = Color(hex: "#121212")
        static let surface: Color = Color(hex: "#292929")
        static let mainText: Color = Color(hex: "#FFFFFF")
        static let offText: Color = Color(hex: "#B3B3B3")
        static let error: Color = Color.red
    }
}

enum ColorChoice: Identifiable {
    case solid(Color)
    case gradient(LinearGradient)
    case custom

    var id: UUID { UUID() }

    var style: AnyShapeStyle {
        switch self {
        case .solid(let color): return AnyShapeStyle(color)
        case .gradient(let gradient): return AnyShapeStyle(gradient)
        case .custom: return AnyShapeStyle(Color.gray.opacity(0.3))
        }
    }

    static let colorOptions: [ColorChoice] = [
        .solid(.blue), .solid(Color(hex: "#0080FF")), .solid(Color(hex: "#2142AB")),
        .solid(.green), .solid(Color(hex: "#0EA7A5")), .solid(Color(hex: "#63B7B7")),
        .solid(.yellow), .solid(Color(hex: "#FFD700")), .solid(.orange),
        .solid(.red), .solid(Color(hex: "#C92519")), .solid(.purple),
        .gradient(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)),
        .gradient(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)),
        .custom
    ]

    static func random() -> ColorChoice {
        colorOptions
            .filter {
                if case .custom = $0 {
                    return false
                }
                return true
            }
            .randomElement() ?? .solid(.blue)
    }
}

// MARK: - TO USE HEX CODES:
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        self.init(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }

    func toHexString(includeAlpha: Bool = false) -> String {
        let uiColor = UIColor(self)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)), lroundf(Float(alpha * 255)))
        } else {
            return String(format: "#%02X%02X%02X", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
        }
    }
    
    // Fetches an image and returns its average color (falls back to background).
    static func averageColor(from url: URL) async -> Color {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data),
               let uiAvg = uiImage.averageColor() {
                return Color(uiAvg)
            }
        } catch { /* ignore and use fallback */ }
        return Theme.ColorPalette.background
    }

    // Average color from an existing UIImage (no network).
    static func averageColor(from image: UIImage) -> Color? {
        image.averageColor().map { Color($0) }
    }
}

// Average color in UIImage with CIAreaAverage:
extension UIImage {
    func averageColor() -> UIColor? {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: [.workingColorSpace: NSNull()])

        let filter = CIFilter.areaAverage()
        filter.inputImage = ciImage
        filter.extent = ciImage.extent

        guard let output = filter.outputImage else { return nil }

        // Render the 1×1 pixel result
        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return UIColor(
            red: CGFloat(pixel[0]) / 255.0,
            green: CGFloat(pixel[1]) / 255.0,
            blue: CGFloat(pixel[2]) / 255.0,
            alpha: CGFloat(pixel[3]) / 255.0
        )
    }
}
