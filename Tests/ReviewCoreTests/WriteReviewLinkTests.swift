import Foundation
import Testing
import ReviewCore

@Suite("レビューを書くリンク")
struct WriteReviewLinkTests {

    @Test("数字の id から App Store のレビューを書く画面のリンクを作る")
    func url() throws {
        let id = try #require(AppStoreID("6829535401"))
        #expect(WriteReviewLink.url(for: id).absoluteString == "https://apps.apple.com/app/id6829535401?action=write-review")
    }

    @Test("数字でない id（空・置き換え忘れ・全角）はリンクにしない", arguments: ["", "APP_STORE_ID", "12a4", "１２３"])
    func rejectsNonDigits(_ text: String) {
        #expect(AppStoreID(text) == nil)
    }
}
