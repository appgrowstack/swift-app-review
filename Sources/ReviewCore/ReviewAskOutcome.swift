/// What happened when the app asked the screen to open the system's rating prompt.
public enum ReviewAskOutcome: Hashable, Sendable {

    /// The system's review request was called. Whether a prompt appeared is unknown and unknowable:
    /// the system decides that, and shows it at most three times a year.
    case requested

    /// The request was dropped before the system was called.
    case abandoned(ReviewAbandonment)
}

/// Why a request was dropped before reaching the system.
public enum ReviewAbandonment: String, Hashable, Sendable, CaseIterable {
    /// No screen was attached to take requests.
    case noHost = "no_host"
    /// Another request was already waiting.
    case alreadyPending = "already_pending"
    /// The app left the foreground while waiting.
    case sceneInactive = "scene_inactive"
    /// A sheet or dialog was on screen while waiting.
    case obstructed
    /// The screen went away while waiting.
    case interrupted
}
