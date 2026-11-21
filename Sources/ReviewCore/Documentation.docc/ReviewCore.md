# ``ReviewCore``

Open the system's App Store rating prompt, and link to the write-a-review page from a settings row.

@Metadata {
    @PageColor(orange)
}

## Overview

The system decides whether a rating prompt appears and what it says. What is left to the app is
when to call it, and that is not this package's job: the `review_ask` campaign in
swift-app-campaign decides it with its trigger (a good outcome), its audience (7 days after first
seen) and its limits (once per app version, 60 days apart). Its placement has the kind `system`: it
has no look of its own and runs the `request_review` action at once.

This module holds the values that do not need SwiftUI: what happened to a request
(``ReviewAskOutcome``, ``ReviewAbandonment``) and the write-review link for a settings row the
person presses themselves (``WriteReviewLink``). The request itself is `ReviewRequestBridge` in
`ReviewSwiftUI`, the only place that imports StoreKit.

```swift
if let id = AppStoreID(appStoreID) {
    Link("Rate on the App Store", destination: WriteReviewLink.url(for: id))
}
```

## Topics

### Requests

- ``ReviewAskOutcome``
- ``ReviewAbandonment``

### The write-review link

- ``AppStoreID``
- ``WriteReviewLink``
