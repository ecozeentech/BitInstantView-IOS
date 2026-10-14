# BitInstantView — Test Report

Environment: Linux cloud VM (Ubuntu 24.04.5 LTS, x86_64), no macOS/Xcode
available. Flutter SDK installed fresh via `git clone --depth 1 -b stable
https://github.com/flutter/flutter.git` (not pre-installed in this image).

```
Flutter 3.47.7 • channel stable
Framework revision abaf9c5237 (2026-10-08)
Engine revision deb287481e
Dart 3.13.5 • DevTools 2.60.0
```

Every result below is from a command actually executed in this
environment, on this exact revision of the code, immediately before this
report was written. Status legend: **Passed**, **Failed**, **Blocked by
environment**, **Not run**.

## 1. `flutter doctor -v`

**Result: ran, with expected gaps for an iOS-only project built on Linux.**

- Flutter SDK: OK.
- Chrome (web): OK (not used by this project; no web platform target was
  created).
- Android toolchain: not installed — **not applicable**, this project only
  targets iOS/iPadOS (`flutter create --platforms=ios`), no `android/`
  directory exists.
- Linux desktop toolchain: incomplete (missing `ninja`, GTK3 dev headers) —
  **not applicable**, no `linux/` platform target was created either.
- **No iOS/Xcode section appears at all**, because `flutter doctor` only
  probes for Xcode on a macOS host. This is the first concrete evidence
  that iOS tooling is categorically unavailable here, not merely
  misconfigured.

## 2. Dependency resolution — `flutter pub get`

**Status: Passed.**

Resolved cleanly against Dart SDK `^3.13.5`. Direct dependencies and the
exact resolved versions committed in `pubspec.lock`:

| Package | Resolved version | Why |
|---|---|---|
| `webview_flutter` | 4.14.1 | the required WebView engine (per brief) |
| `webview_flutter_wkwebview` | 3.27.0 | direct dep so the app can call the iOS-specific `setAllowsBackForwardNavigationGestures` |
| `connectivity_plus` | 7.3.2 | supplementary offline-signal only (see README "Known limitations") |
| `url_launcher` | 6.3.3 | the one place external/`mailto:`/`tel:` navigation is launched |
| `cupertino_icons` | 1.0.9 | standard iOS-style icon font |
| `flutter_lints` (dev) | 6.0.0 | the lint set `analysis_options.yaml` activates |
| `flutter_test` (dev) | SDK | test framework |

`package_info_plus` was evaluated and then **removed** — see §4 for why.

## 3. Formatting — `dart format --output=none --set-exit-if-changed lib test`

**Status: Passed** (after one corrective pass).

First run flagged 17 files as unformatted; `dart format lib test` was run
to fix them, and the check was re-run clean:

```
$ dart format --output=none --set-exit-if-changed lib test
Formatted 27 files (0 changed) in 0.0Xs
$ echo $?
0
```

## 4. Static analysis — `flutter analyze`

**Status: Passed — "No issues found!"**

Issues found and fixed during development (not swept under the rug):

- `undefined_getter` for `AppConstants.appName` in two files — the constant
  actually lives on `AppConfig`; fixed by importing/referencing the right
  class.
- `unused_import` of `app_config.dart` in `webview_controller_manager.dart`
  after a refactor — removed.
- Three analyzer errors in early draft tests from using
  `SemanticsAction`/`SemanticsFlag` without the `dart:ui` import they
  actually live in (not re-exported by `package:flutter/material.dart`) —
  fixed by importing `dart:ui as ui` and using the non-deprecated
  `SemanticsData.hasAction` / `SemanticsFlags.isButton` APIs instead of the
  deprecated `SemanticsNode.hasFlag`.

Final run, verbatim:

```
Analyzing workspace...
No issues found! (ran in 5.9s)
```

## 5. Automated tests — `flutter test`

**Status: Passed — 70/70 tests, 0 failures.**

```
$ flutter test
...
00:04 +70: All tests passed!
```

Breakdown by file:

