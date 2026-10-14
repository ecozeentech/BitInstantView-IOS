import 'dart:async';

import 'package:flutter/widgets.dart' show Color;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/navigation/url_policy.dart';
import 'webview_state.dart';

/// Owns the single [WebViewController] used by [WebViewScreen] and keeps
/// all WebView configuration -- JavaScript mode, background color,
/// navigation delegate, SSL handling, and the one-time initial load -- in a
/// single, testable-by-inspection location instead of spread across the
/// widget's build method.
class WebViewControllerManager {
  WebViewControllerManager({
    required this.initialUrl,
    required this.state,
    required this.onExternalNavigation,
  });

  final String initialUrl;
  final WebViewStateController state;

  /// Invoked when a navigation request resolves to something that must
  /// leave the in-app WebView (system browser or native handler). The
  /// caller (the widget) owns [ExternalLinkService] so this manager stays
  /// free of `url_launcher` platform-channel calls.
  final void Function(Uri uri, LinkTarget target) onExternalNavigation;

  late final WebViewController controller;

  bool _disposed = false;
  bool _hasLoadedInitialUrl = false;

  /// The URL the main frame most recently started navigating to, used to
  /// tell a main-frame HTTP error apart from an incidental sub-resource
  /// one (an ad, an analytics beacon, an in-page API call) -- see
  /// [_handleHttpError]. [WebResourceRequest] (unlike [WebResourceError])
  /// has no `isForMainFrame` flag to check directly.
  String? _currentMainFrameUrl;

  /// Builds the platform WebView controller and performs the one-time
  /// initial navigation. Throws if the platform cannot provide a WebView
  /// implementation at all (for example, when running outside a real iOS
  /// host); callers should catch this and fall back to
  /// [AppError.webViewUnavailable].
  Future<void> initialize() async {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // required: the live
      // site is a Livewire/Alpine.js single-page experience that cannot
      // render or navigate without JavaScript.
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _handleNavigationRequest,
          onPageStarted: _handlePageStarted,
          onPageFinished: _handlePageFinished,
          onProgress: state.progressChanged,
          onWebResourceError: _handleWebResourceError,
          onHttpError: _handleHttpError,
          onSslAuthError: (error) => error.cancel(),
        ),
      );

    final platform = controller.platform;
    if (platform is WebKitWebViewController) {
      await platform.setAllowsBackForwardNavigationGestures(true);
    }

    await _loadInitialUrlOnce();
  }

  Future<void> _loadInitialUrlOnce() async {
    if (_hasLoadedInitialUrl) return;
    _hasLoadedInitialUrl = true;
    state.navigationStarted();
    await controller.loadRequest(Uri.parse(initialUrl));
  }

  FutureOr<NavigationDecision> _handleNavigationRequest(
    NavigationRequest request,
  ) {
    final target = UrlPolicy.classify(request.url);
    switch (target) {
      case LinkTarget.webView:
        return NavigationDecision.navigate;
      case LinkTarget.externalBrowser:
      case LinkTarget.systemHandler:
        final uri = Uri.tryParse(request.url);
        if (uri != null) {
          onExternalNavigation(uri, target);
        }
        return NavigationDecision.prevent;
      case LinkTarget.blocked:
        if (!_disposed) {
          state.failed(AppError.navigationBlocked());
        }
        return NavigationDecision.prevent;
    }
  }

  void _handlePageStarted(String url) {
    if (_disposed) return;
    _currentMainFrameUrl = url;
    state.navigationStarted();
  }

  Future<void> _handlePageFinished(String url) async {
    if (_disposed) return;
    final canGoBack = await controller.canGoBack();
    if (_disposed) return;
    state.navigationFinished(canGoBack: canGoBack);
  }

  void _handleWebResourceError(WebResourceError error) {
    if (_disposed) return;
    // Only a main-frame failure should take over the whole screen; a failed
    // sub-resource (an ad, an analytics beacon, a missing favicon) must not
    // replace valid page content with an error state.
    if (error.isForMainFrame == false) return;
    state.failed(AppError.fromWebResourceError(error));
  }

  void _handleHttpError(HttpResponseError error) {
    if (_disposed) return;
    // Only surface an HTTP error that affects the page we actually
    // navigated to; a failed sub-resource (an ad, a tracker, an in-page
    // API call) must not replace valid page content with an error state.
    if (error.request?.uri.toString() != _currentMainFrameUrl) return;
    state.failed(AppError.httpStatus(error.response?.statusCode ?? 0));
  }

  /// Reloads the page that is currently loaded (or re-attempts the initial
  /// URL if nothing ever successfully loaded).
  Future<void> retry() async {
    state.retryStarted();
    final current = await controller.currentUrl();
    if (current == null) {
      await controller.loadRequest(Uri.parse(initialUrl));
    } else {
      await controller.reload();
    }
  }

  Future<bool> canGoBack() => controller.canGoBack();

  Future<void> goBack() => controller.goBack();

  void dispose() {
    _disposed = true;
  }
}
