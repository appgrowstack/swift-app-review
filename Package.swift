// swift-tools-version: 6.2
import PackageDescription

/// Opening the system's App Store rating prompt, and the write-a-review link for a settings row.
///
/// **It does not decide when, whom or how often to ask.** That is the `review_ask` campaign's job
/// in swift-app-campaign (its trigger, audience and limits). This package only opens the prompt
/// once the screen has settled.
///
/// **No external dependencies.** SwiftPM resolves dependencies per package, so anything declared
/// here lands on every consumer. The campaign engine takes a closure, so nothing here imports it.
let package = Package(
    name: "swift-app-review",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // The outcome of a request and the write-review link. Foundation only.
        .library(name: "ReviewCore", targets: ["ReviewCore"]),
        // The only target that imports StoreKit. Calls `RequestReviewAction` from the view tree.
        .library(name: "ReviewSwiftUI", targets: ["ReviewSwiftUI"])
    ],
    targets: [
        .target(name: "ReviewCore"),
        .target(name: "ReviewSwiftUI", dependencies: ["ReviewCore"]),

        .testTarget(name: "ReviewCoreTests", dependencies: ["ReviewCore"]),
        .testTarget(name: "ReviewSwiftUITests", dependencies: ["ReviewSwiftUI"])
    ]
)
