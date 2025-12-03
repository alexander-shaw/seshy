//
//  EventDateTimeFormatter.swift
//  EventsApp
//
//  Unified date/time formatter for all event-related displays.
//  Format examples (matching screenshot):
//  - "Tonight · 10:30p"
//  - "Tomorrow · 9p"
//  - "Fri · 11p"
//  - "Mar 2 · 8p"
//

import Foundation

/// Unified date/time formatter for all event-related displays
enum EventDateTimeFormatter {
    
    // MARK: - Private DateFormatter Factory
    
    /// Builds a localized `DateFormatter` from a date format template.
    private static func formatter(withTemplate template: String,
                                  locale: Locale = .current,
                                  calendar: Calendar = .current) -> Foundation.DateFormatter {
        let df = Foundation.DateFormatter()
        df.locale = locale
        df.calendar = calendar
        df.setLocalizedDateFormatFromTemplate(template)
        return df
    }
    
    /// "Tuesday"
    private static func fullWeekday(locale: Locale = .current,
                                   calendar: Calendar = .current) -> Foundation.DateFormatter {
        formatter(withTemplate: "EEEE", locale: locale, calendar: calendar)
    }
    
    /// "Tue 11/18"
    private static func eee_md(locale: Locale = .current,
                              calendar: Calendar = .current) -> Foundation.DateFormatter {
        formatter(withTemplate: "EEE Md", locale: locale, calendar: calendar)
    }
    
    /// "Tue 11/18/2025"
    private static func eee_md_yyyy(locale: Locale = .current,
                                   calendar: Calendar = .current) -> Foundation.DateFormatter {
        formatter(withTemplate: "EEE Md yyyy", locale: locale, calendar: calendar)
    }
    
    /// Short time like "3 PM" or "3:45 PM" depending on locale.
    private static func shortTimeFormatter(locale: Locale = .current,
                                 calendar: Calendar = .current) -> Foundation.DateFormatter {
        let df = Foundation.DateFormatter()
        df.locale = locale
        df.calendar = calendar
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }
    
    /// Hour-only time like "3" or "3:30" (no AM/PM). Useful for "from 3 to 7 PM".
    private static func hourOnly(locale: Locale = .current,
                                calendar: Calendar = .current) -> Foundation.DateFormatter {
        return formatter(withTemplate: "H:mm", locale: locale, calendar: calendar)
    }
    
    /// Threshold (24h clock) for calling same-day events "Tonight" instead of "Today".
    private static let tonightHourThreshold: Int = 17 // 5 PM
    
    // MARK: - Public API
    
    /// Event card preview format (EventCardPreview, DiscoverListView)
    /// Examples: "Tonight · 10:30p", "Tomorrow · 9p", "Fri · 11p", "Mar 2 · 8p", "Today · All Day", "Tomorrow · All Day"
    static func cardPreview(for date: Date,
                           isAllDay: Bool = false,
                           now: Date = Date(),
                           calendar: Calendar = .current,
                           locale: Locale = .current) -> String {
        let dayLabel = dayLabel(for: date, now: now, calendar: calendar, locale: locale)
        if isAllDay {
            return "\(dayLabel) · All Day"
        }
        let timeLabel = shortTime(for: date, locale: locale, calendar: calendar)
        return "\(dayLabel) · \(timeLabel)"
    }
    
    /// Notification timestamp (relative time)
    /// Examples: "just now", "5 m", "3 h", "4 d", "2 w"
    static func notificationTimestamp(for date: Date, now: Date = Date()) -> String {
        let interval = now.timeIntervalSince(date)
        if interval < 0 {
            // Future date – treat as "just now" rather than negative.
            return "just now"
        }

        if interval < 5 {
            return "just now"
        }

        let seconds = Int(interval)
        if seconds < 60 {
            return "\(seconds) s"
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes) m"
        }

        let hours = minutes / 60
        if hours < 24 {
            return "\(hours) h"
        }

        let days = hours / 24
        if days < 7 {
            return "\(days) d"
        }

