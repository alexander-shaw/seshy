//
//  UIColor+Extensions.swift
//  EventsApp
//
//  Created by Шоу on 10/26/25.
//

import SwiftUI
import UIKit

extension UIColor {
    struct Components { let r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat }
    var srgbComponents: Components? {
        var r : CGFloat = 0, g : CGFloat = 0, b : CGFloat = 0, a : CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return Components(r: r, g: g, b: b, a: a)
    }
}
