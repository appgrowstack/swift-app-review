import Observation
import ReviewCore
import StoreKit
import SwiftUI

/// Carries a request for the system's rating prompt from code outside the view tree to a view,
/// which calls `RequestReviewAction`.
///
/// `RequestReviewAction` only exists in the SwiftUI environment, so a campaign engine or any other
/// caller cannot call it. The bridge carries one pending request to whichever view applied
/// ``SwiftUICore/View/reviewRequests(_:suppressed:delay:)`` and waits for that view to call the
/// system or give up.
///
/// The bridge does not decide when, whom or how often to ask. That is the `review_ask` campaign's
/// job (its trigger, audience and limits). Hand ``requestSystemPrompt()`` to the campaign engine as
/// the `request_review` action:
///
/// ```swift
/// @State private var review = ReviewRequestBridge()
///
/// // CampaignEngine(…, actions: [.requestReview { await review.requestSystemPrompt() }], …)
///
/// var body: some View {
///     RootView()
///         .reviewRequests(review, suppressed: isSheetPresented)
/// }
/// ```
@MainActor
@Observable
public final class ReviewRequestBridge {

    struct Pending {
        let id: UUID
        let continuation: CheckedContinuation<ReviewAskOutcome, Never>
    }

    /// The request waiting for a view, observed by the host modifier.
    public private(set) var pendingID: UUID?
    @ObservationIgnored private var pending: Pending?
    @ObservationIgnored private var hosts = 0

    public init() {}

    /// Whether a view is attached to take requests.
    public var hasHost: Bool { hosts > 0 }

    /// Asks the attached view to open the system's rating prompt once the screen has settled.
    ///
    /// Returns ``ReviewAskOutcome/requested`` when the system was called, and
    /// ``ReviewAskOutcome/abandoned(_:)`` when the request was dropped first: no view is attached,
    /// another request is waiting, the app left the foreground, something was presented over the
    /// screen, or the view went away.
    @discardableResult
    public func requestSystemPrompt() async -> ReviewAskOutcome {
        guard hasHost else { return .abandoned(.noHost) }
        guard pending == nil else { return .abandoned(.alreadyPending) }
        return await withCheckedContinuation { continuation in
            let id = UUID()
            pending = Pending(id: id, continuation: continuation)
            pendingID = id
        }
    }

    func attachHost() {
        hosts += 1
    }

    func detachHost() {
        hosts = max(0, hosts - 1)
        if hosts == 0, let id = pendingID { resolve(id, with: .abandoned(.interrupted)) }
    }

    func isPending(_ id: UUID) -> Bool {
        pending?.id == id
    }

    /// Finishes the request if it is still the pending one; later calls for the same id do nothing.
    func resolve(_ id: UUID, with outcome: ReviewAskOutcome) {
        guard let current = pending, current.id == id else { return }
        pending = nil
        pendingID = nil
        current.continuation.resume(returning: outcome)
    }
}

/// Calls `RequestReviewAction` for requests carried by a ``ReviewRequestBridge``.
struct ReviewRequestHost: ViewModifier {

    let bridge: ReviewRequestBridge
    let suppressed: Bool
    let delay: Duration

    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onAppear { bridge.attachHost() }
            .onDisappear { bridge.detachHost() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active, let id = bridge.pendingID { bridge.resolve(id, with: .abandoned(.sceneInactive)) }
            }
            .onChange(of: suppressed) { _, isSuppressed in
                if isSuppressed, let id = bridge.pendingID { bridge.resolve(id, with: .abandoned(.obstructed)) }
            }
            .task(id: bridge.pendingID) {
                guard let id = bridge.pendingID else { return }
                guard scenePhase == .active else { return bridge.resolve(id, with: .abandoned(.sceneInactive)) }
                guard !suppressed else { return bridge.resolve(id, with: .abandoned(.obstructed)) }
                do {
                    try await Task.sleep(for: delay)
                } catch {
                    return bridge.resolve(id, with: .abandoned(.interrupted))
                }
                // A change of phase or suppression while waiting has already resolved it.
                guard bridge.isPending(id) else { return }
                requestReview()
                bridge.resolve(id, with: .requested)
            }
    }
}

extension View {

    /// Takes requests from `bridge` and calls the system's review request for each, once the
    /// screen has settled.
    ///
    /// A request is dropped when the app is not in the foreground, when `suppressed` is `true`
    /// (a sheet, a dialog or a permission prompt is showing), or when either becomes true during
    /// `delay`. Apply it once, near the root.
    ///
    /// - Parameters:
    ///   - bridge: The bridge whose ``ReviewRequestBridge/requestSystemPrompt()`` the campaign calls
    ///   - suppressed: `true` while something is presented over the screen
    ///   - delay: How long the screen must stay settled first. The default 1.8 seconds is inside
    ///     the rating rule R8 ("1.5 to 2 seconds after the animation stops").
    public func reviewRequests(
        _ bridge: ReviewRequestBridge,
        suppressed: Bool = false,
        delay: Duration = .milliseconds(1800)
    ) -> some View {
        modifier(ReviewRequestHost(bridge: bridge, suppressed: suppressed, delay: delay))
    }
}
