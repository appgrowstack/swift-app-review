[English](./README.md) | 日本語

# swift-review

いつ頼むかを決めるキャンペーンのために、画面の外のコードから、画面が落ち着いてから iOS の評価のダイアログを開く。

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

評価のダイアログを出すかは iOS が決め、頼む道は `RequestReviewAction` だけです。これは SwiftUI の環境の中にしか無いので、
頼むと決めるコード（キャンペーンの判定）からは呼べません。このパッケージは、その依頼を1つ画面まで運び、
アプリが前面にいて、画面の上に何も出ておらず、画面が少し落ち着いたときに iOS を呼びます。

**いつ・誰に・何回頼むかは決めません。** それは
[swift-app-campaign](https://github.com/no-problem-dev/swift-app-campaign) の型 `review_ask` の件が決めます
（きっかけは「役に立った」の出来事・最初に見てから7日・同じ版で1回・前回から60日）。

> 開発は非公開のモノリポでしていて、ここへは片方向にコピーするだけです。Issueは受けます。PRは受けません。

## 特徴

- **iOS のダイアログだけ。** 画面の側から `RequestReviewAction` を呼びます。自前のダイアログ・前置き・満足度での分岐・見返りはありません（審査 5.6.1・3.2.2(x)・3章の「filtered」）
- **画面が空いているときだけ。** 依頼は画面が落ち着くまで1.8秒待ち、その間にアプリが裏に回るかシートが出たら取りやめます
- **「レビューを書く」のリンク。** 本人が押す設定の行に置きます
- **外部の依存なし。** StoreKit と SwiftUI は `ReviewSwiftUI` の中だけ。キャンペーンには依頼をクロージャで渡します

## 使い方

```swift
import CampaignCore
import ReviewSwiftUI

@State private var review = ReviewRequestBridge()

let campaigns = CampaignEngine(
    …,
    placements: [CampaignTemplate.ReviewAsk.self],
    actions: [.requestReview { await review.requestSystemPrompt() }],
    …
)

var body: some View {
    RootView().reviewRequests(review, suppressed: isSheetPresented)
}
```

件はアプリの `campaigns/` に置きます（app-growth の `review_ask` のテンプレート）。設定の行:

```swift
if let id = AppStoreID(appStoreID) {
    Link("App Store で評価する", destination: WriteReviewLink.url(for: id))
}
```

## ドキュメント

[DESIGN.md](./DESIGN.md) に、何を誰が決めるか・作らない物とその出典・0.4.0 で外へ出した物を書いています。

## 導入

```swift
.package(url: "https://github.com/no-problem-dev/swift-review.git", .upToNextMinor(from: "0.4.0"))
```

| プロダクト | 中身 | 依存 |
|---|---|---|
| `ReviewCore` | `ReviewAskOutcome`・`ReviewAbandonment`・`AppStoreID`・`WriteReviewLink` | Foundation |
| `ReviewSwiftUI` | `ReviewRequestBridge`・`.reviewRequests(_:suppressed:delay:)` | SwiftUI・StoreKit |

## 要件

- iOS 17.0+ / macOS 14.0+
- Swift 6.2+

## ライセンス

MIT — [LICENSE](LICENSE) を参照。
