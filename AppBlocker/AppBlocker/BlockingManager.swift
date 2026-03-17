import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

@MainActor
class BlockingManager: ObservableObject {

    // MARK: - Published State

    @Published var isAuthorized = false
    @Published var authorizationError: String?
    @Published var isBlocking = false
    @Published var selection = FamilyActivitySelection()
    @Published var scheduleEnabled = false
    @Published var scheduleStart = DateComponents(hour: 22, minute: 0)  // 10 PM
    @Published var scheduleEnd   = DateComponents(hour: 8,  minute: 0)  // 8 AM

    /// When true, the normal stop button is hidden — only a Claude-approved override can unblock.
    @Published var claudeOverrideRequired = false

    // MARK: - Private

    private let store   = ManagedSettingsStore()
    private let center  = AuthorizationCenter.shared
    private let activityCenter = DeviceActivityCenter()
    private let activityName   = DeviceActivityName("com.appblocker.daily")

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            authorizationError = error.localizedDescription
        }
    }

    // MARK: - Blocking

    /// Apply restrictions. Pass `requireClaudeOverride: true` to lock the stop button.
    func startBlocking(requireClaudeOverride: Bool = false) {
        guard !selection.applicationTokens.isEmpty ||
              !selection.categoryTokens.isEmpty else { return }

        store.shield.applications         = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty   ? nil : .specific(selection.categoryTokens)
        isBlocking = true
        claudeOverrideRequired = requireClaudeOverride
    }

    /// Remove all restrictions. Only callable directly when claudeOverrideRequired is false.
    func stopBlocking() {
        store.shield.applications          = nil
        store.shield.applicationCategories = nil
        isBlocking = false
        claudeOverrideRequired = false

        if scheduleEnabled {
            cancelSchedule()
        }
    }

    // MARK: - Scheduling

    /// Start blocking on a recurring daily schedule.
    func enableSchedule() {
        let schedule = DeviceActivitySchedule(
            intervalStart: scheduleStart,
            intervalEnd:   scheduleEnd,
            repeats:       true
        )

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories:   selection.categoryTokens,
            threshold:    DateComponents(minute: 0)
        )

        do {
            try activityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: [DeviceActivityEvent.Name("block"): event]
            )
            scheduleEnabled = true
        } catch {
            authorizationError = "Schedule error: \(error.localizedDescription)"
        }
    }

    func cancelSchedule() {
        activityCenter.stopMonitoring([activityName])
        scheduleEnabled = false
    }
}
