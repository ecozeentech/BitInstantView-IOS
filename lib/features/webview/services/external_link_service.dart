import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/url_policy.dart';

/// Performs the actual platform hand-off decided by [UrlPolicy].
///
/// [UrlPolicy] only classifies a URL; this service is the single place that
/// is allowed to call into `url_launcher`, so every outbound navigation that
/// leaves the WebView goes through one auditable code path.
class ExternalLinkService {
  const ExternalLinkService();

  /// Attempts to open [uri] according to [target]. Returns true on success.
  /// Never throws: a device that cannot handle a URL (no mail client
  /// installed, no browser available, etc.) results in `false` instead of
  /// an uncaught exception reaching the UI.
  Future<bool> open(Uri uri, LinkTarget target) async {
    if (target != LinkTarget.externalBrowser &&
        target != LinkTarget.systemHandler) {
      return false;
    }

    try {
      final mode = target == LinkTarget.externalBrowser
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault;

      if (!await canLaunchUrl(uri)) {
        return false;
      }
      return await launchUrl(uri, mode: mode);
    } catch (error, stackTrace) {
      // Never let a launch failure crash the WebView; just report it to
      // developer logs (never to the user, and never including sensitive
      // query parameters beyond what the OS already logs for the launch
      // attempt itself).
      debugPrint(
        'ExternalLinkService failed to launch $uri: $error\n$stackTrace',
      );
      return false;
    }
  }
}
