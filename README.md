# swift-app-review

Open the system's App Store rating prompt from code outside the view tree, only once the screen has settled.

[Japanese](./README.ja.md)

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

`RequestReviewAction` only exists in the SwiftUI environment, so code that decides to ask cannot
call it. `ReviewRequestBridge` carries one request from that code to a view, and the view calls the
system. The package does not decide when, whom or how often to ask; your app or a campaign does.

## Features

- **The system prompt only.** It calls `RequestReviewAction` from the view tree. No custom dialog,
  no pre-prompt, no branch on satisfaction, no incentives
- **Only when the screen is free.** A request waits 1.8 seconds for the screen to settle, and is
  dropped if the app leaves the foreground or something is presented over the screen meanwhile
- **A clear outcome.** `requestSystemPrompt()` returns `ReviewAskOutcome`: `.requested`, or
  `.abandoned` with a `ReviewAbandonment` reason (`noHost`, `alreadyPending`, `sceneInactive`,
  `obstructed`, `interrupted`)
- **A write-review link** (`WriteReviewLink`) for a settings row the person taps themselves.
  `AppStoreID` refuses anything but digits, so a placeholder never becomes a link
- **No dependencies.** StoreKit and SwiftUI stay in `ReviewSwiftUI`; `ReviewCore` needs only
  Foundation

## Quick Start

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

### Connecting to a server

The package works on its own. To connect it to a server, enable the matching trait of the connector package [swift-appgrowstack](https://github.com/appgrowstack/swift-appgrowstack) (SwiftPM traits) instead of wiring a server here.

## Documentation

The API reference is the DocC catalog in `Sources/ReviewCore/Documentation.docc`, and the symbol
documentation of `ReviewSwiftUI`. Open them in Xcode with Product > Build Documentation. Changes
are listed in [CHANGELOG.md](./CHANGELOG.md).

## Installation

```swift
.package(url: "https://github.com/appgrowstack/swift-app-review.git", .upToNextMinor(from: "0.4.0"))
```

```swift
.product(name: "ReviewSwiftUI", package: "swift-app-review")
```

| Product | Contents | Depends on |
|---|---|---|
| `ReviewCore` | `ReviewAskOutcome`, `ReviewAbandonment`, `AppStoreID`, `WriteReviewLink` | Foundation |
| `ReviewSwiftUI` | `ReviewRequestBridge`, `.reviewRequests(_:suppressed:delay:)` | SwiftUI, StoreKit |

## Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 6.2+

## License

MIT. See [LICENSE](./LICENSE).
