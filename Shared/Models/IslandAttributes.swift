import ActivityKit
import Foundation

public enum AssistantStatus: String, Codable, Hashable, CaseIterable {
    case idle
    case listening
    case thinking
    case speaking

    public var iconName: String {
        switch self {
        case .idle: return "mic.slash"
        case .listening: return "waveform"
        case .thinking: return "brain"
        case .speaking: return "speaker.wave.2"
        }
    }
}

public struct IslandAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var status: AssistantStatus
        public var lastQuestion: String
        public var lastAnswer: String

        public init(status: AssistantStatus = .idle, lastQuestion: String = "", lastAnswer: String = "") {
            self.status = status
            self.lastQuestion = lastQuestion
            self.lastAnswer = lastAnswer
        }
    }

    public var assistantName: String

    public init(assistantName: String = "Island AI") {
        self.assistantName = assistantName
    }
}
