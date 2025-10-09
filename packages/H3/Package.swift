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
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "H3", targets: ["H3"])  // Import H3 in Swift.
    ],
    targets: [
        // C target for the raw H3 C library.
        .target(
            name: "CH3",
            path: "sources",
            publicHeadersPath: "../include",
            cSettings: [
                .headerSearchPath("../include")
            ]
        ),
        // Swift wrapper target (recommended for nicer APIs).
        .target(
            name: "H3",
            dependencies: ["CH3"]
        ),
        .testTarget(
            name: "H3Tests",
            dependencies: ["H3"]
        )
    ]
)
