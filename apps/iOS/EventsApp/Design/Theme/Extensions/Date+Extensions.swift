//
//  Date+Extensions.swift
//  EventsApp
//
//  Created by Шоу on 11/8/25.
//

import Foundation

extension Date {
    /// True if `self` is in the same calendar day as `now`.
    func isToday(relativeTo now: Date = TimeViewModel.shared.currentDateTime,
                 cal: Calendar = .current) -> Bool {
        cal.isDate(self, inSameDayAs: now)
    }

    /// True if `self` is tomorrow relative to `now`.
    func isTomorrow(relativeTo now: Date = TimeViewModel.shared.currentDateTime,
                    cal: Calendar = .current) -> Bool {
        let startNow = cal.startOfDay(for: now)
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: startNow) else { return false }
        return cal.isDate(self, inSameDayAs: tomorrow)
    }

    /// True if `self` is within the next `days` (exclusive of today), e.g. 1...6 for next <7 days.
    func isWithinNextDays(_ days: Int,
                          relativeTo now: Date = TimeViewModel.shared.currentDateTime,
                          cal: Calendar = .current) -> Bool {
        let startNow = cal.startOfDay(for: now)
        let startSelf = cal.startOfDay(for: self)
        guard let delta = cal.dateComponents([.day], from: startNow, to: startSelf).day else { return false }
        return (1...days).contains(delta)
    }

    /// True if `self` is in the same calendar year as `now`.
    func isSameYear(as now: Date = TimeViewModel.shared.currentDateTime,
                    cal: Calendar = .current) -> Bool {
        cal.component(.year, from: self) == cal.component(.year, from: now)
    }
}
