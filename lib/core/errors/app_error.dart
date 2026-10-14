import 'package:webview_flutter/webview_flutter.dart';

import '../constants/app_constants.dart';

/// Broad category of a user-facing failure, used to pick the right
/// recovery UI and message. Deliberately coarse: the UI never needs to know
/// the exact platform error code, only how to react to it.
enum AppErrorType {
  /// No usable network connection was available.
  offline,

  /// The main frame failed to load for a reason other than connectivity
  /// (DNS failure, TLS handshake failure, timeout, host unreachable, etc).
  network,

  /// The server responded, but with an HTTP error status code.
  http,

  /// A navigation request was intentionally blocked by [UrlPolicy].
  navigationBlocked,

  /// The WebView engine itself could not be created or crashed.
  webViewUnavailable,

  /// Anything else.
  unknown,
}

/// A sanitized, user-safe description of a failure.
///
/// [AppError] intentionally never exposes raw platform error strings,
/// stack traces, internal URLs with query parameters, or filesystem paths to
/// the UI layer: [debugDetail] is for logs only and must never be rendered.
class AppError {
  const AppError({
    required this.type,
    required this.userMessage,
    this.debugDetail,
    this.httpStatusCode,
  });

  final AppErrorType type;
  final String userMessage;
  final String? debugDetail;
  final int? httpStatusCode;

  factory AppError.offline() => const AppError(
    type: AppErrorType.offline,
    userMessage: AppConstants.offlineMessage,
  );

  factory AppError.navigationBlocked() => const AppError(
    type: AppErrorType.navigationBlocked,
    userMessage: AppConstants.blockedNavigationMessage,
  );

  factory AppError.webViewUnavailable([Object? cause]) => AppError(
    type: AppErrorType.webViewUnavailable,
    userMessage: AppConstants.genericErrorMessage,
    debugDetail: cause?.toString(),
  );

  factory AppError.httpStatus(int statusCode) => AppError(
    type: AppErrorType.http,
    userMessage: '${AppConstants.httpErrorTitlePrefix} ($statusCode).',
    httpStatusCode: statusCode,
  );

  /// Maps a platform [WebResourceError] reported by the WebView's
  /// navigation delegate onto a sanitized [AppError]. Connectivity-shaped
  /// error types are classified as [AppErrorType.offline] so the UI can show
  /// a more specific "you're offline" state; everything else becomes a
  /// generic network failure with the raw description kept out of the user
  /// message.
  factory AppError.fromWebResourceError(WebResourceError error) {
    const connectivityErrorTypes = {
      WebResourceErrorType.hostLookup,
      WebResourceErrorType.connect,
      WebResourceErrorType.timeout,
    };

    final isConnectivityError =
        error.errorType != null &&
        connectivityErrorTypes.contains(error.errorType);

    return AppError(
      type: isConnectivityError ? AppErrorType.offline : AppErrorType.network,
      userMessage: isConnectivityError
          ? AppConstants.offlineMessage
          : AppConstants.genericErrorMessage,
      debugDetail: 'code=${error.errorCode} type=${error.errorType}',
    );
  }

  factory AppError.unknown([Object? cause]) => AppError(
    type: AppErrorType.unknown,
    userMessage: AppConstants.genericErrorMessage,
    debugDetail: cause?.toString(),
  );
}
