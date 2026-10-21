import ActivityKit
import Foundation
import Observation
import SwiftUI

/// Starts, updates and ends the Island Neon Live Activity.
///
/// Colour "animation" in a Live Activity can only happen one update at a time: each call to
/// `Activity.update` ships a new `ContentState` with the next keyline colour. The cycling loop
/// here runs while the app is in the foreground; once iOS suspends the app no further updates
/// are sent. That is a platform limit, not a bug. Background updates would require ActivityKit
/// push notifications from a server and would draw on the same per-day update budget.
@MainActor
@Observable
final class NeonActivityManager {
    private(set) var activity: Activity<NeonActivityAttributes>?
    private(set) var currentState: NeonActivityAttributes.ContentState?
    private(set) var isCycling = false
    private(set) var updateCount = 0
    private(set) var lastError: String?
    private(set) var isInForeground = true

    @ObservationIgnored private var cycleTask: Task<Void, Never>?
    @ObservationIgnored private var stateTask: Task<Void, Never>?
    @ObservationIgnored private var nextStep = 1

    /// Eight hours: the maximum lifetime iOS allows a Live Activity.
    private static let maxLifetime: TimeInterval = 8 * 60 * 60

    init() {
        adoptExistingActivity()
    }

    var isRunning: Bool {
        activity != nil
    }

    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Whether the user has allowed the larger "frequent updates" allowance.
    var frequentUpdatesEnabled: Bool {
        ActivityAuthorizationInfo().frequentPushesEnabled
    }

    // MARK: Lifecycle

    /// Re-attaches to an activity that survived an app relaunch.
    func adoptExistingActivity() {
        guard activity == nil, let existing = Activity<NeonActivityAttributes>.activities.first else { return }
        attach(existing)
    }

    func start(config: NeonConfig) {
        guard areActivitiesEnabled else {
            lastError = "Live Activities are turned off for Island Neon in Settings."
            return
        }

        if let running = activity {
            // Only one activity at a time; end the previous one cleanly.
            Task { await end(running) }
            activity = nil
        }

        let attributes = NeonActivityAttributes(title: "Island Neon", startedAt: .now)
        let state = makeState(config: config, step: 0)
        let content = ActivityContent(state: state, staleDate: Date.now.addingTimeInterval(Self.maxLifetime))

        do {
            let started = try Activity.request(attributes: attributes, content: content, pushType: nil)
            attach(started)
            currentState = state
            updateCount = 0
            nextStep = 1
            lastError = nil
            startCycling(config: config)
        } catch {
            lastError = "Could not start the Live Activity: \(error.localizedDescription)"
        }
    }

    func stop() {
        stopCycling()
        stateTask?.cancel()
        stateTask = nil
        guard let running = activity else { return }
        activity = nil
        currentState = nil
        Task { await end(running) }
    }

    // MARK: Updates

    /// Sends the next colour of the loop immediately.
    func sendNextStep(config: NeonConfig) {
        Task { await sendStep(config: config) }
    }

    /// Repeatedly sends the next colour every `config.activityUpdateInterval` seconds.
    func startCycling(config: NeonConfig) {
        cycleTask?.cancel()
        guard activity != nil else { return }
        isCycling = true
        let interval = max(2, config.activityUpdateInterval)

        cycleTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled, let self, self.activity != nil else { break }
                await self.sendStep(config: config)
            }
            self?.isCycling = false
        }
    }

    func stopCycling() {
        cycleTask?.cancel()
        cycleTask = nil
        isCycling = false
    }

    func scenePhaseChanged(_ phase: ScenePhase) {
        isInForeground = phase == .active
    }

    // MARK: Private

    private func sendStep(config: NeonConfig) async {
        guard let running = activity else { return }
        let steps = max(2, config.activityStepsPerLoop)
        let state = makeState(config: config, step: nextStep % steps)
        let content = ActivityContent(state: state, staleDate: Date.now.addingTimeInterval(Self.maxLifetime))
        await running.update(content)
        currentState = state
        updateCount += 1
        nextStep = (nextStep + 1) % steps
    }

    private func makeState(config: NeonConfig, step: Int) -> NeonActivityAttributes.ContentState {
        let steps = max(2, config.activityStepsPerLoop)
        let phase = Double(step % steps) / Double(steps)
        return NeonActivityAttributes.ContentState(
            keyline: config.mode.color(at: phase).scaled(brightness: config.brightness),
            modeID: config.mode.rawValue,
            step: step % steps,
            stepsPerLoop: steps,
            brightness: config.brightness
        )
    }

    private func attach(_ running: Activity<NeonActivityAttributes>) {
        activity = running
        currentState = running.content.state
        nextStep = (running.content.state.step + 1) % max(2, running.content.state.stepsPerLoop)

        stateTask?.cancel()
        stateTask = Task { [weak self] in
            for await state in running.activityStateUpdates {
                guard let self else { return }
                if state == .ended || state == .dismissed {
                    // Ended by the system (8-hour cap) or dismissed by the user.
                    if self.activity?.id == running.id {
                        self.stopCycling()
                        self.activity = nil
                        self.currentState = nil
                    }
                    return
                }
            }
        }
    }

    private func end(_ running: Activity<NeonActivityAttributes>) async {
        let finalContent = ActivityContent(state: running.content.state, staleDate: nil)
        await running.end(finalContent, dismissalPolicy: .immediate)
    }
}
