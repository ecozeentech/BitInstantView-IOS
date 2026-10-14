import '../config/app_config.dart';

/// How a given destination URL should be handled.
enum LinkTarget {
  /// Load inside the app's own WebView.
  webView,

  /// Hand off to the system browser (Safari).
  externalBrowser,

  /// Hand off to a native OS handler, e.g. the Phone or Mail app.
  systemHandler,

  /// Refuse to navigate anywhere.
  blocked,
}

/// Centralized, side-effect-free navigation policy for BitInstantView.
///
/// This class never performs any navigation itself and never touches a
/// platform channel; it only classifies a URL so a caller (the WebView's
/// navigation delegate, or [ExternalLinkService]) can decide what to do.
/// Keeping it pure makes every rule unit-testable without a device, an
/// emulator, or a live network connection.
class UrlPolicy {
  const UrlPolicy._();

  static const Set<String> _allowedWebViewHosts = {
    AppConfig.primaryDomain,
    'www.${AppConfig.primaryDomain}',
  };

  static const Set<String> _trustedAuthBridgeHosts =
      AppConfig.trustedAuthBridgeHosts;

  static const Set<String> _systemHandlerSchemes = {
    'mailto',
    'tel',
    'sms',
    'facetime',
  };

  /// Schemes that are never safe to navigate to or hand off, regardless of
  /// host: they can execute code in the page context, read local files, or
  /// otherwise escape the sandboxed first-party navigation this app is
  /// meant to provide.
  static const Set<String> _blockedSchemes = {
    'javascript',
    'file',
    'data',
    'blob',
    'about',
  };

  /// Classifies [rawUrl] into a [LinkTarget].
  ///
  /// Returns [LinkTarget.blocked] for any URL that fails to parse, so a
  /// malformed or malicious string can never fall through to a more
  /// permissive branch by accident.
  static LinkTarget classify(String rawUrl) {
    final Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return LinkTarget.blocked;
    }
    return classifyUri(uri);
  }

  /// Same as [classify], but takes an already-parsed [Uri]. Exposed
  /// separately so callers that already have a [Uri] (and tests) do not pay
  /// for a redundant parse/re-parse round trip.
  static LinkTarget classifyUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();

    if (_blockedSchemes.contains(scheme)) {
      return LinkTarget.blocked;
    }

    if (_systemHandlerSchemes.contains(scheme)) {
      return uri.path.isEmpty && uri.host.isEmpty
          ? LinkTarget.blocked
          : LinkTarget.systemHandler;
    }

    if (scheme != 'http' && scheme != 'https') {
      // Unrecognized custom scheme (e.g. a deep link into another app).
      // There is no verified, legitimate use of a custom scheme on
      // bitinstantview.com today, so these are blocked rather than silently
      // handed to whatever app on the device happens to claim them.
      return LinkTarget.blocked;
    }

    if (uri.host.isEmpty) {
      return LinkTarget.blocked;
    }

    final host = uri.host.toLowerCase();

    if (_isFirstPartyHost(host)) {
      // Reject insecure first-party navigation outright rather than silently
      // upgrading it: a plain-HTTP link to the first-party domain should not
      // normally occur, and treating it as a safe allowlist hit would mask a
      // misconfiguration instead of surfacing it.
      return scheme == 'https' ? LinkTarget.webView : LinkTarget.blocked;
    }

    if (scheme == 'https' && _trustedAuthBridgeHosts.contains(host)) {
      return LinkTarget.webView;
    }

    return scheme == 'https' ? LinkTarget.externalBrowser : LinkTarget.blocked;
  }

  /// Whether [host] is the exact first-party apex domain or a real
  /// subdomain of it (`sub.bitinstantview.com`), never a substring match.
  ///
  /// This guards against lookalike hosts such as
  /// `bitinstantview.com.evil.org` (contains the domain as a substring, but
  /// is not a subdomain of it) or `evilbitinstantview.com` (same apex-looking
  /// suffix, different registrable domain).
  static bool _isFirstPartyHost(String host) {
    for (final allowed in _allowedWebViewHosts) {
      if (host == allowed || host.endsWith('.$allowed')) {
        return true;
      }
    }
    return false;
  }

  /// True when [uri] points at the verified first-party domain over HTTPS.
  /// Convenience wrapper used by UI code that only needs a yes/no answer
  /// (for example, to decide whether a loaded page's host still belongs to
  /// BitInstantView).
  static bool isFirstParty(Uri uri) =>
      uri.scheme == 'https' && _isFirstPartyHost(uri.host.toLowerCase());
}
