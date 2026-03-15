// LoopFollow
// LiveActivity.swift

import ActivityKit
import SwiftUI
import WidgetKit

struct LiveActivity: Widget {
    var body: some WidgetConfiguration {
        let configuration = ActivityConfiguration(for: LiveActivityAttributes.self) { context in
            LiveActivityView(context: context)
                .addIsWatchOS()
        } dynamicIsland: { context in
            let hasStaticColorScheme = context.state.glucoseColorScheme == "staticColor"

            var glucoseColor: Color {
                let state = context.state
                let isMgdL = state.unit == "mg/dL"

                // Hardcoded low/high to provide dynamic color shades between 55 and user-set low (~70) and high (~180)
                let hardCodedLow = isMgdL ? Decimal(55) : 55.asMmolL
                let hardCodedHigh = isMgdL ? Decimal(220) : 220.asMmolL

                return Color.getDynamicGlucoseColor(
                    glucoseValue: Decimal(string: state.bg) ?? 100,
                    highGlucoseColorValue: !hasStaticColorScheme
                        ? hardCodedHigh : state.highGlucose,
                    lowGlucoseColorValue: !hasStaticColorScheme
                        ? hardCodedLow : state.lowGlucose,
                    targetGlucose: isMgdL ? state.target : state.target.asMmolL,
                    glucoseColorScheme: state.glucoseColorScheme
                )
            }

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityExpandedLeadingView(
                        context: context,
                        glucoseColor: glucoseColor
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveActivityExpandedTrailingView(
                        context: context,
                        glucoseColor: hasStaticColorScheme ? .primary : glucoseColor
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityExpandedBottomView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    LiveActivityExpandedCenterView(context: context)
                }
            } compactLeading: {
                LiveActivityCompactLeadingView(
                    context: context,
                    glucoseColor: glucoseColor
                )
            } compactTrailing: {
                LiveActivityCompactTrailingView(
                    context: context,
                    glucoseColor: hasStaticColorScheme ? .primary : glucoseColor
                )
            } minimal: {
                LiveActivityMinimalView(
                    context: context,
                    glucoseColor: glucoseColor
                )
            }
            .widgetURL(URL(string: "loopfollow://"))
            .keylineTint(glucoseColor)
            .contentMargins(.horizontal, 0, for: .minimal)
            .contentMargins(.trailing, 0, for: .compactLeading)
            .contentMargins(.leading, 0, for: .compactTrailing)
        }

        if #available(iOS 18.0, *) {
            return configuration.supplementalActivityFamilies([.small])
        } else {
            return configuration
        }
    }
}

// MARK: - Preview helpers

private extension LiveActivityAttributes {
    static var preview: LiveActivityAttributes {
        LiveActivityAttributes(startDate: Date())
    }
}

private extension LiveActivityAttributes.ContentState {
    static var chartData: [LiveActivityAttributes.ChartItem] = [
        LiveActivityAttributes.ChartItem(value: 120, date: Date().addingTimeInterval(-600)),
        LiveActivityAttributes.ChartItem(value: 125, date: Date().addingTimeInterval(-300)),
        LiveActivityAttributes.ChartItem(value: 130, date: Date())
    ]

    static var detailedViewState =
        LiveActivityAttributes.ContentAdditionalState(
            chart: chartData,
            rotationDegrees: 0,
            cob: 20,
            iob: 1.5,
            tdd: 43.21,
            isOverrideActive: false,
            overrideName: "Exercise",
            overrideDate: Date().addingTimeInterval(-3600),
            overrideDuration: 120,
            overrideTarget: 150,
            widgetItems: LiveActivityAttributes.LiveActivityItem.defaultItems
        )

    // 0 is the widest digit; "00.0" gives the upper bound on text width for mmol/L notation
    static var testWide: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "00.0",
            direction: "→",
            change: "+0.0",
            date: Date(),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: false,
            useDetailedViewWatchOS: false,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testVeryWide: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "00.0",
            direction: "↑↑",
            change: "+0.0",
            date: Date(),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: false,
            useDetailedViewWatchOS: false,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testSuperWide: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "00.0",
            direction: "↑↑↑",
            change: "+0.0",
            date: Date(),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: false,
            useDetailedViewWatchOS: false,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testNarrow: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "00",
            direction: "↑",
            change: "+0",
            date: Date(),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: false,
            useDetailedViewWatchOS: false,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testMedium: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "000",
            direction: "↗︎",
            change: "+00",
            date: Date(),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: false,
            useDetailedViewWatchOS: false,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testExpired: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "--",
            direction: nil,
            change: "--",
            date: Date().addingTimeInterval(-60 * 60),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: false,
            useDetailedViewWatchOS: false,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testWideDetailed: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "00.0",
            direction: "→",
            change: "+0.0",
            date: Date(),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: true,
            useDetailedViewWatchOS: true,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testVeryWideDetailed: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "00.0",
            direction: "↑↑",
            change: "+0.0",
            date: Date(),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: true,
            useDetailedViewWatchOS: true,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testSuperWideDetailed: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "00.0",
            direction: "↑↑↑",
            change: "+0.0",
            date: Date(),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: true,
            useDetailedViewWatchOS: true,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testNarrowDetailed: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "00",
            direction: "↑",
            change: "+0",
            date: Date(),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: true,
            useDetailedViewWatchOS: true,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testMediumDetailed: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "000",
            direction: "↗︎",
            change: "+00",
            date: Date(),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: true,
            useDetailedViewWatchOS: true,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }

    static var testExpiredDetailed: LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            unit: "mg/dL",
            bg: "--",
            direction: nil,
            change: "--",
            date: Date().addingTimeInterval(-60 * 60),
            highGlucose: 180,
            lowGlucose: 70,
            target: 100,
            glucoseColorScheme: "staticColor",
            useDetailedViewIOS: true,
            useDetailedViewWatchOS: true,
            detailedViewState: detailedViewState,
            isInitialState: false
        )
    }
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
#Preview("Simple", as: .content, using: LiveActivityAttributes.preview) {
    LiveActivity()
} contentStates: {
    LiveActivityAttributes.ContentState.testSuperWide
    LiveActivityAttributes.ContentState.testVeryWide
    LiveActivityAttributes.ContentState.testWide
    LiveActivityAttributes.ContentState.testMedium
    LiveActivityAttributes.ContentState.testNarrow
    LiveActivityAttributes.ContentState.testExpired
}

@available(iOS 17.0, iOSApplicationExtension 17.0, *)
#Preview("Detailed", as: .content, using: LiveActivityAttributes.preview) {
    LiveActivity()
} contentStates: {
    LiveActivityAttributes.ContentState.testSuperWideDetailed
    LiveActivityAttributes.ContentState.testVeryWideDetailed
    LiveActivityAttributes.ContentState.testWideDetailed
    LiveActivityAttributes.ContentState.testMediumDetailed
    LiveActivityAttributes.ContentState.testNarrowDetailed
    LiveActivityAttributes.ContentState.testExpiredDetailed
}