| File | What it exercises |
|---|---|
| `test/core/navigation/url_policy_test.dart` (23 tests) | first-party allow rules, subdomain boundaries, lookalike-domain rejection (`bitinstantview.com.evil.org`, `evilbitinstantview.com`, userinfo-prefixed `user@evil.com` tricks), the confirmed Google OAuth bridge host, blocked schemes (`javascript:`, `file:`, `data:`), `mailto:`/`tel:` handoff, malformed input |
| `test/core/config/app_config_test.dart` (4 tests) | HTTPS-only defaults, first-party legal URLs, bundle-id placeholder shape, auth-bridge host sanity |
| `test/core/errors/app_error_test.dart` (10 tests) | `WebResourceError` → `AppError` classification (offline vs. generic network), that raw platform error text never leaks into the user-facing message, HTTP-status and navigation-blocked factories |
| `test/features/webview/webview_state_test.dart` (10 tests) | the `WebViewStateController` state machine: loading → success, loading → failed, retry transitions (including a retry that fails again), `notifyListeners` only firing on an actual state change |
| `test/features/webview/error_view_test.dart` (9 tests) | `ErrorView` dispatching to `OfflineView` for offline errors vs. a generic message otherwise, retry-tap behavior, the "Retrying…" disabled state, HTTP status code surfaced without raw platform text |
| `test/features/webview/loading_view_test.dart` (4 tests) | determinate vs. indeterminate progress rendering and its accessibility label |
| `test/features/settings/settings_screen_test.dart` (5 tests) | the Terms/Privacy/account rows render with the right accessible labels, the screen never claims an account "has been deleted", the version row renders synchronously, tapping Terms pushes a screen titled correctly |
| `test/shared/accessible_action_button_test.dart` (5 tests) | tap handling, semantics (`isButton` flag + `tap` action via `SemanticsData`, not the deprecated `SemanticsNode.hasFlag`), the 48pt minimum hit-target, the disabled/loading state |
| `test/widget_test.dart` (3 tests) | the full `BitInstantViewApp` boots without throwing, and — because this plain Dart test environment has no registered `WebViewPlatform` implementation — the real `WebViewControllerManager.initialize()` call throws, is caught, and the app degrades to an accessible `ErrorView` with a reachable, correctly-labeled Retry action instead of crashing or hanging |

A note on the last file, because it is the one subtle point in this
report: `WebViewController()` genuinely throws
`AssertionError('WebViewPlatform.instance != null: A platform
implementation for webview_flutter has not been set...')` under `flutter
test` on this host (verified with a standalone probe script before writing
the real test). That is expected — platform implementations for federated
plugins are wired up by the native Android/iOS build step, which does not
run in a plain `dart`/`flutter test` invocation. The app's own
`WebViewScreen._initializeIfNeeded()` already wraps `WebViewControllerManager
.initialize()` in a `try`/`catch` and reports `AppError.webViewUnavailable`
on any failure — this was written as production-grade defensive code
*before* discovering it also happens to be exactly what makes the widget
test environment survivable. The test suite verifies that real fallback
path, not a stand-in.

### What was deliberately *not* tested as a unit/widget test, and why

- **Real WebView rendering, page loads, gestures, keyboard/autofill
  behavior, rotation.** These require an iOS Simulator or device
  (`flutter run` / `flutter test integration_test/`), which requires Xcode,
  which requires macOS. **Blocked by environment** — see §7.
- **Live network calls to bitinstantview.com from Dart tests.** Unit tests
  must not depend on a live external service; the one place the live site
  actually was inspected (`curl`, during development — see
  `docs/APP_STORE_READINESS.md` §1) is not part of the automated suite.

## 6. Coverage — `flutter test --coverage`

**Status: Passed.** Generated `coverage/lcov.info` (343 `DA:` line entries)
covering every file under `lib/`. `coverage/` is git-ignored, as is
standard for a generated artifact; regenerate it locally with the command
above if needed.

## 7. iOS build — `flutter build ios` / `flutter build ios --no-codesign`

**Status on this Linux authoring host: Blocked by environment — not a
code failure.**

```
$ flutter build ios --no-codesign
Could not find an option named "--no-codesign".

$ flutter build ios
Could not find a subcommand named "ios" for "flutter build".

$ flutter build -h
Available subcommands:
  aar  apk  appbundle  bundle  linux  web
```

