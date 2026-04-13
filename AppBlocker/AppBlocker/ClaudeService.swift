import Foundation

// MARK: - Chat Mode

/// Defines the context/purpose of a Claude conversation.
enum ChatMode {
    case override                             // Regular unlock request
    case blackoutEmergency                    // Emergency during strict blackout hours
    case earnTask(task: EarnTask)             // Claim a task was completed
    case sickDay                              // Request sick-day access
    case alwaysFree                           // Request an app be added to always-free list
    case travelSettings(current: String)      // Request to change travel access limits
    case sickDaySettings(current: String)     // Request to change sick day limits
}

// MARK: - ClaudeService

/// Talks to the Anthropic API in multiple accountability contexts.
actor ClaudeService {

    static let shared = ClaudeService()

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model  = "claude-sonnet-4-6"

    // MARK: - System Prompts

    private let overridePrompt = """
    You are an accountability coach built into an app blocker. \
    The user has voluntarily set up app-blocking to help themselves focus or build healthier habits. \
    They are now asking you to override (unlock) their blocked apps early.

    Your job:
    1. Have a SHORT conversation (1–3 exchanges) to understand why they want to unlock early.
    2. Be empathetic but firm. It is okay to say no if the reason isn't compelling.
    3. Good reasons to approve: genuine emergency, work requirement, done with scheduled task early.
    4. Bad reasons to approve: boredom, "just for a minute", social pressure, vague excuses.
    5. When you decide, end your message with EXACTLY one of these tokens on its own line:
       [OVERRIDE_APPROVED] — if you are granting access
       [OVERRIDE_DENIED]   — if you are not granting access
    6. Do not include the token until you have enough information to make a decision.
    7. Keep your replies concise and conversational — this is a mobile app.
    """

    private let blackoutEmergencyPrompt = """
    You are an accountability coach. It is currently BLACKOUT HOURS — a self-imposed hard lock \
    the user set up to protect their sleep and wellbeing. The user is requesting emergency access.

    Rules:
    1. ONLY approve for genuine emergencies: medical need, personal safety, family emergency, \
       urgent crisis involving another person.
    2. Explicitly DENY: boredom, work tasks, school assignments, social media, entertainment, \
       "just checking something", feeling tired but awake.
    3. Ask one clarifying question if needed, then decide.
    4. End your message with EXACTLY one of these tokens on its own line:
       [OVERRIDE_APPROVED] — genuine emergency only
       [OVERRIDE_DENIED]   — anything else
    5. Keep replies short and direct.
    """

    private func earnTaskPrompt(task: EarnTask) -> String {
        """
        You are an accountability coach. The user claims to have completed this task:

        Task: "\(task.name)"
        Description: "\(task.taskDescription)"
        Time earned if valid: \(task.minutesEarned) minutes of unblocked screen time.

        Your job:
        1. Ask the user to describe what they actually did to complete the task.
        2. Assess whether their description sounds credible and genuine — not vague or rushed.
        3. Have a short conversation (1–3 exchanges) to probe if needed.
        4. Good signs: specific details, effort described, realistic timeframe.
        5. Bad signs: "I did it", "yes", vague one-word answers, clearly didn't do much.
        6. When you decide, end your message with EXACTLY one of these tokens on its own line:
           [TASK_APPROVED] — if their completion claim is credible
           [TASK_DENIED]   — if it doesn't sound like they genuinely completed the task
        7. Do not include the token until you have enough information.
        """
    }

    private let sickDayPrompt = """
    You are an accountability coach. The user is requesting a sick-day override to access \
    their blocked apps while ill. Your job is to assess whether they are genuinely sick, \
    not just tired, lazy, or looking for an excuse.

    Rules:
    1. Ask follow-up questions to assess their condition:
       - What symptoms do they have?
       - When did they start feeling sick?
       - Have they taken any medication or rested?
    2. Have a conversation of 2–4 exchanges before deciding.
    3. Approve only for clear illness: fever, vomiting, significant pain, doctor-diagnosed condition, etc.
    4. Deny for: tiredness, stress, "not feeling great", minor discomfort, wanting to relax.
    5. You decide how many hours to grant (2–8 hours based on severity). The user does NOT choose.
    6. When you decide, end your message with EXACTLY one of these tokens on its own line:
       [SICK_DAY_APPROVED: hours=N]  — where N is 2–8 depending on severity
       [SICK_DAY_DENIED]             — if not convincingly ill
    7. Keep replies empathetic but honest.
    """

    private let alwaysFreePrompt = """
    You are an accountability coach. The user wants to permanently add an app to their \
    "always-free" list — meaning that app will NEVER be blocked, even during strict blackout hours.

    This is a permanent change. Be very conservative.

    Approve ONLY for apps that are genuinely essential utilities, such as:
    - Maps / navigation
    - Phone / emergency contacts
    - Medical or health monitoring apps
    - Accessibility tools
    - Authenticator or security apps

    Deny for:
    - Social media apps
    - Games or entertainment
    - News or browsing
    - Messaging apps (except emergency-only communication)
    - Any app that could become a distraction

    Ask the user which app they want to add and why. Then decide.

    End your message with EXACTLY one of these tokens on its own line:
    [ALWAYS_FREE_APPROVED: <app name>]  — if the app is a genuine essential utility
    [ALWAYS_FREE_DENIED]               — if not
    """

    private func travelSettingsPrompt(current: String) -> String {
        """
        You are an accountability coach. The user wants to change their travel access limits.
        Current limits: \(current)

        Travel access is a self-imposed restriction they set up to control how often they \
        can grant themselves temporary unrestricted access (e.g. during flights or trips).

        Only approve changes that make the limits MORE strict or are genuinely justified \
        (e.g. they travel for work much more than expected). Do NOT approve changes that \
        simply make it easier to bypass their own rules.

        After their explanation, respond with EXACTLY one of these tokens on its own line:
        [SETTINGS_APPROVED: uses=N, hours=H]  — new values approved
        [SETTINGS_DENIED]                      — not approved
        """
    }

    private func sickDaySettingsPrompt(current: String) -> String {
        """
        You are an accountability coach. The user wants to change their sick-day limit.
        Current limit: \(current)

        This limit controls how many sick days per month they can request. \
        Only approve if they have a genuine ongoing health condition that justifies more \
        sick days, or if they want to REDUCE the limit (making it stricter). \
        Do not approve increases that just give more leeway without good reason.

        After their explanation, respond with EXACTLY one of these tokens on its own line:
        [SETTINGS_APPROVED: sickDays=N]  — approved new value
        [SETTINGS_DENIED]                 — not approved
        """
    }

    // MARK: - Types

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct RequestBody: Codable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]
    }

    struct ResponseBody: Codable {
        struct Content: Codable { let text: String }
        let content: [Content]
    }

    enum OverrideDecision: Equatable {
        case pending                         // Still chatting
        case approved                        // Override / unlock granted
        case denied                          // Denied
        case taskApproved                    // Earn task validated — use earnTask from context
        case taskDenied
        case sickDayApproved(hours: Int)     // Sick day — Claude chose duration
        case sickDayDenied
        case alwaysFreeApproved(appName: String)
        case alwaysFreeDenied
        case settingsApproved(raw: String)   // Raw token payload, caller parses
        case settingsDenied
    }

    struct ClaudeReply {
        let text: String
        let decision: OverrideDecision
    }

    // MARK: - API Call

    func send(history: [Message], apiKey: String, mode: ChatMode = .override) async throws -> ClaudeReply {
        let systemPrompt = buildSystemPrompt(for: mode)

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey,             forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")

        let body = RequestBody(model: model, max_tokens: 512, system: systemPrompt, messages: history)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown error"
            throw ClaudeError.apiError(body)
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        let rawText = decoded.content.first?.text ?? ""

        let (decision, cleanText) = parseDecision(from: rawText, mode: mode)
        return ClaudeReply(text: cleanText, decision: decision)
    }

    // MARK: - System Prompt Builder

    private func buildSystemPrompt(for mode: ChatMode) -> String {
        switch mode {
        case .override:
            return overridePrompt
        case .blackoutEmergency:
            return blackoutEmergencyPrompt
        case .earnTask(let task):
            return earnTaskPrompt(task: task)
        case .sickDay:
            return sickDayPrompt
        case .alwaysFree:
            return alwaysFreePrompt
        case .travelSettings(let current):
            return travelSettingsPrompt(current: current)
        case .sickDaySettings(let current):
            return sickDaySettingsPrompt(current: current)
        }
    }

    // MARK: - Decision Parsing

    private func parseDecision(from text: String, mode: ChatMode) -> (OverrideDecision, String) {
        var clean = text

        // Standard override / blackout emergency
        if clean.contains("[OVERRIDE_APPROVED]") {
            clean = strip("[OVERRIDE_APPROVED]", from: clean)
            return (.approved, clean)
        }
        if clean.contains("[OVERRIDE_DENIED]") {
            clean = strip("[OVERRIDE_DENIED]", from: clean)
            return (.denied, clean)
        }

        // Earn task
        if clean.contains("[TASK_APPROVED]") {
            clean = strip("[TASK_APPROVED]", from: clean)
            return (.taskApproved, clean)
        }
        if clean.contains("[TASK_DENIED]") {
            clean = strip("[TASK_DENIED]", from: clean)
            return (.taskDenied, clean)
        }

        // Sick day — parse hours
        if let range = clean.range(of: #"\[SICK_DAY_APPROVED: hours=(\d+)\]"#, options: .regularExpression) {
            let token = String(clean[range])
            let hours = Int(token.components(separatedBy: "=").last?.replacingOccurrences(of: "]", with: "") ?? "4") ?? 4
            clean = clean.replacingOccurrences(of: token, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return (.sickDayApproved(hours: hours), clean)
        }
        if clean.contains("[SICK_DAY_DENIED]") {
            clean = strip("[SICK_DAY_DENIED]", from: clean)
            return (.sickDayDenied, clean)
        }

        // Always-free — parse app name
        if let range = clean.range(of: #"\[ALWAYS_FREE_APPROVED: ([^\]]+)\]"#, options: .regularExpression) {
            let token = String(clean[range])
            let appName = token
                .replacingOccurrences(of: "[ALWAYS_FREE_APPROVED: ", with: "")
                .replacingOccurrences(of: "]", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            clean = clean.replacingOccurrences(of: token, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return (.alwaysFreeApproved(appName: appName), clean)
        }
        if clean.contains("[ALWAYS_FREE_DENIED]") {
            clean = strip("[ALWAYS_FREE_DENIED]", from: clean)
            return (.alwaysFreeDenied, clean)
        }

        // Settings changes
        if let range = clean.range(of: #"\[SETTINGS_APPROVED:[^\]]+\]"#, options: .regularExpression) {
            let token = String(clean[range])
            let payload = token
                .replacingOccurrences(of: "[SETTINGS_APPROVED:", with: "")
                .replacingOccurrences(of: "]", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            clean = clean.replacingOccurrences(of: token, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return (.settingsApproved(raw: payload), clean)
        }
        if clean.contains("[SETTINGS_DENIED]") {
            clean = strip("[SETTINGS_DENIED]", from: clean)
            return (.settingsDenied, clean)
        }

        return (.pending, clean.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func strip(_ token: String, from text: String) -> String {
        text.replacingOccurrences(of: token, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Error

enum ClaudeError: LocalizedError {
    case apiError(String)
    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return "Claude API error: \(msg)"
        }
    }
}
