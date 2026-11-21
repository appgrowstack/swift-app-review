import Foundation
import Testing
import ReviewCore
@testable import ReviewSwiftUI

@MainActor
@Suite("画面の側: OS の評価の窓を開く依頼の受け渡し")
struct ReviewSwiftUITests {

    @Test("受ける画面が無ければ、頼まずに取りやめる")
    func noHost() async {
        let bridge = ReviewRequestBridge()
        #expect(await bridge.requestSystemPrompt() == .abandoned(.noHost))
    }

    @Test("受ける画面があれば待っている依頼になり、画面が呼んだら requested を返す")
    func hostResolvesRequested() async throws {
        let bridge = ReviewRequestBridge()
        bridge.attachHost()
        let task = Task { await bridge.requestSystemPrompt() }
        try await waitUntil { bridge.pendingID != nil }

        bridge.resolve(try #require(bridge.pendingID), with: .requested)
        #expect(await task.value == .requested)
        #expect(bridge.pendingID == nil)
    }

    @Test("待っている依頼がある間の次の依頼は取りやめる")
    func secondRequestWhilePending() async throws {
        let bridge = ReviewRequestBridge()
        bridge.attachHost()
        let first = Task { await bridge.requestSystemPrompt() }
        try await waitUntil { bridge.pendingID != nil }

        #expect(await bridge.requestSystemPrompt() == .abandoned(.alreadyPending))
        bridge.resolve(try #require(bridge.pendingID), with: .requested)
        #expect(await first.value == .requested)
    }

    @Test("受ける画面が消えたら、待っている依頼は取りやめにする")
    func detachInterrupts() async throws {
        let bridge = ReviewRequestBridge()
        bridge.attachHost()
        let task = Task { await bridge.requestSystemPrompt() }
        try await waitUntil { bridge.pendingID != nil }
        bridge.detachHost()
        #expect(await task.value == .abandoned(.interrupted))
        #expect(!bridge.hasHost)
    }

    @Test("同じ依頼を2回終えても、2回目は何もしない")
    func resolveIsIdempotent() async throws {
        let bridge = ReviewRequestBridge()
        bridge.attachHost()
        let task = Task { await bridge.requestSystemPrompt() }
        try await waitUntil { bridge.pendingID != nil }
        let id = try #require(bridge.pendingID)
        bridge.resolve(id, with: .abandoned(.obstructed))
        bridge.resolve(id, with: .requested)
        #expect(await task.value == .abandoned(.obstructed))
    }

    private func waitUntil(_ condition: @MainActor () -> Bool) async throws {
        for _ in 0..<200 where !condition() {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(condition())
    }
}
