//
//  PlaceSelectionView.swift
//  EventsApp
//
//  Created by Шоу on 10/27/25.
//

import SwiftUI
import CoreData
import CoreLocation
import CoreDomain

struct PlaceSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    @Binding var selectedPlace: Place
    
    // Pullman, WA base coordinates:
    private let pullmanLat: Double = 46.7317
    private let pullmanLon: Double = -117.1814
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(theme.colors.accent)
                
                Spacer()
                
                Text("Select Location")
                    .font(.headline)
                    .foregroundColor(theme.colors.mainText)
                
                Spacer()
                
                Button("Random") {
                    generateFakePlace()
                    dismiss()
                }
                .foregroundColor(theme.colors.accent)
            }
            .padding(.horizontal, theme.spacing.medium)
            .padding(.vertical, theme.spacing.small)
            
            Divider()
                .foregroundStyle(theme.colors.surface)

            VStack(spacing: theme.spacing.large) {
                Spacer()
                
                VStack(spacing: theme.spacing.medium) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(theme.colors.accent)
                    
                    Text("Using Fake Location")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.mainText)
                    
                    Text("A random location in Pullman, WA will be generated for this event.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(theme.colors.offText)
                        .padding(.horizontal, theme.spacing.large)
                }
                
                Spacer()
            }
            .padding(.horizontal, theme.spacing.medium)
            .padding(.vertical, theme.spacing.large)
        }
        .background(theme.colors.background)
    }
    
    // MARK: - HELPER METHODS:
    private func generateFakePlace() {
        // Generate random offset from Pullman coordinates.
        // Add/subtract random value up to ~0.01 degrees (roughly 1 km).
        let latOffset = Double.random(in: -0.01...0.01)
        let lonOffset = Double.random(in: -0.01...0.01)
        
        let randomLatitude = pullmanLat + latOffset
        let randomLongitude = pullmanLon + lonOffset
        
        // Generate random radius between 5-100 meters.
        let randomRadius = Double.random(in: 50...500)
        
        // Update the existing place instead of creating a new one, which ensures the correct managed object context.
        selectedPlace.name = "Event Location"
        selectedPlace.details = "Generated location in Pullman, WA"
        selectedPlace.city = "Pullman"
        selectedPlace.stateRegion = "WA"
        selectedPlace.latitude = randomLatitude
        selectedPlace.longitude = randomLongitude
        selectedPlace.radius = randomRadius
        selectedPlace.maxCapacity = NSNumber(value: 100)
        selectedPlace.updatedAt = Date()
        
        // Save to context if we have the same context.
        guard let context = selectedPlace.managedObjectContext else {
            print("Warning: selectedPlace has no managed object context")
            return
        }
        
        // Save synchronously to ensure it's saved before the view dismisses.
        context.performAndWait {
            do {
                try context.save()
                print("Place saved:  \(selectedPlace.name ?? "nil") at (\(selectedPlace.latitude), \(selectedPlace.longitude))")
            } catch {
                print("Failed to save place:  \(error)")
            }
        }
    }
}
