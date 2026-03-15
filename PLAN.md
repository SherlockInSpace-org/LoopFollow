# Plan: LiveActivity Widget for LoopFollow

## Background

The `LiveActivity/` folder at the project root is a **reference copy** of the Trio app's LiveActivity widget. It documents how Trio implements its Live Activity and serves as the blueprint — but its files will **not** be used directly as build inputs. Instead, all files will be copied and placed into the proper LoopFollow structure before the widget can be compiled or used.

---

## Repository Structure Convention

The existing top-level layout is:
```
LoopFollow/          ← main app source (one folder per target)
Tests/               ← test target source
Pods/                ← CocoaPods (generated)
LoopFollow.xcodeproj/
```

Each Xcode target has its own top-level folder. The new extension target will follow this pattern exactly.

Inside `LoopFollow/` (the main app folder), code is organized by domain:
```
LoopFollow/
├── Application/        ← AppDelegate, SceneDelegate
├── Controllers/        ← business logic controllers and managers
│   └── Nightscout/     ← Nightscout-specific controllers
├── Settings/           ← SwiftUI settings views (+ ViewModels where needed)
├── Storage/            ← Storage.swift, Observable.swift, migration
├── Helpers/            ← AppConstants and other utilities
└── ...
```

New files added to the main app will follow this same structure.

---

## Current State Analysis

### What the `LiveActivity/` reference provides
The reference folder contains the complete Trio widget UI:

| Reference file | Purpose |
|----------------|---------|
| `LiveActivityBundle.swift` | `@main` extension entry point |
| `LiveActivity.swift` | `ActivityConfiguration` with Dynamic Island (compact / minimal / expanded) and iOS 18 Apple Watch support |
| `LiveActivity+Helper.swift` | `GlucoseUnits`, `GlucoseColorScheme`, `Color.getDynamicGlucoseColor()`, `bgAndTrend()`, `isWatchOS` environment key, `LiveActivityModifiers` |
| `Views/LiveActivityView.swift` | Root lock-screen layout (simple or detailed) plus all Dynamic Island sub-views |
| `Views/LiveActivityChartView.swift` | 6-hour Apple Charts glucose history |
| `Views/LiveActivityGlucoseDeltaLabelView.swift` | Delta label |
| `Views/LiveActivityBGAndTrendView.swift` | BG + trend arrow |
| `Views/WidgetItems/LiveActivityBGLabelView.swift` | BG label (small) |
| `Views/WidgetItems/LiveActivityBGLabelLargeView.swift` | BG + trend (large) |
| `Views/WidgetItems/LiveActivityBGLabelWatchView.swift` | Compact Watch layout |
| `Views/WidgetItems/LiveActivityIOBLabelView.swift` | IOB item |
| `Views/WidgetItems/LiveActivityCOBLabelView.swift` | COB item |
| `Views/WidgetItems/LiveActivityTotalDailyDoseView.swift` | TDD item |
| `Views/WidgetItems/LiveActivityUpdatedLabelView.swift` | Last-updated time item |
| `WidgetBobble 2.swift` | Decorative bobble element |
| `Assets.xcassets/` | App icon, accent color, widget background, reservoir images |
| `Info.plist` | Extension point identifier (`com.apple.widgetkit-extension`) |

### What is missing from the reference (must be created)
1. **`LiveActivityAttributes` struct** — defined only in the main Trio app, absent from the reference. Every view references this type; it must be created for LoopFollow.
2. **`LiveActivityManager`** — code in the main app to start, update, and end the Live Activity.
3. **Xcode target** — the extension must be registered in `LoopFollow.xcodeproj/project.pbxproj`.
4. **Main app `Info.plist` key** — `NSSupportsLiveActivities` must be added.
5. **Settings storage + UI** — user-facing enable/disable and configuration.

### What LoopFollow already has that the widget needs

