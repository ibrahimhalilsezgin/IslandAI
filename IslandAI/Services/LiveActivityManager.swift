import Foundation
import ActivityKit

public class LiveActivityManager: ObservableObject {
    @Published public var currentActivityId: String? = nil
    @Published public var isActivityActive: Bool = false

    public init() {}

    public func startActivity(assistantName: String = "Island AI") {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled.")
            return
        }

        let attributes = IslandAttributes(assistantName: assistantName)
        let initialContentState = IslandAttributes.ContentState(status: .idle, lastQuestion: "", lastAnswer: "")

        do {
            let activity: Activity<IslandAttributes>

            if #available(iOS 16.2, *) {
                let activityContent = ActivityContent(state: initialContentState, staleDate: nil)
                activity = try Activity.request(attributes: attributes, content: activityContent, pushType: nil)
            } else {
                // Fallback for iOS 16.0
                activity = try Activity.request(attributes: attributes, contentState: initialContentState, pushType: nil)
            }

            DispatchQueue.main.async {
                self.currentActivityId = activity.id
                self.isActivityActive = true
            }
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }

    public func updateActivity(status: AssistantStatus, question: String? = nil, answer: String? = nil) {
        guard let activityId = currentActivityId,
              let activity = Activity<IslandAttributes>.activities.first(where: { $0.id == activityId }) else {
            return
        }

        Task {
            var updatedState = activity.contentState
            updatedState.status = status

            if let q = question {
                updatedState.lastQuestion = q
            }

            if let a = answer {
                updatedState.lastAnswer = a
            }

            if #available(iOS 16.2, *) {
                let activityContent = ActivityContent(state: updatedState, staleDate: nil)
                await activity.update(activityContent)
            } else {
                await activity.update(using: updatedState)
            }
        }
    }

    public func endActivity() {
        guard let activityId = currentActivityId,
              let activity = Activity<IslandAttributes>.activities.first(where: { $0.id == activityId }) else {
            return
        }

        Task {
            let finalState = activity.contentState

            if #available(iOS 16.2, *) {
                let activityContent = ActivityContent(state: finalState, staleDate: nil)
                await activity.end(activityContent, dismissalPolicy: .immediate)
            } else {
                await activity.end(using: finalState, dismissalPolicy: .immediate)
            }

            DispatchQueue.main.async {
                self.currentActivityId = nil
                self.isActivityActive = false
            }
        }
    }
}