        let weeks = days / 7
        return "\(weeks) w"
    }
    
    /// Event detail/full sheet (with ranges)
    /// Examples: "Tomorrow from 3 to 7p", "Tomorrow at 3p to Friday at 5p"
    static func detailRange(start: Date,
                           end: Date,
                           now: Date = Date(),
                           calendar: Calendar = .current,
                           locale: Locale = .current) -> String {
        let sameDay = calendar.isDate(start, inSameDayAs: end)

        if sameDay {
            return sameDayRangeString(start: start,
                                     end: end,
                                     now: now,
                                     calendar: calendar,
                                     locale: locale)
        } else {
            return multiDayRangeString(start: start,
                                      end: end,
                                      now: now,
                                      calendar: calendar,
                                      locale: locale)
        }
    }
    
    /// Calendar section header
    /// Examples: "Today", "Tomorrow", "Saturday", "Sun 12/7"
    static func calendarHeader(for date: Date,
                              now: Date = Date(),
                              calendar: Calendar = .current,
                              locale: Locale = .current) -> String {
        return dayLabel(for: date, now: now, calendar: calendar, locale: locale)
    }
    
    /// Calendar row time
    /// Examples: "10:30p", "9p", "" (for all-day)
    static func calendarTime(for date: Date?,
                            isAllDay: Bool,
                            locale: Locale = .current,
                            calendar: Calendar = .current) -> String {
        guard !isAllDay, let date = date else { return "" }
        return shortTime(for: date, locale: locale, calendar: calendar)
    }
    
    /// Event composer summary (NewEventView)
    /// Examples: "All day Mar 2", "Mar 2 · 3p–7p", "Mar 2 → Mar 3"
    static func composerSummary(start: Date,
                               end: Date?,
                               durationMinutes: Int64?,
                               isAllDay: Bool,
                               locale: Locale = .current,
                               calendar: Calendar = .current) -> String {
        if isAllDay {
            let dayLabel = dayLabel(for: start, now: Date(), calendar: calendar, locale: locale)
            return "All day \(dayLabel)"
        }
        
        if let end = end {
            let startDayLabel = dayLabel(for: start, now: Date(), calendar: calendar, locale: locale)
            let startTime = shortTime(for: start, locale: locale, calendar: calendar)
            let endTime = shortTime(for: end, locale: locale, calendar: calendar)
            
            if calendar.isDate(start, inSameDayAs: end) {
                return "\(startDayLabel) · \(startTime)–\(endTime)"
            } else {
                let endDayLabel = dayLabel(for: end, now: Date(), calendar: calendar, locale: locale)
                return "\(startDayLabel) → \(endDayLabel)"
            }
        }
        
        if let durationMinutes = durationMinutes {
            let dayLabel = dayLabel(for: start, now: Date(), calendar: calendar, locale: locale)
            let hours = Double(durationMinutes) / 60.0
            if hours >= 1 {
                return String(format: "%@ · %.1fh", dayLabel, hours)
            }
            return String(format: "%@ · %dm", dayLabel, Int(durationMinutes))
        }
        
        // Just start time
        let dayLabel = dayLabel(for: start, now: Date(), calendar: calendar, locale: locale)
        let time = shortTime(for: start, locale: locale, calendar: calendar)
        return "\(dayLabel) · \(time)"
    }
    
    // MARK: - Private Helpers
    
    /// Day label: "Tonight", "Today", "Tomorrow", "Fri", "Mar 2", "Mar 2, 2026"
    private static func dayLabel(for date: Date,
                                now: Date,
                                calendar: Calendar,
                                locale: Locale) -> String {
        let isToday = calendar.isDate(date, inSameDayAs: now)
        if isToday {
            let hour = calendar.component(.hour, from: date)
            return hour >= tonightHourThreshold ? "Tonight" : "Today"
        }
        
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTarget = calendar.startOfDay(for: date)
        
        guard let dayDiff = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget).day else {
            // Fallback to full date
            let nowYear = calendar.component(.year, from: now)
            let dateYear = calendar.component(.year, from: date)
            if dateYear == nowYear {
                return eee_md(locale: locale, calendar: calendar).string(from: date)
            } else {
                return eee_md_yyyy(locale: locale, calendar: calendar).string(from: date)
            }
        }
        
        if dayDiff == 1 {
            return "Tomorrow"
        } else if dayDiff > 1 && dayDiff <= 6 {
            // Weekday name: "Fri"
            let weekdayFormatter = fullWeekday(locale: locale, calendar: calendar)
            return weekdayFormatter.string(from: date)
        }
        
        // 7+ days away
        let nowYear = calendar.component(.year, from: now)
        let dateYear = calendar.component(.year, from: date)
        if dateYear == nowYear {
            // "Mar 2" format - extract just the date part
            let dateFormatter = eee_md(locale: locale, calendar: calendar)
            let fullString = dateFormatter.string(from: date)
            // Extract date part (e.g., "Fri 12/7" -> "12/7" or keep "Fri 12/7" depending on format)
            // For simplicity, return the full formatted string
            return fullString
        } else {
            return eee_md_yyyy(locale: locale, calendar: calendar).string(from: date)
        }
    }
    
    /// Short time format: "10:30p", "9p", "10:30a", "9a"
    /// Removes minutes when time is on the hour (e.g., "1:00 PM" -> "1p", but "11:15 PM" -> "11:15p")
    private static func shortTime(for date: Date,
                                 locale: Locale,
                                 calendar: Calendar) -> String {
        let formatter = shortTimeFormatter(locale: locale, calendar: calendar)
        var timeString = formatter.string(from: date)
        
        // Check if minutes are zero (on the hour)
        let minute = calendar.component(.minute, from: date)
        let isOnTheHour = minute == 0
        
        // Convert to lowercase format: "10:30 PM" -> "10:30p"
        timeString = timeString.replacingOccurrences(of: " AM", with: "a", options: .caseInsensitive)
        timeString = timeString.replacingOccurrences(of: " PM", with: "p", options: .caseInsensitive)
        
        // If on the hour, remove ":00" (e.g., "1:00p" -> "1p", "11:00a" -> "11a")
        if isOnTheHour {
            timeString = timeString.replacingOccurrences(of: ":00", with: "")
        }
        
        return timeString
    }
    
    /// Same-calendar-day range: "Tomorrow from 3 to 7p"
    private static func sameDayRangeString(start: Date,
                                          end: Date,
                                          now: Date,
                                          calendar: Calendar,
                                          locale: Locale) -> String {
        let baseLabel = dayLabel(for: start, now: now, calendar: calendar, locale: locale)

        let timeWithAmPm = shortTimeFormatter(locale: locale, calendar: calendar)
        let hourOnlyFormatter = hourOnly(locale: locale, calendar: calendar)

        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)

        let sameMeridiem: Bool = {
            // Basic heuristic: compare AM/PM by observing resulting strings.
            let startString = timeWithAmPm.string(from: start)
            let endString = timeWithAmPm.string(from: end)
            return (startString.hasSuffix("AM") && endString.hasSuffix("AM"))
            || (startString.hasSuffix("PM") && endString.hasSuffix("PM"))
        }()

        if sameMeridiem,
           startComponents.hour != nil,
           endComponents.hour != nil {
            // "Tomorrow from 3 to 7p"
            let startHourOnly = hourOnlyFormatter.string(from: start)
            let endFull = shortTime(for: end, locale: locale, calendar: calendar)
            return "\(baseLabel) from \(startHourOnly) to \(endFull)"
        } else {
            // Fallback: "Tomorrow from 11a to 1p"
            let startFull = shortTime(for: start, locale: locale, calendar: calendar)
            let endFull = shortTime(for: end, locale: locale, calendar: calendar)
            return "\(baseLabel) from \(startFull) to \(endFull)"
        }
    }

    /// Different-day range: "Tomorrow at 3p to Friday at 5p"
    private static func multiDayRangeString(start: Date,
                                           end: Date,
                                           now: Date,
                                           calendar: Calendar,
                                           locale: Locale) -> String {
        let baseStart = dayLabel(for: start, now: now, calendar: calendar, locale: locale)
        let baseEnd = dayLabel(for: end, now: now, calendar: calendar, locale: locale)

        let startTime = shortTime(for: start, locale: locale, calendar: calendar)
        let endTime = shortTime(for: end, locale: locale, calendar: calendar)

        // "Tomorrow at 3p to Friday at 5p"
        return "\(baseStart) at \(startTime) to \(baseEnd) at \(endTime)"
    }
}

