import XCTest
@testable import EventsApp

final class EventTimeConsistencyTests: XCTestCase {
    func testEndClampedAfterStart() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .hour, value: -2, to: start)
        let snapshot = EventTimeSnapshot(start: start, end: end, durationMinutes: nil, isAllDay: false)
        let normalized = EventTimeConsistency.normalized(snapshot: snapshot, mode: .end)
        XCTAssertEqual(normalized.end, start, "End time should clamp to start when before start")
    }

    func testDurationProducesEndTime() {
        let start = Date()
        let snapshot = EventTimeSnapshot(start: start, end: nil, durationMinutes: 90, isAllDay: false)
        let normalized = EventTimeConsistency.normalized(snapshot: snapshot, mode: .duration)
        let expected = Calendar.current.date(byAdding: .minute, value: 90, to: start)
        XCTAssertEqual(normalized.end, expected)
        XCTAssertEqual(normalized.durationMinutes, 90)
    }

    func testAllDayRoundsToDayBounds() {
        let start = ISO8601DateFormatter().date(from: "2024-08-24T15:34:00+0000")!
        let snapshot = EventTimeSnapshot(start: start, end: nil, durationMinutes: nil, isAllDay: true)
        let normalized = EventTimeConsistency.normalized(snapshot: snapshot, mode: .allDay)
        let startOfDay = Calendar.current.startOfDay(for: start)
        XCTAssertEqual(normalized.start, startOfDay)
        XCTAssertTrue(normalized.isAllDay)
    }
}