| Data | Source in LoopFollow |
|------|----------------------|
| Current BG string | `Observable.shared.bgText.value` |
| Raw BG integer | `Observable.shared.bg.value` |
| Direction / trend arrow | `Observable.shared.directionText.value` |
| Delta string | `Observable.shared.deltaText.value` |
| Data stale flag | `Observable.shared.bgStale.value` |
| BG history array | `MainViewController.bgData: [ShareGlucoseData]` |
| Last reading timestamp | `bgData.last?.date` (Unix seconds) |
| Low threshold | `Storage.shared.lowLine.value` (Double, mg/dL) |
| High threshold | `Storage.shared.highLine.value` (Double, mg/dL) |
| mmol/L flag | `Storage.shared.useIFCC.value` |
| IOB | `MainViewController.latestIOB: InsulinMetric?` (from Nightscout devicestatus) |
| COB | `MainViewController.latestCOB: CarbMetric?` (from Nightscout devicestatus) |
| App Group ID | `group.com.$(unique_id).LoopFollow$(app_suffix)` |
| URL scheme | `loopfollow` (registered in `LoopFollow/Info.plist` CFBundleURLSchemes) |

> **Note on TDD and Overrides**: LoopFollow does not currently surface TDD or closed-loop override state. Those widget fields default to `0` / `false`; the widget handles them gracefully. They can be wired to Nightscout data in a follow-up.

---

## Target Folder Structure

The new extension will live in `LoopFollowLiveActivity/` at the project root, mirroring how `LoopFollow/` and `Tests/` are organized:

```
LoopFollowLiveActivity/               ← new extension target folder
├── LiveActivityAttributes.swift      ← NEW: shared data model (also added to main app target)
├── LiveActivityBundle.swift          ← copied from reference; no changes
├── LiveActivity.swift                ← copied from reference; 1 change (URL scheme)
├── LiveActivity+Helper.swift         ← copied from reference; no changes
├── LiveActivityWidgetBobble.swift    ← copied + renamed from "WidgetBobble 2.swift"
├── Views/
│   ├── LiveActivityView.swift        ← copied; 2 string changes (app name)
│   ├── LiveActivityChartView.swift   ← copied; no changes
│   ├── LiveActivityGlucoseDeltaLabelView.swift  ← copied; no changes
│   ├── LiveActivityBGAndTrendView.swift          ← copied; no changes
│   └── WidgetItems/
│       ├── LiveActivityBGLabelView.swift          ← copied; no changes
│       ├── LiveActivityBGLabelLargeView.swift     ← copied; no changes
│       ├── LiveActivityBGLabelWatchView.swift     ← copied; no changes
│       ├── LiveActivityIOBLabelView.swift         ← copied; no changes
│       ├── LiveActivityCOBLabelView.swift         ← copied; no changes
│       ├── LiveActivityTotalDailyDoseView.swift   ← copied; no changes
│       └── LiveActivityUpdatedLabelView.swift     ← copied; no changes
├── Assets.xcassets/                  ← copied from reference; no changes
├── Info.plist                        ← copied from reference; no changes
└── LoopFollowLiveActivity.entitlements  ← NEW

LoopFollow/                           ← main app (existing, additions only)
├── Controllers/
│   └── LiveActivityManager.swift     ← NEW
├── Settings/
│   └── LiveActivitySettingsView.swift ← NEW
├── Storage/
│   └── Storage.swift                 ← MODIFIED (3 new StorageValue properties)
├── Info.plist                        ← MODIFIED (NSSupportsLiveActivities)
└── Controllers/Nightscout/BGData.swift ← MODIFIED (trigger update after each reading)
```

---

## Step-by-Step Implementation Plan

### Step 1 — Create the extension folder and copy all view files

Create `LoopFollowLiveActivity/` at the project root. Copy every file from the `LiveActivity/` reference into the corresponding path under `LoopFollowLiveActivity/`, renaming `WidgetBobble 2.swift` to `LiveActivityWidgetBobble.swift` (removes the space and disambiguates from the reference).

At this point the files exist on disk but are not yet part of any Xcode target.

---

### Step 2 — Create `LiveActivityAttributes.swift`

