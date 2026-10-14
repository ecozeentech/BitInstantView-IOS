# BitInstantView — App Store Readiness Assessment

Last reviewed: 2026-10-14, against the public
[App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
and the live `https://www.bitinstantview.com` website as it responded on
that date. This is an engineering assessment, not a legal or compliance
opinion, and it is **not** a guarantee of Apple's approval.

## 1. What was actually inspected

Direct HTTP inspection of the live site (via `curl`, from this build
environment) confirmed:

| Route | Status | Notes |
|---|---|---|
| `/` | 200 | Livewire/Alpine.js SPA shell ("Bitinstantview — Trade Smarter") |
| `/terms` | 200 | Reachable, non-trivial content |
| `/privacy` | 200 | Reachable, non-trivial content |
| `/login` | 200 | Email/password form + **"Continue with Google"** → `/auth/google/redirect` |
| `/register` | 200 | Reachable |
| `/forgot-password` | 200 | Reachable |
| `/profile`, `/dashboard`, `/kyc` | 302 | Redirects (to login) — gated by authentication, could not be inspected further without a real account |
| `/robots.txt` | 200 | Disallows crawling of `/dashboard`, `/wallet`, `/portfolio`, `/markets`, `/kyc`, `/profile`, `/staking`, `/mining`, `/copy-trading`, `/bots`, `/signals`, `/predictions`, `/marketplace`, `/academy`, `/support`, `/referrals`, `/admin`, `/login`, `/register`, and more — i.e. almost the entire authenticated product surface |
| `/sitemap.xml` | 200 | Public pages only: home, about, features, faq, contact, terms, privacy, disclaimer |

The homepage's own in-page search index (embedded JSON) additionally
confirms the product surface includes: markets (all/gainers/losers,
watchlist, news), trading (buy crypto, portfolio, wallet, alerts), products
(copy trading, AI bots, predictions, signals, marketplace), earn (staking,
mining), an affiliate/referral program, and standard resource pages
(about, features, academy, FAQ, support, contact, risk disclaimer). A
cookie-consent banner is present on first load with explicit accept/reject
controls.

**No credentials for a real BitInstantView account were available**, so
anything behind `/login` (the actual dashboard, wallet, KYC flow, trade
execution, deposit/withdrawal, or account-deletion UI) could **not** be
inspected directly. Everything below that depends on that authenticated
surface is marked as **unverified** rather than assumed safe.

## 2. Minimum functionality (Guideline 4.2) — risk, not a pass

Apple is explicit that a WebView wrapper around an existing website,
without "sufficient functionality... distinct from a mobile website," may
be rejected. This app:

- Does **not** fabricate any native feature, balance, chart, or trading
  capability the website doesn't actually provide.
- Does add real native value: a branded launch screen, a single
  correctly-configured WKWebView with reliable progress/loading, failure,
  and offline states; a centralized, unit-tested URL/navigation-security
  policy; native back-gesture support; accessible (VoiceOver-labeled,
  48pt-minimum-hit-area) recovery controls; safe external-link handoff to
  Safari/Mail/Phone; system light/dark appearance support for the native
  shell; and a native Settings screen for the legal pages and account
  management.
- Is still, fundamentally, a WebView-first product. **This is the single
  biggest subjective App Store risk for this submission** and cannot be
  fully resolved by code alone — it depends on how differentiated Apple's
  reviewer judges the live product to be relative to a mobile browser
  bookmark. Recommended mitigation before submission: review the current
  live site for any additional native-feeling touches (push notifications
  for price alerts, for example) that the business is willing to support
  server-side, since those would strengthen this assessment. None have
  been added here, because the brief explicitly prohibits fabricating
  functionality the service doesn't support.

## 3. Account creation & deletion (Guideline 5.1.1(v))

- The live site supports account creation (`/register`) and therefore
  Apple's account-deletion requirement applies if the final build offers
  account creation inside the app (it does, via the WebView).
- **Verified:** `/profile` returns a 302 redirect (i.e., it exists and is
  gated by authentication, consistent with an account-settings page) and
  the Terms of Service page states: *"You may stop using the Platform and
  close your Account at any time, subject to settling any pending
  transactions, open positions, or locked staking and mining terms first."*
  This confirms account closure is a real, documented feature of the
  service.
- **Not verified (no demo account available):** the exact in-product path
  and whether deletion is self-service (immediate) or requires a support
  request. The app does **not** claim deletion is instant or self-service
  beyond what the website itself does.
- **Implementation in this app:** `SettingsScreen` has a "Manage or Delete
  Account" row that is explicit it requires signing in on the website
  (`AppConstants.accountRowSubtitle`) and links to `AppConfig.accountSettingsUrl`
  (`/profile`). The app never claims an account was deleted; it only ever
  provides a reachable path to the real feature.
- **Outstanding dependency:** before submission, the app owner should
  confirm with a real account that `/profile` (or wherever the website
  ends up routing to) actually exposes a deletion/closure action, and that
  the row's destination URL still matches. If the website's self-service
  deletion path lives at a different URL, update `AppConfig.accountSettingsUrl`
  accordingly.

## 4. Authentication (Guideline 5.1.1 / general security)

- Login, registration, password reset, and a third-party ("Continue with
  Google") option are confirmed live on the website.
- The app does **not** intercept, read, log, or store credentials, tokens,
  session cookies, or recovery codes anywhere in Dart code — the login
  form is rendered and submitted entirely inside WKWebView, which the app
  never inspects via JavaScript injection or a JavaScript bridge (none is
  added).
- `onSslAuthError` is wired to unconditionally call `.cancel()` — the app
  never offers to proceed past an invalid certificate.
- The confirmed Google OAuth redirect (`/auth/google/redirect` →
  `accounts.google.com`) is allowed to load **inside** the same WebView
  (see `AppConfig.trustedAuthBridgeHosts`) rather than being bounced to the
  system browser, specifically so the OAuth callback returns to the same
  WKWebView session/cookie jar instead of an unrelated Safari session.
- **Guideline 4.8 (Sign in with Apple) risk:** because the site offers
  Google sign-in, Apple's reviewers *may* ask for an equivalent
  privprivacy-preserving option (Sign in with Apple), or for the login to
  meet the limited-data-collection alternative. This app does not
  implement any native login UI (everything happens inside the website's
  own WebView-rendered form), so there is no Dart-level "third-party login
  SDK" being added here — but Apple's guideline has in the past still been
  applied to WebView-embedded OAuth buttons in some reviews. **This is a
  genuine, unresolved App Store risk that requires either (a) the
  BitInstantView backend adding Sign in with Apple as a login option, or
  (b) accepting the risk that Guideline 4.8 may be raised during review.**
  This cannot be fixed from the Flutter client alone.
- Password-manager/autofill and keyboard behavior rely on WKWebView's
  standard form handling (`autocomplete="username"` /
  `autocomplete="current-password"` are present on the live login form),
  which WKWebView supports natively; this could not be interactively
  confirmed without an iOS Simulator in this environment (see
  `docs/TEST_REPORT.md`).

## 5. Financial / cryptocurrency functionality (Guideline 3.1.5(b) and related)

BitInstantView's own marketing copy and in-page product index describe
spot trading, copy trading, AI-driven trading bots, staking, and mining —
i.e., a cryptocurrency exchange/investment product, not just a price
tracker.

- **This app does not implement any of that functionality natively.**
  Every trade, deposit, withdrawal, stake, or bot action happens entirely
  on the website, inside the WebView, subject to whatever eligibility
  checks, KYC, regional restrictions, and risk disclosures the website
  itself already enforces. The app does not bypass, hide, or duplicate
  any of them.
- **Not verified from this repository:** BitInstantView's money-transmission
  licensing, regulatory registration (e.g., state money-transmitter
  licenses, FinCEN MSB registration, or equivalent in other jurisdictions),
  or geographic availability restrictions. No license, registration, or
  regulatory claim is made anywhere in this app's code or copy — none
  should be invented, and none has been.
- **Outstanding business/legal dependency:** the app owner should confirm
  BitInstantView's current regulatory status and be prepared to answer
  Apple's App Review questions about it; Apple has in the past asked
  crypto-exchange apps for proof of appropriate licensing in each
  distribution territory. This is outside the scope of a client-side
  Flutter change.

## 6. Payments (Guideline 3.1)

- No in-app purchase, subscription, or StoreKit integration has been
  added. The website's own payment/deposit flows (if any involve real
  fiat currency rails rather than Apple's digital-goods rules) are left
  entirely to the website, consistent with Apple's guidance that
  "real-world goods and services" (which fiat-funded crypto purchases
  typically are, for App Review purposes) are exempt from the in-app
  purchase requirement — but this exemption determination should be
  confirmed by the app owner with Apple directly if asked, since the
  specifics of BitInstantView's payment rails were not inspectable without
  a funded account.

## 7. Privacy, permissions, and tracking

- **Permissions requested by this app: none beyond standard network
  access.** No camera, photo library, microphone, location, contacts, or
  notification permission is requested, because no feature in this build
  needs one. `Info.plist` contains no `NS*UsageDescription` keys as a
  result — if a future feature needs one, add the specific usage
  description at that time, not preemptively.
- **App Tracking Transparency (ATT):** not triggered by this app's own
  code (no advertising identifier access, no cross-app/cross-site tracking
  SDK added). The live website does set first-party session/XSRF cookies
  (`bitinstantview-session`, `XSRF-TOKEN`, both `secure`, the session
  cookie additionally `httponly`) and shows its own cookie-consent banner
  for "non-essential cookies" — those are the website's responsibility to
  disclose in its own privacy policy and cookie banner (both confirmed
  reachable, see §1), not something this app's own ATT prompt covers.
  **Not verified:** whether the website loads any third-party analytics or
  advertising script that would independently trigger ATT; a full
  JavaScript/network trace of the live page was not performed from this
  text-only inspection. The app owner should run the real site under a
  network inspector (e.g. Charles Proxy, or Safari Web Inspector against a
  simulator) before submission to confirm.
- **Data the app itself collects: none.** The app does not run its own
  analytics, crash reporting, or telemetry SDK. All data in transit is
  between the user's device and `bitinstantview.com` (plus, when the user
  explicitly taps an external link, whatever destination they chose) —
  governed by the website's own Privacy Policy, which is reachable from
  Settings.
- **App Store Privacy ("nutrition label") questionnaire:** should be
  completed based on the website's actual server-side data practices
  (account data, financial/trading data, device/usage data the site's own
  analytics may collect), not solely on this client's code, since a
  WebView's network traffic is the website's data collection, attributable
  to the app under App Store Connect's privacy rules. This requires input
  from whoever operates the BitInstantView backend and cannot be completed
  from this repository alone.

## 8. Security review summary

- HTTPS-only navigation inside the WebView (`UrlPolicy` blocks plain HTTP,
  including to the first-party host, rather than silently upgrading it).
- No custom certificate trust logic; `onSslAuthError` always cancels.
- No JavaScript bridge is exposed to web content (`addJavaScriptChannel` is
  never called).
- No credentials, tokens, or cookies are read, logged, or persisted outside
  WKWebView's own standard, sandboxed cookie/session storage.
- Debug-only WebView inspection (`setOnConsoleMessage`, Safari Web
  Inspector `isInspectable`, etc.) is not enabled in this app's
  configuration.
- Lookalike-domain protection and scheme allowlisting are unit-tested (see
  `test/core/navigation/url_policy_test.dart`).

## 9. Outstanding checklist for the app owner before submission

These cannot be completed from this repository and are **not** marked done:

- [ ] Register (or confirm) the real bundle identifier in the Apple
      Developer account and replace the `com.bitinstantview.app` placeholder
      in `ios/Runner.xcodeproj/project.pbxproj`.
- [ ] Provide App Store Connect distribution signing (certificates,
      provisioning profile) — none is configured or implied by this repo.
- [ ] Confirm the real support email/URL for App Store Connect's "Support
      URL" / "Marketing URL" fields — none is invented here.
- [ ] Confirm BitInstantView's regulatory status for each territory the
      app will be distributed in (see §5).
- [ ] Decide how to respond if Apple raises Guideline 4.8 (Sign in with
      Apple) during review (see §4).
- [ ] Confirm, with a real account, the exact self-service account
      deletion path and update `AppConfig.accountSettingsUrl` if it differs
      from `/profile`.
- [ ] Run a full network trace of the live site (ideally from an iOS
      Simulator/device) to confirm no undisclosed third-party tracking
      script is present before completing the App Store privacy
      questionnaire.
- [ ] Decide on age rating, given the site's cryptocurrency trading
      content (Apple's age-rating questionnaire has specific
      "Unrestricted Web Access" and financial-content categories that
      apply to WebView apps).
- [ ] Prepare App Store screenshots, description, and (if the account
      requires sign-in to review) a working demo account and reviewer
      instructions — none of this is fabricated here.
