//
//  String+Extensions.swift
//  EventsApp
//
//  Created by Шоу on 10/26/25.
//

import SwiftUI
import UIKit

extension String {
    // True if string is exactly 6 hex digits (no '#').
    var isValidHex6: Bool {
        guard count == 6 else { return false }
        return range(of: "^[0-9A-Fa-f]{6}$", options: .regularExpression) != nil
    }

    // Returns 6 hex digits if this string looks like "#RRGGBB" or "RRGGBB".
    var strippedHex6: String? {
        var s = trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        return s.isValidHex6 ? s : nil
    }
}
