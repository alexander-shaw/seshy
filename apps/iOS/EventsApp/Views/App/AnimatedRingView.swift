//
//  AnimatedRingView.swift
//  EventsApp
//
//  Created by Шоу on 10/16/25.
//

import SwiftUI

struct AnimatedRingView: View {
    @Environment(\.theme) private var theme
    
    let ringColor: Color
    let animationDuration: CGFloat = 1.50
    let ringRadius: CGFloat
    let lineThickness: CGFloat
    let growthTargets: [CGFloat] = (0..<40).map { _ in CGFloat.random(in: -0.5...3) }

    init() {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        self.ringRadius = screenHeight * 0.04
        self.lineThickness = screenWidth * 0.04
        self.ringColor = Color.white // Will be overridden by theme
    }
    
    var body: some View {
        // TimelineView() provides efficient rendering, fine-grained control, and reduced overhead.
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: animationDuration * 2)  // Out and in.
            let normalizedProgress = elapsed / animationDuration
            
            let animatedProgress = normalizedProgress <= 1.0 ? normalizedProgress : 2.0 - normalizedProgress
            
            AnimatedRingShape(
                dataPoints: growthTargets.map { $0 * CGFloat(animatedProgress) },
                ringRadius: ringRadius
            )
            .stroke(theme.colors.mainText, lineWidth: lineThickness)
            .frame(width: ringRadius*2, height: ringRadius*2)
            .shadow(color: theme.colors.mainText.opacity(0.50), radius: lineThickness/5, x: 0, y: 0)
            .padding(.bottom, lineThickness)
        }
    }
}

struct AnimatedRingShape: Shape {
    var dataPoints: [CGFloat]
    var ringRadius: CGFloat

    var animatableData: AnimatableRingData {
        get { AnimatableRingData(values: dataPoints) }
        set { dataPoints = newValue.values }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let count = dataPoints.count

        for index in 0..<count {
            let angle = Angle.degrees(Double(index) / Double(count) * 360.0)
            let adjustedRadius = ringRadius + dataPoints[index]

            let point = CGPoint(
                x: center.x + CGFloat(cos(angle.radians)) * adjustedRadius,
                y: center.y + CGFloat(sin(angle.radians)) * adjustedRadius
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct AnimatableRingData: VectorArithmetic {
    var values: [CGFloat]

    static var zero: AnimatableRingData {
        return AnimatableRingData(values: [])
    }

    static func + (lhs: AnimatableRingData, rhs: AnimatableRingData) -> AnimatableRingData {
        return AnimatableRingData(values: zip(lhs.values, rhs.values).map(+))
    }

    static func - (lhs: AnimatableRingData, rhs: AnimatableRingData) -> AnimatableRingData {
        return AnimatableRingData(values: zip(lhs.values, rhs.values).map(-))
    }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * CGFloat(rhs) }
    }

    var magnitudeSquared: Double {
        return values.reduce(0) { $0 + Double($1 * $1) }
    }
}