**New file**: `LoopFollowLiveActivity/LiveActivityAttributes.swift`

This file must be compiled into **both** the main `LoopFollow` target and the `LoopFollowLiveActivity` extension target — it is the only file shared between them.

Full struct definition matching what all the view files expect:

```swift
// LoopFollow
// LiveActivityAttributes.swift

import ActivityKit
import Foundation

struct LiveActivityAttributes: ActivityAttributes {
    public typealias LiveActivityStatus = ContentState

    struct ContentState: Codable, Hashable {
        var unit: String             // "mg/dL" or "mmol/L"
        var bg: String               // formatted BG string, e.g. "142" or "7.9"
        var direction: String?       // trend arrow, e.g. "→", "↑↑", nil when unavailable
        var change: String           // delta string, e.g. "+5" or "-0.3"
        var date: Date               // timestamp of the last reading
        var highGlucose: Decimal     // high alert threshold in mg/dL
        var lowGlucose: Decimal      // low alert threshold in mg/dL
        var target: Decimal          // target glucose in mg/dL
        var glucoseColorScheme: String   // "staticColor" or "dynamicColor"
        var useDetailedViewIOS: Bool
        var useDetailedViewWatchOS: Bool
        var detailedViewState: ContentAdditionalState
        var isInitialState: Bool
    }

    struct ContentAdditionalState: Codable, Hashable {
        var chart: [ChartItem]
        var rotationDegrees: Int
        var cob: Int
        var iob: Double
        var tdd: Double
        var isOverrideActive: Bool
        var overrideName: String
        var overrideDate: Date
        var overrideDuration: Decimal
        var overrideTarget: Decimal
        var widgetItems: [LiveActivityItem]
    }

    struct ChartItem: Codable, Hashable {
        var value: Decimal
        var date: Date
    }

    enum LiveActivityItem: String, Codable, Hashable, CaseIterable {
        case currentGlucose
        case currentGlucoseLarge
        case iob
        case cob
        case updatedLabel
        case totalDailyDose
        case empty

        static var defaultItems: [LiveActivityItem] {
            [.currentGlucoseLarge, .iob, .cob, .updatedLabel]
        }
    }

    var startDate: Date
}
```

---

### Step 3 — Apply the two changes to the copied view files

These are the only content changes required to the Trio view code:

**`LoopFollowLiveActivity/LiveActivity.swift`** — change the widget tap URL:
```swift
// Before:
.widgetURL(URL(string: "Trio://"))
// After:
.widgetURL(URL(string: "loopfollow://"))
```

**`LoopFollowLiveActivity/Views/LiveActivityView.swift`** — two occurrences of the expiry message:
```swift
// Before (in both the lock-screen body and LiveActivityExpandedBottomView):
Text("Live Activity Expired. Open Trio to Refresh")
// After:
Text("Live Activity Expired. Open LoopFollow to Refresh")
```

No other files from the reference require content changes.

---

### Step 4 — Create `LiveActivityManager.swift`

**New file**: `LoopFollow/Controllers/LiveActivityManager.swift`

Following the pattern of `LoopFollow/Controllers/BackgroundAlertManager.swift`, this is a singleton class that owns the Live Activity lifecycle.

Responsibilities:
- Check `ActivityAuthorizationInfo().areActivitiesEnabled` before attempting to start
- Maintain a reference to the running `Activity<LiveActivityAttributes>`
- Expose `update(bgData:iob:cob:)` — builds a new `ContentState` and calls `Activity.update(using:)`; starts a new activity first if none is running
- Expose `end()` — calls `activity.end(dismissalPolicy: .immediate)`
- Rebuild `ContentState` from the data available in `Observable.shared`, `Storage.shared`, and the passed-in parameters

**Data mapping** inside `buildContentState`:

| `ContentState` field | LoopFollow source |
|----------------------|-------------------|
| `unit` | `Storage.shared.useIFCC.value ? "mmol/L" : "mg/dL"` |
| `bg` | `Observable.shared.bgText.value` |
| `direction` | `Observable.shared.directionText.value` (nil if "–") |
| `change` | `Observable.shared.deltaText.value` |
| `date` | `Date(timeIntervalSince1970: bgData.last?.date ?? ...)` |
| `highGlucose` | `Decimal(Storage.shared.highLine.value)` |
| `lowGlucose` | `Decimal(Storage.shared.lowLine.value)` |
| `target` | `Decimal(100)` (hardcoded initially; configurable later) |
| `glucoseColorScheme` | `Storage.shared.liveActivityColorScheme.value` |
| `useDetailedViewIOS` | `Storage.shared.liveActivityDetailedView.value` |
| `useDetailedViewWatchOS` | `Storage.shared.liveActivityDetailedView.value` |
| `chart` | last 6 hours of `bgData` mapped to `[ChartItem(value:date:)]` |
| `iob` | `iob ?? 0` |
| `cob` | `Int(cob ?? 0)` |
| `tdd` | `0.0` (placeholder) |
| `isOverrideActive` | `false` (placeholder) |
| override fields | zero / empty defaults |
| `widgetItems` | `LiveActivityItem.defaultItems` |
| `isInitialState` | `false` |

---

### Step 5 — Add settings storage keys

**Modify**: `LoopFollow/Storage/Storage.swift`

Add three new `StorageValue` properties alongside the existing general display settings:

```swift
// Live Activity [BEGIN]
var liveActivityEnabled      = StorageValue<Bool>(key: "liveActivityEnabled",      defaultValue: false)
var liveActivityDetailedView = StorageValue<Bool>(key: "liveActivityDetailedView", defaultValue: false)
var liveActivityColorScheme  = StorageValue<String>(key: "liveActivityColorScheme", defaultValue: "staticColor")
// Live Activity [END]
```

---

### Step 6 — Create `LiveActivitySettingsView.swift`

**New file**: `LoopFollow/Settings/LiveActivitySettingsView.swift`

Following the pattern of `LoopFollow/Settings/CalendarSettingsView.swift` (a self-contained SwiftUI Form view), this file provides the Live Activity settings page:

```
LiveActivitySettingsView (NavigationView > Form)
└── Section("Live Activity")
    ├── Toggle "Enable Live Activity"   → Storage.shared.liveActivityEnabled
    ├── Toggle "Detailed View"          → Storage.shared.liveActivityDetailedView  [shown only when enabled]
    └── Picker "Color Scheme"           → Storage.shared.liveActivityColorScheme
            ├── "Static"   (value: "staticColor")
            └── "Dynamic"  (value: "dynamicColor")
```

When the enable toggle is turned off, call `LiveActivityManager.shared.end()`.

Then **add a navigation link** to `LiveActivitySettingsView` from `LoopFollow/Settings/SettingsMenuView.swift`, following the same pattern as existing settings entries.

---

### Step 7 — Hook into the BG update flow

**Modify**: `LoopFollow/Controllers/Nightscout/BGData.swift`

At the end of `ProcessDexBGData(data:sourceName:)`, after the main app UI has been updated, add:

```swift
if Storage.shared.liveActivityEnabled.value {
    LiveActivityManager.shared.update(
        bgData: data,
        iob: latestIOB?.value,
        cob: latestCOB?.value
    )
}
```

`LiveActivityManager.update` will call `start()` internally if no activity is currently running.

---

### Step 8 — Add `NSSupportsLiveActivities` to the main app `Info.plist`

**Modify**: `LoopFollow/Info.plist`

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

This key is required for any app that starts Live Activities.

---

### Step 9 — Create the extension entitlements file

**New file**: `LoopFollowLiveActivity/LoopFollowLiveActivity.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.$(unique_id).LoopFollow$(app_suffix)</string>
    </array>
</dict>
</plist>
```

---

### Step 10 — Xcode project integration

This is the most mechanical step. `LoopFollow.xcodeproj/project.pbxproj` must be edited to register the new extension. All required changes:

#### 10a. New target: `LoopFollowLiveActivity`
- `productType`: `com.apple.product-type.app-extension`
- `productName`: `LoopFollowLiveActivity`
- `PRODUCT_BUNDLE_IDENTIFIER`: `com.$(unique_id).LoopFollow$(app_suffix).LiveActivity`
- `DEVELOPMENT_TEAM`: `$(LF_DEVELOPMENT_TEAM)` (inherits from xcconfig)
- `IPHONEOS_DEPLOYMENT_TARGET`: `16.1` (minimum iOS version for ActivityKit)
- `SWIFT_VERSION`: same as main target
- `INFOPLIST_FILE`: `LoopFollowLiveActivity/Info.plist`
- `CODE_SIGN_ENTITLEMENTS`: `LoopFollowLiveActivity/LoopFollowLiveActivity.entitlements`
- `SKIP_INSTALL`: `YES`

#### 10b. Sources build phase for `LoopFollowLiveActivity`
All Swift files in `LoopFollowLiveActivity/`:
- `LiveActivityAttributes.swift`
- `LiveActivityBundle.swift`
- `LiveActivity.swift`
- `LiveActivity+Helper.swift`
- `LiveActivityWidgetBobble.swift`
- `Views/LiveActivityView.swift`
- `Views/LiveActivityChartView.swift`
- `Views/LiveActivityGlucoseDeltaLabelView.swift`
- `Views/LiveActivityBGAndTrendView.swift`
- `Views/WidgetItems/LiveActivityBGLabelView.swift`
- `Views/WidgetItems/LiveActivityBGLabelLargeView.swift`
- `Views/WidgetItems/LiveActivityBGLabelWatchView.swift`
- `Views/WidgetItems/LiveActivityIOBLabelView.swift`
- `Views/WidgetItems/LiveActivityCOBLabelView.swift`
- `Views/WidgetItems/LiveActivityTotalDailyDoseView.swift`
- `Views/WidgetItems/LiveActivityUpdatedLabelView.swift`

#### 10c. Add `LiveActivityAttributes.swift` to the main app Sources build phase
`LoopFollowLiveActivity/LiveActivityAttributes.swift` must also appear in the `LoopFollow` target's Sources build phase so the main app can construct and push `ContentState` updates.

#### 10d. Resources build phase for `LoopFollowLiveActivity`
- `LoopFollowLiveActivity/Assets.xcassets`

#### 10e. Frameworks build phase for `LoopFollowLiveActivity`
Frameworks to link:
- `ActivityKit.framework`
- `WidgetKit.framework`
- `SwiftUI.framework`
- `Charts.framework` (used by `LiveActivityChartView`)

The main `LoopFollow` target needs `ActivityKit.framework` linked if not already present.

#### 10f. Embed the extension in the main app
Add an `Embed App Extensions` build phase to the `LoopFollow` target (if it does not already have one) that embeds `LoopFollowLiveActivity.appex` with Code Sign On Copy enabled.

#### 10g. App Groups capability on both targets
Both `LoopFollow` and `LoopFollowLiveActivity` need the App Groups entitlement:
`group.com.$(unique_id).LoopFollow$(app_suffix)`

The main app entitlement file (`Loop Follow.entitlements`) will need this added.

---

## Complete File Inventory

