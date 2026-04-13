import Foundation
import Combine

#if os(iOS)
import FamilyControls
import ManagedSettings
import DeviceActivity
#endif

#if os(macOS)
import AppKit
#endif

// MARK: - Supporting Models

struct EarnTask: Identifiable, Codable {
    var id = UUID()
    var name: String
    var taskDescription: String
    var minutesEarned: Int
}

struct AlwaysFreeApp: Identifiable, Codable {
    var id = UUID()
    var name: String
    var bundleIdentifier: String
}

// MARK: - BlockingManager

@MainActor
class BlockingManager: ObservableObject {

    // MARK: - Shared State

    @Published var isAuthorized = false
    @Published var authorizationError: String?
    @Published var isBlocking = false
    @Published var claudeOverrideRequired = false
    @Published var scheduleEnabled = false
    @Published var scheduleStart = DateComponents(hour: 22, minute: 0)
    @Published var scheduleEnd   = DateComponents(hour: 8,  minute: 0)

    // MARK: - iOS-only State

    #if os(iOS)
    @Published var selection = FamilyActivitySelection()
    @Published var alwaysFreeSelection = FamilyActivitySelection()
    private let store          = ManagedSettingsStore()
    private let center         = AuthorizationCenter.shared
    private let activityCenter = DeviceActivityCenter()
    private let activityName   = DeviceActivityName("com.appblocker.daily")
    #endif

    // MARK: - macOS-only State

    #if os(macOS)
    @Published var blockedBundleIDs: Set<String> = []
    private var workspaceObserver: NSObjectProtocol?
    private var macOSBlackoutObserver: NSObjectProtocol?
    private var periodicTimer: Timer?
    #endif

    // MARK: - Earn System

    @Published var earnTasks: [EarnTask] = [] {
        didSet { saveEarnTasks() }
    }
    @Published var earnedMinutesRemaining: Int = 0
    @Published var earnSessionActive: Bool = false
    private var earnTimer: Timer?
    private var earnedMinutesPausedDuringBlackout: Int = 0

    // MARK: - Travel Access

    @Published var travelUsesPerMonth: Int = 3
    @Published var travelMaxHoursPerUse: Int = 8
    @Published var travelUsesUsedThisMonth: Int = 0
    @Published var travelSessionActive: Bool = false
    @Published var travelSessionEndsAt: Date?
    private var travelTimer: Timer?

    // MARK: - Sick Day

    @Published var sickDaysPerMonth: Int = 3
    @Published var sickDaysUsedThisMonth: Int = 0
    @Published var sickDaySessionActive: Bool = false
    @Published var sickDaySessionEndsAt: Date?
    private var sickDayTimer: Timer?

    // MARK: - Blackout

    @Published var blackoutEnabled: Bool = false
    @Published var blackoutStart = DateComponents(hour: 21, minute: 0)  // 9 PM
    @Published var blackoutEnd   = DateComponents(hour: 8,  minute: 0)  // 8 AM
    @Published var isInBlackout: Bool = false
    @Published var alwaysFreeApps: [AlwaysFreeApp] = [] {
        didSet { saveAlwaysFreeApps() }
    }

    // MARK: - Computed Properties

    var selectedAppCount: Int {
        #if os(iOS)
        return selection.applicationTokens.count + selection.categoryTokens.count
        #elseif os(macOS)
        return blockedBundleIDs.count
        #endif
    }

    var canEarn: Bool { !isInBlackout }

    var travelUsesRemaining: Int { max(0, travelUsesPerMonth - travelUsesUsedThisMonth) }

    var sickDaysRemaining: Int { max(0, sickDaysPerMonth - sickDaysUsedThisMonth) }

    // True when any special session (travel, sick day, earn) has suspended blocking
    var hasActiveSpecialSession: Bool {
        travelSessionActive || sickDaySessionActive || earnSessionActive
    }

    // MARK: - Init / Lifecycle

