// LoopFollow
// LiveActivityGlucoseDeltaLabelView.swift

import Foundation
import SwiftUI
import WidgetKit

struct LiveActivityGlucoseDeltaLabelView: View {
    var context: ActivityViewContext<LiveActivityAttributes>
    var glucoseColor: Color

    var body: some View {
        if !context.state.change.isEmpty {
            Text(context.state.change)
                .foregroundStyle(
                    context.isStale ? .secondary : context.state
                        .glucoseColorScheme == "staticColor" ? .primary : glucoseColor
                )
                .strikethrough(context.isStale, pattern: .solid, color: .red.opacity(0.6))
        } else {
            Text("--")
        }
    }
}
