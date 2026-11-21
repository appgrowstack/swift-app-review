# swift-app-review

画面の外のコードから、画面が止まっているときだけ、iOSのApp Storeの評価のダイアログを開く。

[English](./README.md)

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

`RequestReviewAction` はSwiftUIの環境の中にしか無いので、頼むと決めるコードからは呼べません。
`ReviewRequestBridge` がそのコードからビューへ依頼を1つ運び、ビューがiOSを呼びます。
いつ・誰に・何回頼むかはこのパッケージでは決めません。アプリかキャンペーンが決めます。

## 機能

- **iOSのダイアログだけ。** ビューから `RequestReviewAction` を呼びます。自前のダイアログ・前置き・満足度での分岐・見返りはありません
- **画面が空いているときだけ。** 依頼は画面が止まったまま1.8秒たつのを待ちます。その間にアプリが前面から外れるか、画面の上に何かが出たら取りやめます
- **結果が分かる。** `requestSystemPrompt()` は `ReviewAskOutcome` を返します。`.requested` か、理由の `ReviewAbandonment`（`noHost`・`alreadyPending`・`sceneInactive`・`obstructed`・`interrupted`）付きの `.abandoned` です
- **「レビューを書く」のリンク**（`WriteReviewLink`）。本人がタップする設定の行に置きます。`AppStoreID` は数字だけを受けるので、仮の文字列がリンクになりません
- **外部の依存なし。** StoreKitとSwiftUIは `ReviewSwiftUI` の中だけです。`ReviewCore` はFoundationだけを使います

## はじめに

```swift
import ReviewCore
import ReviewSwiftUI
import SwiftUI

struct ContentView: View {
    @State private var review = ReviewRequestBridge()
    @State private var isSheetPresented = false

    var body: some View {
        VStack(spacing: 16) {
            Button("Finish") {
                Task {
                    // Call this when your own rule decides to ask.
                    let outcome = await review.requestSystemPrompt()
                    if case let .abandoned(reason) = outcome {
                        print("Not asked:", reason.rawValue)
                    }
                }
            }
            if let id = AppStoreID("1234567890") {
                Link("Rate on the App Store", destination: WriteReviewLink.url(for: id))
            }
        }
        // Apply once, near the root. Pass true while a sheet or dialog is showing.
        .reviewRequests(review, suppressed: isSheetPresented)
    }
}
```

### サーバーにつなぐ

このパッケージは単体で使えます。サーバーにつなぐときは、このパッケージで送り先を書く代わりに、コネクターのパッケージ [swift-appgrowstack](https://github.com/appgrowstack/swift-appgrowstack) の対応するtrait（SwiftPMのtraits）を有効にします。

## ドキュメント

APIの説明は `Sources/ReviewCore/Documentation.docc` のDocCのカタログと、`ReviewSwiftUI` のシンボルのドキュメントです。
XcodeのProduct > Build Documentationで開けます。変更は [CHANGELOG.md](./CHANGELOG.md) にあります。

## 入れ方

```swift
.package(url: "https://github.com/appgrowstack/swift-app-review.git", .upToNextMinor(from: "0.4.1"))
```

```swift
.product(name: "ReviewSwiftUI", package: "swift-app-review")
```

| プロダクト | 中身 | 依存 |
|---|---|---|
| `ReviewCore` | `ReviewAskOutcome`・`ReviewAbandonment`・`AppStoreID`・`WriteReviewLink` | Foundation |
| `ReviewSwiftUI` | `ReviewRequestBridge`・`.reviewRequests(_:suppressed:delay:)` | SwiftUI・StoreKit |

## 動く環境

- iOS 17.0+ / macOS 14.0+
- Swift 6.2+

## ライセンス

MIT。[LICENSE](./LICENSE) を見てください。