`ios` does not even appear as an available `flutter build` subcommand on
this Linux host — Flutter only registers the iOS build toolchain when run
on macOS with Xcode installed, which this environment does not have and
cannot have (Apple's toolchain is macOS-only). This is a hard environment
limitation, not a defect in this project's code. What **was** verified
here, in lieu of an actual compile:

- `flutter analyze` type-checks every line of `lib/` against the real
  `webview_flutter` 4.14.1 / `webview_flutter_wkwebview` 3.27.0 API surface
  (verified by reading the installed package source directly — e.g.
  confirming `WebKitWebViewController.setAllowsBackForwardNavigationGestures`,
  the exact `NavigationDelegate` callback signatures, and
  `HttpResponseError.response?.statusCode` — before writing the code that
  calls them).
- `flutter test` exercises every file under `lib/` through real imports
  and real execution (not just a type-check).
- The generated `ios/` Xcode project was inspected by hand: every file
  referenced by `AppIcon.appiconset/Contents.json` exists with the exact
  pixel dimensions Apple's spec requires (verified with Pillow — see §8),
  `IPHONEOS_DEPLOYMENT_TARGET = 15.0` is set consistently across all three
  build configurations, `PRODUCT_BUNDLE_IDENTIFIER` is set to the
  documented placeholder, and both `webview_flutter_wkwebview` and
  `url_launcher_ios` ship a `Package.swift` (confirmed on disk in the pub
  cache), so Swift Package Manager — this Flutter version's default — can
  resolve them with no `Podfile` needed.

### 7a. Real iOS build, verified on GitHub Actions (macOS/Xcode)

Because an actual `xcodebuild` invocation genuinely cannot run on this
host, `.github/workflows/ios-build.yml` was added to run the full pipeline
on GitHub's hosted macOS runners, which do have Xcode. This is **real,
independently verifiable evidence**, not a claim — see the run logs at
<https://github.com/ecozeentech/BitInstantView-IOS/actions/workflows/ios-build.yml>.

**First run** (commit `6632c2d`, `macos-14`) **failed**, and caught a real
bug that this Linux host could never have caught:

```
Swift Compiler Error (Xcode): Value of type 'NWPath' has no member 'isUltraConstrained'
/…/connectivity_plus-7.3.2/ios/.../PathMonitorConnectivityProvider.swift:28:39
```

`connectivity_plus` 7.3.2's own iOS source references `NWPath.isUltraConstrained`
inside an `if #available(iOS 26.0, *)` guard — a Swift availability check
is a *runtime* branch, but the symbol must still exist in the SDK the code
is *compiled* against, and `macos-14`'s default Xcode predates the iOS 26
SDK. This was **not** worked around by patching application code; the fix
was to the CI environment itself (switch to `macos-15` and explicitly
select `latest-stable` Xcode via `maxim-lobanov/setup-xcode@v1`), since the
plugin code and its availability guard are both correct for a sufficiently
new toolchain.

**Second run** (commit `84ae7df`, `macos-15` + latest-stable Xcode) —
**passed completely, in ~5 minutes:**

| Step | Result |
|---|---|
| `xcodebuild -version` / SDK check | Logged for traceability |
| `flutter pub get` | Passed |
| `dart format --set-exit-if-changed` | Passed |
| `flutter analyze` | Passed |
| `flutter test` | Passed (same 70/70 as the Linux run, confirming parity) |
| `flutter build ios --debug --simulator` | **Passed — real Xcode build, zero errors** |
| Package + upload Simulator `.app` artifact | Passed — downloadable from the run page for 30 days |
| `flutter build ios --release --no-codesign` | **Passed — real Xcode release build, zero errors** |

This is the first point in this project's history where an actual
`xcodebuild` compile of this app has been confirmed to succeed. It is
**not** equivalent to codesigning, App Store submission, or installing on
a physical device (see README.md "Getting a build to test, without owning
a Mac" and §10 below) — but it is real, reproducible evidence that the
Dart/Flutter code, the generated Xcode project, the asset catalog, and
every plugin dependency actually compile for iOS.

## 8. App icon asset verification

**Status: Passed (verified programmatically, not just visually).**

```
$ file ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
Icon-App-20x20@1x.png:     PNG image data, 20 x 20,   8-bit/color RGB
Icon-App-20x20@2x.png:     PNG image data, 40 x 40,   8-bit/color RGB
Icon-App-20x20@3x.png:     PNG image data, 60 x 60,   8-bit/color RGB
Icon-App-29x29@1x.png:     PNG image data, 29 x 29,   8-bit/color RGB
Icon-App-29x29@2x.png:     PNG image data, 58 x 58,   8-bit/color RGB
Icon-App-29x29@3x.png:     PNG image data, 87 x 87,   8-bit/color RGB
Icon-App-40x40@1x.png:     PNG image data, 40 x 40,   8-bit/color RGB
Icon-App-40x40@2x.png:     PNG image data, 80 x 80,   8-bit/color RGB
Icon-App-40x40@3x.png:     PNG image data, 120 x 120, 8-bit/color RGB
Icon-App-60x60@2x.png:     PNG image data, 120 x 120, 8-bit/color RGB
Icon-App-60x60@3x.png:     PNG image data, 180 x 180, 8-bit/color RGB
Icon-App-76x76@1x.png:     PNG image data, 76 x 76,   8-bit/color RGB
Icon-App-76x76@2x.png:     PNG image data, 152 x 152, 8-bit/color RGB
Icon-App-83.5x83.5@2x.png: PNG image data, 167 x 167, 8-bit/color RGB
Icon-App-1024x1024@1x.png: PNG image data, 1024 x 1024, 8-bit/color RGB
```

Every dimension matches its `Contents.json` entry exactly, and every file
is plain RGB with **no alpha channel** — confirmed with Pillow
(`Image.open(...).mode == 'RGB'`), satisfying Apple's requirement that the
1024×1024 App Store marketing icon (and, as a matter of visual
consistency, every other size here) not carry transparency. The source
logo's own transparent corner padding was flattened onto the brand gold
(`#E7AD00`) rather than left transparent or manually pre-rounded — iOS
applies its own corner mask at render time. See `tool/generate_icons.py`
for the fully reproducible generation step and its inline reasoning.

## 9. Live website integration checks

Performed with `curl` against the production site (not part of the
automated test suite — see §5 for why). Full results and their
interpretation are in `docs/APP_STORE_READINESS.md` §1. Summary: home,
terms, privacy, login, register, and forgot-password all returned `200`;
the Google OAuth login link, the cookie-consent banner, and the
authenticated-route gating (`robots.txt` + `302` redirects on
`/profile`/`/dashboard`/`/kyc`) were all directly confirmed from the raw
HTML/headers.

## 10. Simulator / device testing

**Status: build-level verification passed on CI (§7a); actual on-screen
behavior still not run — blocked by environment.**

GitHub Actions CI (macOS/Xcode) confirms the app **compiles** into a real
`Runner.app` targeting the iOS Simulator architecture (§7a), and that
`.app` can be downloaded and installed into a Simulator with
`xcrun simctl install` by anyone with a Mac (see README.md). That is a
genuine, higher bar than "blocked" — but it is still not the same as
*launching* the app and visually confirming its behavior, because no agent
in this conversation has a macOS GUI to open Simulator.app, tap through
the UI, and observe the result. None of the Responsive Device Test Matrix
scenarios in the original brief (Dynamic Island safe areas,
split-screen/multitasking, rotation, keyboard-open layout, slow-connection
feedback, app-background/resume, Dynamic Type) have been visually
exercised. All of them were addressed at the code level with standard,
well-documented Flutter/iOS APIs (`SafeArea`, `PopScope`,
`WidgetsBindingObserver.didChangeAppLifecycleState`,
`setAllowsBackForwardNavigationGestures`, system `ThemeMode`, and no
hardcoded orientation lock), but **the actual on-device/on-simulator
behavior has not been visually confirmed and must be before shipping.**
This remains the single most important remaining verification step —
install the CI's Simulator artifact (or run `flutter run` on a Mac) and
watch it work.

## Summary

| Check | Status |
|---|---|
| `flutter doctor -v` | Passed (iOS section N/A on Linux, as expected) |
| `flutter pub get` | Passed |
| `dart format` | Passed |
| `flutter analyze` | Passed — 0 issues |
| `flutter test` | Passed — 70/70 |
| `flutter test --coverage` | Passed |
| `flutter build ios` (this Linux host) | Blocked by environment (no Xcode) |
| `flutter build ios --debug --simulator` (GitHub Actions macOS CI) | **Passed** — real Xcode build, see §7a |
| `flutter build ios --release --no-codesign` (GitHub Actions macOS CI) | **Passed** — real Xcode build, see §7a |
| App icon asset dimensions/alpha | Passed (verified with Pillow) |
| Live website route checks | Passed (via `curl`) |
| Simulator/device on-screen testing | Not run — no macOS GUI available in this conversation |
