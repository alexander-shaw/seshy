// swift-tools-version:5.9
import PackageDescription

//
//  Package.swift
//  EventsApp
//
//  Created by Шоу on 10/8/25.
//

// MARK: SwiftPM package that wraps the C-based H3 library as CH3 and exposes a Swift-friendly H3 module.

let package = Package(
    name: "H3",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "H3",
            targets: ["H3"]
        )
    ],
    targets: [
        // C target (raw H3):
        .target(
            name: "CH3",
            // Use default path: Sources/CH3:
            publicHeadersPath: "include",  // MARK: MUST BE INSIDE Sources/CH3.
            // If extra header paths are needed, add:
            cSettings: [
                .headerSearchPath("include")
            ]
        ),
        // Swift wrapper that depends on the C target:
        .target(
            name: "H3",
            dependencies: ["CH3"]  // Uses default path: Sources/H3
        ),
        .testTarget(
            name: "H3Tests",
            dependencies: ["H3"]
        )
    ]
)
