// LoopFollow
// LiveActivityManager.swift

import ActivityKit
import Foundation
import UIKit

/// Manages the lifecycle (start / update / end) of the LoopFollow Live Activity.
///
/// Call `update(bgData:iob:cob:)` after each BG reading is processed.
/// The manager starts a new activity automatically if none is running.
/// Call `end()` when the user disables Live Activities in settings.
@available(iOS 16.2, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()

    /// The currently running activity, if any.
    private var activity: Activity<LiveActivityAttributes>?

    /// The time at which the current activity was started. Used to enforce
    /// a periodic recreation threshold so we never approach the 8-hour system
    /// expiry wall and lose the widget unexpectedly.
    private var activityStartDate: Date?

    /// Last-seen BG data, cached so app-transition force-updates can replay them.
    private var lastBGData: [ShareGlucoseData] = []
    private var lastIOB: Double?
    private var lastCOB: Double?

    private init() {
        // Recover any activity that was started before this process instance launched
        // (e.g. after iOS suspends and later resumes the app). Without this, the
        // existing activity on the Lock Screen becomes orphaned — still visible but
        // never updated again — because `activity` is nil and every call to `update()`
        // creates a brand-new activity instead of updating the existing one.
        activity = Activity<LiveActivityAttributes>.activities.first
        // Best-effort: treat the oldest known start date as the activity start so
        // the 1-hour recreation timer is approximately correct after process restart.
        activityStartDate = activity != nil ? Date() : nil

        // Force a widget refresh at app-lifecycle boundaries so the Lock Screen
        // always shows fresh data when the user picks up their phone.
        // Mirrors Trio's LiveActivityBridge behaviour.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in self?.forceUpdate() }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in self?.forceUpdate() }
    }

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

        // Cache for replaying on app-transition force-updates.
        lastBGData = bgData
        lastIOB = iob
        lastCOB = cob

        let contentState = buildContentState(bgData: bgData, iob: iob, cob: cob)

        // Recreate the activity after 1 hour to avoid silently approaching the
        // 8-hour system-imposed maximum lifetime. iOS does not warn the app before
        // killing a long-running activity; by recycling proactively we guarantee
        // at least 7 more hours of headroom at every recreation point.
        let needsRecreation: Bool
        if let startDate = activityStartDate {
            needsRecreation = Date().timeIntervalSince(startDate) >= 60 * 60
        } else {
            needsRecreation = false
        }

        if let current = activity,
           current.activityState != .ended,
           current.activityState != .dismissed,
           current.activityState != .stale,
           !needsRecreation {
            // Update the running activity.
            // Use the ActivityContent API (iOS 16.2+) with an explicit staleDate so iOS
            // knows when to mark the widget as stale. Without a staleDate the system has
            // no signal for when the reading is too old to display.
            // staleDate = reading timestamp + 6 minutes (one missed poll interval).
            Task {
                // End any orphaned duplicate activities that we no longer own. These can
                // accumulate when the app is killed and relaunched repeatedly — each launch
                // previously called Activity.request() without checking whether an activity
                // already existed, leaving stale entries in Activity.activities that are
                // still rendered on the Lock Screen. Removing them keeps the display clean.
                for orphan in Activity<LiveActivityAttributes>.activities where orphan.id != current.id {
                    await orphan.end(nil, dismissalPolicy: .immediate)
                }

                let content = ActivityContent(
                    state: contentState,
                    staleDate: contentState.date.addingTimeInterval(6 * 60)
                )
                await current.update(content)
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
        activityStartDate = nil
    }

    // MARK: - Private helpers

    /// Replay the last known BG state into the widget.
    ///
    /// Called at app-lifecycle boundaries (background / foreground) so the Lock
    /// Screen is refreshed at the moment the user is most likely to look at it,
    /// rather than waiting for the next poll cycle.
    private func forceUpdate() {
        guard !lastBGData.isEmpty else { return }
        update(bgData: lastBGData, iob: lastIOB, cob: lastCOB)
    }

    private func start(with contentState: LiveActivityAttributes.ContentState) {
        // End the old activity (if any) before starting a replacement so it
        // does not linger as an orphan on the Lock Screen.
        Task {
            if let old = activity {
                await old.end(nil, dismissalPolicy: .immediate)
            }
        }

        let attributes = LiveActivityAttributes(startDate: Date())
        do {
            let newActivity = try Activity<LiveActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            activity = newActivity
            activityStartDate = Date()
        } catch {
            // Activity request failed — silently ignore (e.g. simulator, low-power mode).
            activityStartDate = nil
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
