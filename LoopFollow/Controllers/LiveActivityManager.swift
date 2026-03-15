// LoopFollow
// LiveActivityManager.swift

import ActivityKit
import Foundation

/// Manages the lifecycle (start / update / end) of the LoopFollow Live Activity.
///
/// Call `update(bgData:iob:cob:)` after each BG reading is processed.
/// The manager starts a new activity automatically if none is running.
/// Call `end()` when the user disables Live Activities in settings.
@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()

    /// The currently running activity, if any.
    private var activity: Activity<LiveActivityAttributes>?

    private init() {}

    // MARK: - Public API

    /// Update (or start) the Live Activity with the latest BG data.
    ///
    /// This is the main entry point. It is safe to call from a background thread;
    /// it dispatches UI-affecting work on the main queue internally.
    ///
    /// - Parameters:
    ///   - bgData: Full BG history array from MainViewController (oldest→newest).
    ///   - iob: Insulin on board in units, or nil if unavailable.
    ///   - cob: Carbs on board in grams, or nil if unavailable.
    func update(bgData: [ShareGlucoseData], iob: Double?, cob: Double?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let contentState = buildContentState(bgData: bgData, iob: iob, cob: cob)

        if let current = activity, current.activityState != .ended, current.activityState != .dismissed {
            // Update the running activity.
            Task {
                await current.update(using: contentState)
            }
        } else {
            // No live activity running — start a fresh one.
            start(with: contentState)
        }
    }

    /// End the Live Activity immediately (e.g. when the user disables it in Settings).
    func end() {
        guard let current = activity else { return }
        Task {
            await current.end(using: nil, dismissalPolicy: .immediate)
        }
        activity = nil
    }

    // MARK: - Private helpers

    private func start(with contentState: LiveActivityAttributes.ContentState) {
        let attributes = LiveActivityAttributes(startDate: Date())
        do {
            let newActivity = try Activity<LiveActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            activity = newActivity
        } catch {
            // Activity request failed — silently ignore (e.g. simulator, low-power mode).
        }
    }

    /// Build a ContentState from the current app state and the supplied BG data.
    private func buildContentState(
        bgData: [ShareGlucoseData],
        iob: Double?,
        cob: Double?
    ) -> LiveActivityAttributes.ContentState {
        let unit = Storage.shared.units.value // "mg/dL" or "mmol/L"
        let bg = Observable.shared.bgText.value

        // Direction: "→", "↑", etc. Observable stores "-" when unavailable.
        let rawDirection = Observable.shared.directionText.value
        let direction: String? = (rawDirection.isEmpty || rawDirection == "-") ? nil : rawDirection

        let change = Observable.shared.deltaText.value
        let highGlucose = Decimal(Storage.shared.highLine.value)
        let lowGlucose = Decimal(Storage.shared.lowLine.value)
        // Use 100 mg/dL as the default target (midpoint of typical range).
        let target = Decimal(100)
        let colorScheme = Storage.shared.liveActivityColorScheme.value
        let useDetailed = Storage.shared.liveActivityDetailedView.value

        // Timestamp of the most recent reading (bgData is oldest→newest).
        let readingDate: Date
        if let last = bgData.last {
            readingDate = Date(timeIntervalSince1970: last.date)
        } else {
            readingDate = Date()
        }

        // Build chart items: last 6 hours of readings (bgData is already filtered to
        // downloadDays by ProcessDexBGData, so we just take the last 6 hours).
        let sixHoursAgo = Date().addingTimeInterval(-6 * 60 * 60).timeIntervalSince1970
        let chartItems: [LiveActivityAttributes.ChartItem] = bgData
            .filter { $0.date >= sixHoursAgo }
            .map { LiveActivityAttributes.ChartItem(value: Decimal($0.sgv), date: Date(timeIntervalSince1970: $0.date)) }

        let additionalState = LiveActivityAttributes.ContentAdditionalState(
            chart: chartItems,
            rotationDegrees: 0,
            cob: Int(cob ?? 0),
            iob: iob ?? 0,
            tdd: 0,
            isOverrideActive: false,
            overrideName: "",
            overrideDate: Date(),
            overrideDuration: 0,
            overrideTarget: 0,
            widgetItems: LiveActivityAttributes.LiveActivityItem.defaultItems
        )

        return LiveActivityAttributes.ContentState(
            unit: unit,
            bg: bg,
            direction: direction,
            change: change,
            date: readingDate,
            highGlucose: highGlucose,
            lowGlucose: lowGlucose,
            target: target,
            glucoseColorScheme: colorScheme,
            useDetailedViewIOS: useDetailed,
            useDetailedViewWatchOS: useDetailed,
            detailedViewState: additionalState,
            isInitialState: false
        )
    }
}
