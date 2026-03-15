// LoopFollow
// LiveActivityAttributes.swift
//
// Shared between the LoopFollowLiveActivity extension target and the main LoopFollow app target.
// The extension renders the widget UI; the main app constructs and pushes ContentState updates
// via LiveActivityManager.

import ActivityKit
import Foundation

struct LiveActivityAttributes: ActivityAttributes {
    public typealias LiveActivityStatus = ContentState

    // MARK: - ContentState

    struct ContentState: Codable, Hashable {
        /// Display unit string: "mg/dL" or "mmol/L"
        var unit: String
        /// Formatted blood glucose string, e.g. "142" (mg/dL) or "7.9" (mmol/L)
        var bg: String
        /// Trend direction arrow, e.g. "→", "↑↑". Nil when unavailable.
        var direction: String?
        /// Glucose delta string, e.g. "+5" or "-0.3"
        var change: String
        /// Timestamp of the last reading
        var date: Date
        /// High alert threshold in mg/dL (used for color calculation and chart rule mark)
        var highGlucose: Decimal
        /// Low alert threshold in mg/dL (used for color calculation and chart rule mark)
        var lowGlucose: Decimal
        /// Target glucose in mg/dL (used for chart rule mark and dynamic color midpoint)
        var target: Decimal
        /// Color scheme: "staticColor" (orange/red/green) or "dynamicColor" (hue-based rainbow)
        var glucoseColorScheme: String
        /// Whether to show the detailed view (chart + widget items) on iPhone lock screen
        var useDetailedViewIOS: Bool
        /// Whether to show the detailed view (chart) on Apple Watch
        var useDetailedViewWatchOS: Bool
        /// Additional data for the detailed view
        var detailedViewState: ContentAdditionalState
        /// True when the activity is freshly started and no real data has been pushed yet
        var isInitialState: Bool
    }

    // MARK: - ContentAdditionalState

    struct ContentAdditionalState: Codable, Hashable {
        /// Historical glucose readings for the trend chart
        var chart: [ChartItem]
        /// Chart rotation in degrees (reserved for future use)
        var rotationDegrees: Int
        /// Carbs on board in grams
        var cob: Int
        /// Insulin on board in units
        var iob: Double
        /// Total daily dose in units
        var tdd: Double
        /// Whether a loop override / temp target is currently active
        var isOverrideActive: Bool
        /// Display name of the active override
        var overrideName: String
        /// Start time of the active override (used to draw its range on the chart)
        var overrideDate: Date
        /// Duration of the active override in minutes
        var overrideDuration: Decimal
        /// Target glucose during the active override in mg/dL
        var overrideTarget: Decimal
        /// Ordered list of items to display in the detailed widget row
        var widgetItems: [LiveActivityItem]
    }

    // MARK: - ChartItem

    struct ChartItem: Codable, Hashable {
        /// Blood glucose value in mg/dL
        var value: Decimal
        /// Timestamp of this reading
        var date: Date
    }

    // MARK: - LiveActivityItem

    enum LiveActivityItem: String, Codable, Hashable, CaseIterable {
        case currentGlucose
        case currentGlucoseLarge
        case iob
        case cob
        case updatedLabel
        case totalDailyDose
        case empty

        /// Default set of items shown in the detailed widget row
        static var defaultItems: [LiveActivityItem] {
            [.currentGlucoseLarge, .iob, .cob, .updatedLabel]
        }
    }

    // MARK: - Static attributes

    /// The date when this Live Activity was started
    var startDate: Date
}
