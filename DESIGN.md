# swift-review — design

Status: 0.4.0 (2026-11-21). Rewritten for appgrowstack (app-playbook
`docs/growth-platform-design-2026-11-21.md` §3.2 and §4.2): the decision of when, whom and how often
to ask moved to the `review_ask` campaign type of swift-app-campaign. What is left here is opening
the system's rating prompt.

A summary in Japanese is at the end ([日本語の要約](#日本語の要約)).

---

## 1. Purpose

**Open the system's App Store rating prompt when a campaign says so, and only once the screen has
settled.** The system owns *whether* a prompt appears and what it says. The `review_ask` campaign
owns *when, whom and how often*. This package owns the last step: reaching `RequestReviewAction`,
which exists only in the SwiftUI environment, from code that is not a view.

## 2. Who decides what

| Question | Where it is decided |
|---|---|
| After which good outcome (the third exchange, a finished book…) | the campaign's `triggers` (`review_ask.trigger`) |
| Not in the first week | the campaign's `audience`: `days_since_first_seen` gte 7 (`review_ask.first_seen`) |
| Once per app version, 60 days apart | the campaign's `limits`: `max_per_app_version` 1, `min_hours_between` 1440 or more |
| Not while a paywall or another full screen is up | the engine's `isBusy`, up to the trigger's `wait_seconds` |
| Not while a sheet is up, not in the background, 1.8 s after the screen settles | **this package** (`.reviewRequests(_:suppressed:delay:)`) |
| Whether a prompt appears | the system (three times in 365 days per app) |

The checks named in the first column are in app-growth `schema/inapp/templates/review_ask.json`;
`app-growth campaigns check` refuses a campaign that breaks one.

## 3. Non-goals, and why

| Not provided | Why |
|---|---|
| A custom rating dialog, star picker, or anything that looks like the store's | App Review Guideline **5.6.1**: "Use the provided API to prompt users to review your app … we will disallow custom review prompts." |
| A pre-prompt ("Do you like this app? Yes / No") or any routing of unhappy people away from the prompt | The introduction to Guidelines §3 lists inflating rankings with "paid, incentivized, **filtered**, or fake feedback" as manipulation, with removal from the Developer Program as a possible result. A pre-prompt that only lets satisfied people reach the system prompt filters by sentiment. Google Play's In-App Review guidance forbids asking "Do you like the app?" before or during the flow outright. The system prompt itself already asks "Enjoying *App Name*?" (HIG, Ratings and reviews), so a pre-prompt asks the same question twice. **5.6.3** forbids manipulating any element of the store experience, reviews included |
| Incentives (credits, unlocked features, days of a subscription) | Guidelines §3 intro ("incentivized"); **3.2.2(x)**: apps "must not force users to rate the app, review the app … in order to access functionality". In Japan, the 2023-10 stealth-marketing rule under the Premiums and Representations Act makes asking only for good reviews, or rewarding them, a further risk |
| Calling the request from a button | `RequestReviewAction` "may not present an alert", so a button that sometimes does nothing reads as a bug (StoreKit documentation; HIG; rating.md R7). The write-review link is the button-shaped path (§4) |
| A screen in front of the system prompt | A screen that comes before the system prompt and decides who reaches it is the pre-prompt above. The `review_ask` template forbids one too (`review_ask.placement`): its placement is `system`, so nothing is drawn before the prompt |
| Knowing whether the prompt was shown | The system does not report it. The `request_review` action always reports `completed`; the outcome of a campaign is the rating count and average in App Store Connect, never a per-person comparison (`review_ask.holdout` is 0) |
| Replying to App Store reviews | An operations task (`asc reviews …`), not app code |


Apple's own numbers the `review_ask` limits rest on: the system shows the prompt at most **three times in 365
days** per app; for someone who already rated, only in a new version and more than 365 days after
the last rating; never in TestFlight; every time in development builds. `SKStoreReviewController`
is deprecated in iOS 18 in favour of `RequestReviewAction` (iOS 16+).

## 4. Package structure

```
swift-review
├── ReviewCore      Foundation only. ReviewAskOutcome, ReviewAbandonment, AppStoreID, WriteReviewLink
└── ReviewSwiftUI   ReviewCore + SwiftUI + StoreKit. ReviewRequestBridge, .reviewRequests(_:suppressed:delay:)
```

No external dependencies. The campaign engine takes the request as a closure
(`.requestReview { await review.requestSystemPrompt() }`), so this package does not import
swift-app-campaign and swift-app-campaign does not import this one.

**The write-review link.** `WriteReviewLink.url(for:)` is
`https://apps.apple.com/app/id<ID>?action=write-review`, for a settings row the person presses
themselves (R7). It is not a request and no campaign is involved.

## 5. The StoreKit adapter

`RequestReviewAction` exists only in the SwiftUI environment and has no public initialiser, so it
cannot be called from the campaign engine or faked. The seam is one step earlier:

- `ReviewRequestBridge` (`@MainActor @Observable`) holds at most one pending request and suspends
  the caller until a view resolves it.
- `.reviewRequests(bridge, suppressed: isSheetShown, delay: .milliseconds(1800))` on the root view
  takes the pending request, checks `scenePhase == .active` and `!suppressed`, waits `delay`, checks
  again, calls `requestReview()` and resolves `.requested`.
- It resolves `.abandoned(…)` if no view is attached (`.noHost`), one is already pending
  (`.alreadyPending`), the scene leaves the foreground (`.sceneInactive`), something is presented
  (`.obstructed`), or the view goes away (`.interrupted`).

The engine records `campaign_shown` and `campaign_action_completed(action=request_review)`. An
abandoned request is still `completed` for the engine, because the system never says whether it
showed a prompt either; the campaign's outcome is read in App Store Connect.

## 6. What was removed in 0.4.0, and where it went

| Removed | Now |
|---|---|
| `ReviewPolicy`, `ReviewRules`, `ReviewPrompter`, signals, blockers, cooldowns, moments | the `review_ask` campaign's triggers, audience and limits |
| `ReviewScreenMoment` and the own review screen after What's New | not made (rating R2, R3, K1): the placement is `system` |
| `ReviewState` and its stores | the engine's own record (`shown_by_app_version`) |
| `ReviewMetrics` and `review_requested` | the engine's `campaign_*` events |
| `AppVersion` | the app's own version type, or swift-app-campaign's `CampaignVersion` |
| Feedback (`FeedbackDraft`, mail and HTTP senders) | swift-app-support (appgrowstack R7) |
| `ReviewTesting` | nothing to fake: the app passes a closure |

## 日本語の要約

**何のためのパッケージか。** キャンペーンの件が「頼む」と決めたときに、画面が落ち着いてから iOS の評価のダイアログ（`RequestReviewAction`）を開く。いつ・誰に・何回頼むかは持たない。それは swift-app-campaign の型 `review_ask` の件（きっかけ・相手・回数）が決める。

**作らないもの。** 自前の星の画面・「気に入っていますか？」の前置き・満足した人だけを App Store へ送る分岐・見返り・ボタンからの依頼・評価のお願いの自前の画面。審査ガイドライン 5.6.1・3章の前書き（filtered）・3.2.2(x)・5.6.3 が理由。件のプレースメントは種類 `system` で、見た目を持たずにすぐ `request_review` を動かす。

**構成。** `ReviewCore`（Foundation だけ。依頼の結果と、設定の行に置く「レビューを書く」のリンク）と `ReviewSwiftUI`（StoreKit を import する唯一のターゲット。`ReviewRequestBridge` と `.reviewRequests`）。外部の依存は無い。キャンペーンにはクロージャで渡す（`.requestReview { await review.requestSystemPrompt() }`）。

**このパッケージが見ること。** アプリが前面にいる・シートが出ていない・画面が落ち着いて1.8秒（R8）。外れたら呼ばずに取りやめる。iOS は出したかを返さないので、キャンペーンの側ではいつも completed で、成果は ASC の評価の件数と平均で読む。

**0.4.0 で消した物。** 判定（`ReviewPolicy`・`ReviewRules`・`ReviewPrompter`）・自前の画面の瞬間・状態の置き場所・計測・`AppVersion`・要望（swift-app-support へ）・`ReviewTesting`。
