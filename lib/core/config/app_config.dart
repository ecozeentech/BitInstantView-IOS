/// Centralized, immutable runtime configuration for BitInstantView.
///
/// Keeping every externally meaningful value (URLs, allowed hosts, bundle
/// identifier placeholder) in one place avoids the navigation policy, the
/// WebView screen, and the settings screen each hard-coding their own copy
/// of the same strings.
class AppConfig {
  const AppConfig._();

  /// Display name used throughout the UI and in native metadata.
  static const String appName = 'BitInstantView';

  /// Human-readable version shown in Settings. Kept as a plain constant
  /// instead of pulling in `package_info_plus`: a single WebView-wrapper
  /// screen does not justify an extra platform-channel dependency, and this
  /// value is trivial to keep in sync with the `version:` line in
  /// `pubspec.yaml` by hand. Update both together on every release.
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  /// The official BitInstantView website, loaded as the app's primary
  /// content surface. Must always be HTTPS.
  static const String homeUrl = 'https://www.bitinstantview.com/';

  /// Legal pages that must stay reachable from inside the app.
  static const String termsUrl = 'https://www.bitinstantview.com/terms';
  static const String privacyUrl = 'https://www.bitinstantview.com/privacy';

  /// Account settings route on the website. Account deletion for
  /// BitInstantView is only possible after signing in on the website itself;
  /// the app does not and cannot perform deletion on the user's behalf. This
  /// route is reachable but gated by the website's own authentication, which
  /// is confirmed by `robots.txt` disallowing crawlers from it while still
  /// returning the site's normal (non-404) redirect-to-login response.
  static const String accountSettingsUrl =
      'https://www.bitinstantview.com/profile';

  /// Verified apex domain for first-party navigation decisions. Exposed
  /// separately from [allowedWebViewHosts] so [UrlPolicy] can enforce real
  /// subdomain boundaries (`*.bitinstantview.com`) instead of a substring
  /// match that a hostile domain like `bitinstantview.com.evil.org` could
  /// defeat.
  static const String primaryDomain = 'bitinstantview.com';

  /// Hosts that may load directly inside the in-app WebView because they are
  /// either the first-party domain or a third-party identity provider that
  /// the live website itself redirects to as part of a legitimate sign-in
  /// flow (confirmed by inspecting https://www.bitinstantview.com/login,
  /// which links to `/auth/google/redirect`). Keeping the OAuth hop inside
  /// the WebView preserves the session/cookie context started by the
  /// first-party page; bouncing it out to the system browser would start an
  /// unrelated browsing session and likely break the callback.
  static const Set<String> trustedAuthBridgeHosts = {'accounts.google.com'};

  /// Placeholder bundle identifier. No Apple Developer Program registration
  /// could be verified from this repository, so this value MUST be replaced
  /// with the identifier actually registered to the publishing developer
  /// account before archiving for App Store submission. See
  /// docs/APP_STORE_READINESS.md.
  static const String bundleIdentifierPlaceholder = 'com.bitinstantview.app';
}
