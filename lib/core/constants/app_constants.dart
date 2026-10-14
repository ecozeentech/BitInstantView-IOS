import 'package:flutter/material.dart';

/// Fixed UI strings, durations, and visual constants that are not
/// configuration (see [AppConfig]) but are reused across more than one
/// widget. Keeping them here avoids copy-pasted literals drifting apart.
class AppConstants {
  const AppConstants._();

  // Brand palette, derived directly from the supplied BitInstantView logo.
  static const Color primaryGold = Color(0xFFF5B900);
  static const Color deepGold = Color(0xFFE7AD00);
  static const Color primaryBlack = Color(0xFF080808);
  static const Color white = Color(0xFFFFFFFF);
  static const Color secondaryNeutral = Color(0xFFF5F5F5);
  static const Color errorRed = Color(0xFFB00020);
  static const Color successGreen = Color(0xFF1E8E3E);

  static const Duration splashMinimumDuration = Duration(milliseconds: 400);
  static const Duration retryDebounce = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 3);

  static const String loadingLabel = 'Loading BitInstantView…';
  static const String retryLabel = 'Retry';
  static const String retryingLabel = 'Retrying…';
  static const String openInBrowserLabel = 'Open in Browser';

  static const String offlineTitle = "You're offline";
  static const String offlineMessage =
      'BitInstantView needs an internet connection to load. '
      'Check your connection and try again.';

  static const String genericErrorTitle = "This page couldn't load";
  static const String genericErrorMessage =
      'Something went wrong while loading BitInstantView. '
      'Please try again.';

  static const String httpErrorTitlePrefix = 'Server returned an error';

  static const String blockedNavigationMessage =
      'That link was blocked because it did not look like a trusted '
      'BitInstantView web address.';

  static const String externalLinkFailedMessage =
      "Couldn't open that link on this device.";

  static const String settingsTitle = 'Settings';
  static const String termsRowLabel = 'Terms of Service';
  static const String privacyRowLabel = 'Privacy Policy';
  static const String accountRowLabel = 'Manage or Delete Account';
  static const String accountRowSubtitle =
      'Sign in on the BitInstantView website to manage your account, '
      'including closing it.';
  static const String openWebsiteRowLabel = 'Open bitinstantview.com';
}
