// LoopFollow
// LiveActivitySettingsView.swift

import SwiftUI

struct LiveActivitySettingsView: View {
    // MARK: - Storage bindings

    @ObservedObject private var liveActivityEnabled = Storage.shared.liveActivityEnabled
    @ObservedObject private var liveActivityDetailedView = Storage.shared.liveActivityDetailedView
    @ObservedObject private var liveActivityColorScheme = Storage.shared.liveActivityColorScheme

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // ───────── Enable ─────────
                Section {
                    Toggle("Enable Live Activity", isOn: $liveActivityEnabled.value)
                        .onChange(of: liveActivityEnabled.value) { enabled in
                            if !enabled {
                                LiveActivityManager.shared.end()
                            }
                        }
                } footer: {
                    Text(
                        "Shows blood glucose on the Lock Screen, Dynamic Island, and Apple Watch. " +
                            "The activity updates automatically with each new reading."
                    )
                }

                // ───────── Display options (visible only when enabled) ─────────
                if liveActivityEnabled.value {
                    Section {
                        Toggle("Detailed View", isOn: $liveActivityDetailedView.value)

                        Picker("Color Scheme", selection: $liveActivityColorScheme.value) {
                            Text("Static").tag("staticColor")
                            Text("Dynamic").tag("dynamicColor")
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Display")
                    } footer: {
                        Text(
                            "Detailed View adds a glucose trend chart plus IOB and COB. " +
                                "Static uses orange/red/green. Dynamic uses a hue-based rainbow."
                        )
                    }
                }
            }
            .navigationTitle("Live Activity")
        }
    }
}