    init() {
        loadEarnTasks()
        loadAlwaysFreeApps()
        loadPersistedState()
        checkMonthlyReset()
        #if os(macOS)
        startPeriodicTimer()
        #endif
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        #if os(iOS)
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            authorizationError = error.localizedDescription
        }
        #elseif os(macOS)
        // macOS uses NSWorkspace — no Screen Time authorization needed
        isAuthorized = true
        #endif
    }

    // MARK: - Blocking

    func startBlocking(requireClaudeOverride: Bool = false) {
        #if os(iOS)
        guard !selection.applicationTokens.isEmpty ||
              !selection.categoryTokens.isEmpty else { return }
        store.shield.applications          = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty   ? nil : .specific(selection.categoryTokens)
        #elseif os(macOS)
        guard !blockedBundleIDs.isEmpty else { return }
        startMacOSBlocking()
        #endif
        isBlocking = true
        claudeOverrideRequired = requireClaudeOverride
    }

    func stopBlocking() {
        #if os(iOS)
        store.shield.applications          = nil
        store.shield.applicationCategories = nil
        #elseif os(macOS)
        stopMacOSBlocking()
        #endif
        isBlocking = false
        claudeOverrideRequired = false
        if scheduleEnabled { cancelSchedule() }
    }

    // MARK: - Scheduling

    func enableSchedule() {
        #if os(iOS)
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
        #elseif os(macOS)
        scheduleEnabled = true
        evaluateScheduleWindow()
        #endif
    }

    func cancelSchedule() {
        #if os(iOS)
        activityCenter.stopMonitoring([activityName])
        #endif
        scheduleEnabled = false
    }

    // MARK: - Blackout

    func enableBlackout() {
        blackoutEnabled = true
        evaluateBlackoutWindow()
    }

    func disableBlackout() {
        blackoutEnabled = false
        if isInBlackout { exitBlackout() }
    }

    func evaluateBlackoutWindow() {
        guard blackoutEnabled else {
            if isInBlackout { exitBlackout() }
            return
        }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let inWindow = isInTimeWindow(now: now, start: blackoutStart, end: blackoutEnd)
        if inWindow && !isInBlackout {
            enterBlackout()
        } else if !inWindow && isInBlackout {
            exitBlackout()
        }
    }

    private func enterBlackout() {
        isInBlackout = true
        // Pause any active earn countdown
        if earnSessionActive {
            earnedMinutesPausedDuringBlackout = earnedMinutesRemaining
            earnTimer?.invalidate()
            earnTimer = nil
        }
        applyBlackoutBlocking()
    }

    private func exitBlackout() {
        isInBlackout = false
        exitBlackoutBlocking()
        // Resume paused earn countdown if any
        if earnedMinutesPausedDuringBlackout > 0 {
            earnedMinutesRemaining = earnedMinutesPausedDuringBlackout
            earnedMinutesPausedDuringBlackout = 0
            if earnSessionActive { startEarnCountdown() }
        }
    }

    private func applyBlackoutBlocking() {
        #if os(iOS)
        // Block all app categories; individual app exemptions not supported by iOS API
        store.shield.applicationCategories = .all(except: alwaysFreeSelection.categoryTokens)
        #elseif os(macOS)
        applyMacOSBlackoutBlocking()
        #endif
    }

    private func exitBlackoutBlocking() {
        #if os(iOS)
        // Restore normal blocking state
        if isBlocking {
            store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        } else {
            store.shield.applicationCategories = nil
        }
        #elseif os(macOS)
        stopMacOSBlackoutBlocking()
        #endif
    }

    // MARK: - Earn System

    func addEarnedMinutes(_ minutes: Int) {
        earnedMinutesRemaining += minutes
    }

    func startEarnedSession() {
        guard earnedMinutesRemaining > 0, canEarn else { return }
        earnSessionActive = true
        suspendBlockingForSession()
        startEarnCountdown()
    }

    private func startEarnCountdown() {
        earnTimer?.invalidate()
        earnTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.earnedMinutesRemaining > 0 {
                    self.earnedMinutesRemaining -= 1
                }
                if self.earnedMinutesRemaining == 0 {
                    self.endEarnedSession()
                }
            }
        }
    }

    private func endEarnedSession() {
        earnTimer?.invalidate()
        earnTimer = nil
        earnSessionActive = false
        resumeBlockingAfterSession()
    }

    // MARK: - Travel Access

    func activateTravelAccess(hours: Int) {
        guard travelUsesRemaining > 0, hours <= travelMaxHoursPerUse, hours > 0 else { return }
        travelUsesUsedThisMonth += 1
        travelSessionActive = true
        travelSessionEndsAt = Date().addingTimeInterval(TimeInterval(hours * 3600))
        savePersistedState()
        suspendBlockingForSession()
        travelTimer?.invalidate()
        travelTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(hours * 3600), repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.endTravelSession() }
        }
    }

    private func endTravelSession() {
        travelTimer?.invalidate()
        travelTimer = nil
        travelSessionActive = false
        travelSessionEndsAt = nil
        resumeBlockingAfterSession()
    }

    // MARK: - Sick Day

    func activateSickDay(hours: Int) {
        guard sickDaysRemaining > 0, hours > 0 else { return }
        sickDaysUsedThisMonth += 1
        sickDaySessionActive = true
        sickDaySessionEndsAt = Date().addingTimeInterval(TimeInterval(hours * 3600))
        savePersistedState()
        suspendBlockingForSession()
        sickDayTimer?.invalidate()
        sickDayTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(hours * 3600), repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.endSickDaySession() }
        }
    }

    private func endSickDaySession() {
        sickDayTimer?.invalidate()
        sickDayTimer = nil
        sickDaySessionActive = false
        sickDaySessionEndsAt = nil
        resumeBlockingAfterSession()
    }

    // MARK: - Session Suspend / Resume

    private var preSessionWasBlocking = false
    private var preSessionClaudeRequired = false

    private func suspendBlockingForSession() {
        preSessionWasBlocking = isBlocking
        preSessionClaudeRequired = claudeOverrideRequired
        if isInBlackout {
            exitBlackoutBlocking()
        } else {
            #if os(iOS)
            store.shield.applications          = nil
            store.shield.applicationCategories = nil
            #elseif os(macOS)
            stopMacOSBlocking()
            #endif
        }
    }

    private func resumeBlockingAfterSession() {
        // Only resume if no other special session is still active
        guard !travelSessionActive, !sickDaySessionActive, !earnSessionActive else { return }
        if isInBlackout {
            applyBlackoutBlocking()
        } else if preSessionWasBlocking {
            startBlocking(requireClaudeOverride: preSessionClaudeRequired)
        }
    }

    // MARK: - Settings Updates (called after Claude approval)

    func updateTravelSettings(usesPerMonth: Int, maxHoursPerUse: Int) {
        travelUsesPerMonth = usesPerMonth
        travelMaxHoursPerUse = maxHoursPerUse
        savePersistedState()
    }

    func updateSickDaySettings(daysPerMonth: Int) {
        sickDaysPerMonth = daysPerMonth
        savePersistedState()
    }

    // MARK: - Time Window Helper

    func isInTimeWindow(now: DateComponents, start: DateComponents, end: DateComponents) -> Bool {
        let startMin = (start.hour ?? 0) * 60 + (start.minute ?? 0)
        let endMin   = (end.hour   ?? 0) * 60 + (end.minute   ?? 0)
        let nowMin   = (now.hour   ?? 0) * 60 + (now.minute   ?? 0)
        // Handle overnight windows (e.g. 21:00 – 08:00)
        if startMin < endMin {
            return nowMin >= startMin && nowMin < endMin
        } else {
            return nowMin >= startMin || nowMin < endMin
        }
    }

    // MARK: - Monthly Reset

    func checkMonthlyReset() {
        let resetDate = UserDefaults.standard.object(forKey: "travelPeriodResetDate") as? Date
            ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        if Date() > resetDate {
            travelUsesUsedThisMonth = 0
            sickDaysUsedThisMonth = 0
            let newReset = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            UserDefaults.standard.set(newReset, forKey: "travelPeriodResetDate")
            savePersistedState()
        }
    }

    // MARK: - Persistence

    private func saveEarnTasks() {
        if let data = try? JSONEncoder().encode(earnTasks) {
            UserDefaults.standard.set(data, forKey: "earnTasks")
        }
    }

    private func loadEarnTasks() {
        if let data = UserDefaults.standard.data(forKey: "earnTasks"),
           let tasks = try? JSONDecoder().decode([EarnTask].self, from: data) {
            earnTasks = tasks
        }
    }

    private func saveAlwaysFreeApps() {
        if let data = try? JSONEncoder().encode(alwaysFreeApps) {
            UserDefaults.standard.set(data, forKey: "alwaysFreeApps")
        }
    }

    private func loadAlwaysFreeApps() {
        if let data = UserDefaults.standard.data(forKey: "alwaysFreeApps"),
           let apps = try? JSONDecoder().decode([AlwaysFreeApp].self, from: data) {
            alwaysFreeApps = apps
        }
    }

    private func savePersistedState() {
        let d = UserDefaults.standard
        d.set(travelUsesPerMonth, forKey: "travelUsesPerMonth")
        d.set(travelMaxHoursPerUse, forKey: "travelMaxHoursPerUse")
        d.set(travelUsesUsedThisMonth, forKey: "travelUsesUsedThisMonth")
        d.set(sickDaysPerMonth, forKey: "sickDaysPerMonth")
        d.set(sickDaysUsedThisMonth, forKey: "sickDaysUsedThisMonth")
    }

    private func loadPersistedState() {
        let d = UserDefaults.standard
        if d.object(forKey: "travelUsesPerMonth") != nil {
            travelUsesPerMonth = d.integer(forKey: "travelUsesPerMonth")
        }
        if d.object(forKey: "travelMaxHoursPerUse") != nil {
            travelMaxHoursPerUse = d.integer(forKey: "travelMaxHoursPerUse")
        }
        travelUsesUsedThisMonth = d.integer(forKey: "travelUsesUsedThisMonth")
        if d.object(forKey: "sickDaysPerMonth") != nil {
            sickDaysPerMonth = d.integer(forKey: "sickDaysPerMonth")
        }
        sickDaysUsedThisMonth = d.integer(forKey: "sickDaysUsedThisMonth")
    }

    // MARK: - macOS-specific Implementation

    #if os(macOS)

    private func startMacOSBlocking() {
        let ids = blockedBundleIDs
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  self.blockedBundleIDs.contains(app.bundleIdentifier ?? "") else { return }
            app.terminate()
        }
        // Terminate any already-running blocked apps
        for app in NSWorkspace.shared.runningApplications where ids.contains(app.bundleIdentifier ?? "") {
            app.terminate()
        }
    }

    private func stopMacOSBlocking() {
        if let obs = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            workspaceObserver = nil
        }
    }

    private func applyMacOSBlackoutBlocking() {
        let freeIDs = Set(alwaysFreeApps.map { $0.bundleIdentifier })
        macOSBlackoutObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            let bid = app.bundleIdentifier ?? ""
            let isFree = self.alwaysFreeApps.map { $0.bundleIdentifier }.contains(bid)
            if !isFree { app.terminate() }
        }
        // Terminate currently running non-free, non-system apps
        for app in NSWorkspace.shared.runningApplications
        where app.activationPolicy == .regular && !freeIDs.contains(app.bundleIdentifier ?? "") {
            app.terminate()
        }
    }

    private func stopMacOSBlackoutBlocking() {
        if let obs = macOSBlackoutObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            macOSBlackoutObserver = nil
        }
    }

    private func startPeriodicTimer() {
        periodicTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.evaluateScheduleWindow()
                self.evaluateBlackoutWindow()
                self.checkMonthlyReset()
            }
        }
    }

    private func evaluateScheduleWindow() {
        guard scheduleEnabled, !hasActiveSpecialSession else { return }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let inWindow = isInTimeWindow(now: now, start: scheduleStart, end: scheduleEnd)
        if inWindow && !isBlocking {
            startBlocking(requireClaudeOverride: claudeOverrideRequired)
        } else if !inWindow && isBlocking {
            stopBlocking()
        }
    }

    #endif
}
