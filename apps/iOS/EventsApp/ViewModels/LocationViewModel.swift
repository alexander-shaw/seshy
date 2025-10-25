//
//  LocationViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// Manages H3 geospatial cell data for location-based features.
// Provides a reactive interface for SwiftUI views to work with H3 cells including:
// - Location tracking and geospatial indexing;
// - Motion type detection and analysis;
// - H3 cell resolution management; and
// - Integration with Core Data persistence layer.

import Foundation
import CoreData
import SwiftUI
import Combine
import CoreLocation
import CoreDomain

@MainActor
final class LocationViewModel: ObservableObject {
    @Published var timestamp: Date = Date()
    @Published var motionType: MotionType = .unknown
    @Published var horizontalAccuracy: Double = 0.0
    @Published var altitude: Double = 0.0
    @Published var verticalAccuracy: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var speedAccuracy: Double = 0.0
    @Published var course: Double = 0.0
    @Published var courseAccuracy: Double = 0.0
    @Published var resolution: Int16 = 9
    @Published var h3Index: Int64 = 0
    
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var h3Cells: [H3Node] = []
    @Published private(set) var cellCount: Int = 0
    
    private let context: NSManagedObjectContext
    private let repository: H3CellRepository
    private var h3Cell: H3Node?

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: H3CellRepository = CoreDataH3CellRepository()) {
        self.context = context
        self.repository = repository
    }
    
    func createH3Cell(from location: CLLocation, motion: MotionType = .unknown) async {
        isSaving = true
        errorMessage = nil
        
        do {
            let newCell = try await repository.createH3Cell(from: location, motion: motion)
            h3Cell = newCell
            populateFromCell(newCell)
            await updateCellCount()
        } catch {
            errorMessage = "Failed to create H3 cell: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func loadH3Cells(in dateRange: DateInterval?, limit: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let cellDTOs = try await repository.getH3Cells(in: dateRange, limit: limit)
            // TODO: work with DTOs until repository is updated.
        } catch {
            errorMessage = "Failed to load H3 cells: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadH3Cells(at h3Index: Int64, limit: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            h3Cells = try await repository.getH3Cells(at: h3Index, limit: limit)
        } catch {
            errorMessage = "Failed to load H3 cells at index: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadRecentH3Cells(limit: Int = 100) async {
        isLoading = true
        errorMessage = nil
        
        do {
            h3Cells = try await repository.getRecentH3Cells(limit: limit)
        } catch {
            errorMessage = "Failed to load recent H3 cells: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteOldH3Cells(olderThan date: Date) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let deletedCount = try await repository.deleteOldH3Cells(olderThan: date)
            await updateCellCount()
            // Reload recent cells after cleanup.
            await loadRecentH3Cells()
        } catch {
            errorMessage = "Failed to delete old H3 cells: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateCellCount() async {
        do {
            cellCount = try await repository.getH3CellCount()
        } catch {
            errorMessage = "Failed to get cell count: \(error.localizedDescription)"
        }
    }
    
    // MARK: - COMPUTED PROPERTIES:

    var trustScore: Double {
        // Guardrails to avoid divide-by-zero and wild spikes.
        let hAccuracy = max(horizontalAccuracy, 1.0)
        let vAccuracy = max(verticalAccuracy, 1.0)
        let sAccuracy = max(speedAccuracy, 0.1)
        let cAccuracy = max(courseAccuracy, 1.0)
        
        // Product of penalties (smaller accuracy => higher trust).
        var score = 1.0 / (hAccuracy * hAccuracy)  // Dominant, quadratic falloff.
        score *= 1.0 / (0.25 * vAccuracy + 1.0)  // Gentle linear penalty.
        score *= 1.0 / (0.5 * sAccuracy + 1.0)  // Gentle linear penalty.
        score *= 1.0 / (0.02 * cAccuracy + 1.0)  // Very gentle linear penalty.

        // Walking is more predictable than flying
        switch motionType {
            case .walking, .running, .cycling, .driving: score *= 1.1
            case .stationary: score *= 1.0
            case .flying, .transition: score *= 0.9  // Erratic 3D movement -> less predictable.
            case .unknown: score *= 0.7  // No motion context -> penalized.
        }
        
        return score
    }
    
    var reliabilityLevel: String {
        switch trustScore {
            case 0.03...: return "HIGH"
            case 0.01..<0.03: return "MEDIUM"
            case 0.001..<0.01: return "LOW"
            default: return "IGNORE"
        }
    }
    
    var reliabilityColor: Color {
        switch trustScore {
            case 0.03...: return .green
            case 0.01..<0.03: return .yellow
            case 0.001..<0.01: return .orange
            default: return .red
        }
    }
    
    var motionTypeDescription: String {
        switch motionType {
            case .unknown: return "Unknown"
            case .stationary: return "Stationary"
            case .walking: return "Walking"
            case .running: return "Running"
            case .cycling: return "Cycling"
            case .driving: return "Driving"
            case .flying: return "Flying"
            case .transition: return "Transition"
        }
    }
    
    var speedDescription: String {
        if speed < 0 {
            return "Unknown"
        } else {
            return String(format: "%.1f m/s", speed)
        }
    }
    
    var courseDescription: String {
        if course < 0 {
            return "Unknown"
        } else {
            return String(format: "%.0f°", course)
        }
    }
    
    var accuracyDescription: String {
        return String(format: "±%.1fm", horizontalAccuracy)
    }
    
    var recentCells: [H3Node] {
        return Array(h3Cells.prefix(10))
    }
    
    var cellsByMotionType: [MotionType: [H3Node]] {
        return Dictionary(grouping: h3Cells) { $0.motionType }
    }
    
    // MARK: - PRIVATE METHODS:

    private func populateFromCellDTO(_ cellDTO: H3NodeDTO) {
        timestamp = cellDTO.timestamp
        motionType = MotionType(rawValue: cellDTO.motionTypeRaw) ?? .unknown
        horizontalAccuracy = cellDTO.horizontalAccuracy ?? 0.0
        altitude = cellDTO.altitude ?? 0.0
        verticalAccuracy = cellDTO.verticalAccuracy ?? 0.0
        speed = cellDTO.speed ?? 0.0
        speedAccuracy = cellDTO.speedAccuracy ?? 0.0
        course = cellDTO.course ?? 0.0
        courseAccuracy = cellDTO.courseAccuracy ?? 0.0
        resolution = cellDTO.resolution
        h3Index = cellDTO.h3Index
    }
    
    private func populateFromCell(_ cell: H3Node) {
        timestamp = cell.timestamp
        motionType = cell.motionType
        horizontalAccuracy = cell.horizontalAccuracy?.doubleValue ?? 0.0
        altitude = cell.altitude?.doubleValue ?? 0.0
        verticalAccuracy = cell.verticalAccuracy?.doubleValue ?? 0.0
        speed = cell.speed?.doubleValue ?? 0.0
        speedAccuracy = cell.speedAccuracy?.doubleValue ?? 0.0
        course = cell.course?.doubleValue ?? 0.0
        courseAccuracy = cell.courseAccuracy?.doubleValue ?? 0.0
        resolution = cell.resolution
        h3Index = cell.h3Index
    }
}
