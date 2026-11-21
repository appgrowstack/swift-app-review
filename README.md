English | [日本語](./README.ja.md)

# swift-review

Open the system's App Store rating prompt from outside the view tree, once the screen has settled, for a campaign that decides when to ask.

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

iOS decides whether a rating prompt appears, and `RequestReviewAction` is the only way to ask. It
lives in the SwiftUI environment, so code that decides to ask — a campaign engine — cannot call it.
This package carries one request from there to a view and calls the system when the app is in the
foreground, nothing is presented over the screen, and the screen has been still for a moment.

**It does not decide when, whom or how often to ask.** The `review_ask` campaign type of
[swift-app-campaign](https://github.com/no-problem-dev/swift-app-campaign) does: a good outcome as
the trigger, 7 days after first seen, once per app version, 60 days apart.

## Features

- **The system prompt only.** `RequestReviewAction`, called from the view tree. No custom dialog, no
  pre-prompt, no sentiment branch, no incentives (Guidelines 5.6.1, 3.2.2(x), and §3's "filtered"
  feedback)
- **Only when the screen is free.** A request waits 1.8 seconds for the screen to settle and is
  dropped if the app leaves the foreground or a sheet appears meanwhile
- **A write-review link** for a settings row the person presses themselves
- **No dependencies.** StoreKit and SwiftUI are confined to `ReviewSwiftUI`; the campaign engine
  takes the request as a closure

## Usage

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

The campaign lives in the app's `campaigns/` (see the `review_ask` template in app-growth). A
settings row:

```swift
if let id = AppStoreID(appStoreID) {
    Link("Rate on the App Store", destination: WriteReviewLink.url(for: id))
}
```

## Documentation

[DESIGN.md](./DESIGN.md) covers who decides what, the non-goals with citations, and what moved out
in 0.4.0.

## Installation

```swift
.package(url: "https://github.com/no-problem-dev/swift-review.git", .upToNextMinor(from: "0.4.0"))
```

| Product | Contents | Depends on |
|---|---|---|
| `ReviewCore` | `ReviewAskOutcome`, `ReviewAbandonment`, `AppStoreID`, `WriteReviewLink` | Foundation |
| `ReviewSwiftUI` | `ReviewRequestBridge`, `.reviewRequests(_:suppressed:delay:)` | SwiftUI, StoreKit |

## Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 6.2+

## License

MIT — see [LICENSE](LICENSE).
