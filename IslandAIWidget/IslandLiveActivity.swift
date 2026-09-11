import WidgetKit
import SwiftUI
import ActivityKit

struct IslandLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IslandAttributes.self) { context in
            // Lock screen / Banner presentation
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status.iconName)
                        .font(.title2)
                        .foregroundColor(statusColor(for: context.state.status))
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(statusText(for: context.state.status))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        if !context.state.lastQuestion.isEmpty {
                            Text("Q: \(context.state.lastQuestion)")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        if !context.state.lastAnswer.isEmpty {
                            Text(context.state.lastAnswer)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.horizontal)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Quick Action: Link to islandai://record to immediately talk
                    Link(destination: URL(string: "islandai://record")!) {
                        Label("Konuş", systemImage: "mic.fill")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 8)
                }
            } compactLeading: {
                // Compact leading view (e.g. Brain / Mic icon with status color)
                Image(systemName: context.state.status.iconName)
                    .foregroundColor(statusColor(for: context.state.status))
                    .padding(.leading, 4)
            } compactTrailing: {
                // Compact trailing view (e.g. waveform or state text)
                Text(statusText(for: context.state.status))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 4)
            } minimal: {
                // Minimal view (e.g. small pulsing brain/dot)
                Image(systemName: context.state.status.iconName)
                    .foregroundColor(statusColor(for: context.state.status))
            }
        }
    }

    private func statusColor(for status: AssistantStatus) -> Color {
        switch status {
        case .idle: return .gray
        case .listening: return .red
        case .thinking: return .purple
        case .speaking: return .blue
        }
    }

    private func statusText(for status: AssistantStatus) -> String {
        switch status {
        case .idle: return "Hazır"
        case .listening: return "Dinliyor..."
        case .thinking: return "Düşünüyor..."
        case .speaking: return "Konuşuyor"
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<IslandAttributes>

    var body: some View {
        VStack {
            HStack {
                Image(systemName: context.state.status.iconName)
                    .foregroundColor(statusColor(for: context.state.status))
                Text(context.attributes.assistantName)
                    .font(.headline)
                Spacer()
                Text(statusText(for: context.state.status))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)

            if !context.state.lastQuestion.isEmpty {
                HStack {
                    Text("Sen:")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text(context.state.lastQuestion)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                }
            }

            if !context.state.lastAnswer.isEmpty {
                HStack {
                    Text("AI:")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text(context.state.lastAnswer)
                        .font(.caption)
                        .lineLimit(2)
                    Spacer()
                }
            }
        }
        .padding()
        // Lock screen widget UI should have clear presentation. ActivityKit wraps it.
    }

    private func statusColor(for status: AssistantStatus) -> Color {
        switch status {
        case .idle: return .gray
        case .listening: return .red
        case .thinking: return .purple
        case .speaking: return .blue
        }
    }

    private func statusText(for status: AssistantStatus) -> String {
        switch status {
        case .idle: return "Hazır"
        case .listening: return "Dinliyor..."
        case .thinking: return "Düşünüyor..."
        case .speaking: return "Konuşuyor"
        }
    }
}