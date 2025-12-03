import XCTest
@testable import EventsApp

final class EventComposerStateSummaryTests: XCTestCase {
    func testCapacitySummaryUnlimited() {
        let state = EventComposerState(maxCapacity: 0)
        XCTAssertEqual(state.capacitySummaryText, "Unlimited")
    }

    func testTimeSummaryAllDay() {
        var state = EventComposerState()
        state.startTime = Date(timeIntervalSince1970: 0)
        state.isAllDay = true
        let summary = state.timeSummaryText
        XCTAssertTrue(summary.contains("All day"))
    }

    func testVisibilitySummary() {
        var state = EventComposerState()
        state.visibilityRaw = ComposerEventVisibility.inviteOnly.rawValue
        XCTAssertEqual(state.visibilitySummaryText, ComposerEventVisibility.inviteOnly.title)
    }

    func testVibesSummaryCount() {
        var state = EventComposerState()
        state.vibes = ["House", "Techno"]
        XCTAssertEqual(state.vibesSummaryText, "2 tags")
    }
}
