//
//  Ticket.swift
//  EventsApp
//
//  Created by Auto on 12/6/24.
//

import Foundation
import CoreData

@objc(Ticket)
public class Ticket: NSManagedObject, Identifiable {}

extension Ticket {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ticket> {
        NSFetchRequest<Ticket>(entityName: "Ticket")
    }

    @NSManaged public var id: UUID  // MARK: Unique.
    @NSManaged public var name: String
    @NSManaged public var priceCents: Int64
    @NSManaged public var event: EventItem?
}

// MARK: - Convenience Extensions
extension Ticket {
    /// Price in dollars (converted from cents)
    public var priceDollars: Double {
        get { Double(priceCents) / 100.0 }
        set { priceCents = Int64(newValue * 100) }
    }
    
    /// Formatted price string
    public var formattedPrice: String {
        if priceDollars == 0 {
            return "Free"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        
        // If price ends in .00 (no cents), show only dollars without cents
        if priceCents % 100 == 0 {
            formatter.maximumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        }
        
        return formatter.string(from: NSNumber(value: priceDollars)) ?? "$0"
    }
}

// Local & Cloud Storage:
extension Ticket: SyncTrackable {
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var schemaVersion: Int16

    // Computed:
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