### New files to create
| Path | Target(s) |
|------|-----------|
| `LoopFollowLiveActivity/LiveActivityAttributes.swift` | Main app + Extension |
| `LoopFollowLiveActivity/LiveActivityBundle.swift` | Extension |
| `LoopFollowLiveActivity/LiveActivity.swift` | Extension |
| `LoopFollowLiveActivity/LiveActivity+Helper.swift` | Extension |
| `LoopFollowLiveActivity/LiveActivityWidgetBobble.swift` | Extension |
| `LoopFollowLiveActivity/Views/LiveActivityView.swift` | Extension |
| `LoopFollowLiveActivity/Views/LiveActivityChartView.swift` | Extension |
| `LoopFollowLiveActivity/Views/LiveActivityGlucoseDeltaLabelView.swift` | Extension |
| `LoopFollowLiveActivity/Views/LiveActivityBGAndTrendView.swift` | Extension |
| `LoopFollowLiveActivity/Views/WidgetItems/LiveActivityBGLabelView.swift` | Extension |
| `LoopFollowLiveActivity/Views/WidgetItems/LiveActivityBGLabelLargeView.swift` | Extension |
| `LoopFollowLiveActivity/Views/WidgetItems/LiveActivityBGLabelWatchView.swift` | Extension |
| `LoopFollowLiveActivity/Views/WidgetItems/LiveActivityIOBLabelView.swift` | Extension |
| `LoopFollowLiveActivity/Views/WidgetItems/LiveActivityCOBLabelView.swift` | Extension |
| `LoopFollowLiveActivity/Views/WidgetItems/LiveActivityTotalDailyDoseView.swift` | Extension |
| `LoopFollowLiveActivity/Views/WidgetItems/LiveActivityUpdatedLabelView.swift` | Extension |
| `LoopFollowLiveActivity/Assets.xcassets/` | Extension |
| `LoopFollowLiveActivity/Info.plist` | Extension |
| `LoopFollowLiveActivity/LoopFollowLiveActivity.entitlements` | Extension |
| `LoopFollow/Controllers/LiveActivityManager.swift` | Main app |
| `LoopFollow/Settings/LiveActivitySettingsView.swift` | Main app |

### Files to modify
| Path | Change |
|------|--------|
| `LoopFollow/Info.plist` | Add `NSSupportsLiveActivities = true` |
| `LoopFollow/Storage/Storage.swift` | Add 3 `StorageValue` properties |
| `LoopFollow/Settings/SettingsMenuView.swift` | Add navigation link to `LiveActivitySettingsView` |
| `LoopFollow/Controllers/Nightscout/BGData.swift` | Call `LiveActivityManager.shared.update()` in `ProcessDexBGData` |
| `LoopFollow.xcodeproj/project.pbxproj` | Register new extension target (Step 10) |
| `LoopFollow/Loop Follow.entitlements` | Add App Groups entry |

### Reference folder (read-only, not compiled)
`LiveActivity/` — used only as source material for copying into `LoopFollowLiveActivity/`.

---

## Key Constraints and Notes

1. **iOS deployment target for extension**: ActivityKit requires iOS 16.1+. The extension must declare `IPHONEOS_DEPLOYMENT_TARGET = 16.1`. Apple Watch support via supplemental activity families requires iOS 18+ and is already guarded with `if #available(iOS 18.0, *)` in the widget code.

2. **`LiveActivityAttributes` shared via dual-target membership**: A single file added to two targets is the simplest approach that avoids introducing a shared framework dependency.

3. **`NSSupportsLiveActivities` entitlement**: Apple grants the underlying `com.apple.developer.live-activity` entitlement automatically to any app with a WidgetKit extension using `NSExtensionPointIdentifier = com.apple.widgetkit-extension`. No explicit entitlement key is needed beyond `NSSupportsLiveActivities` in the main app `Info.plist`.

4. **No new background mode needed**: LoopFollow already has background fetch and audio keep-alive. `Activity.update(using:)` is safe to call from background threads.

5. **TDD and Override fields**: Default to `0.0` / `false`. The widget renders "0 U / TDD" gracefully. These can be connected to Nightscout data in a follow-up (LoopFollow already fetches device status where TDD can sometimes be found).

6. **`AppConstants.APP_GROUP_ID`** currently uses `"group.com.$(unique_id).LoopFollow"` (without `$(app_suffix)`). The widget pushes all state via `Activity.update` and does not read from the App Group directly, so this inconsistency does not affect the widget at this stage.

7. **`WidgetBobble 2.swift` rename**: The filename with a space and trailing `2` is non-standard. Renaming to `LiveActivityWidgetBobble.swift` aligns with LoopFollow's PascalCase file naming and eliminates the need to quote the filename in build settings.
