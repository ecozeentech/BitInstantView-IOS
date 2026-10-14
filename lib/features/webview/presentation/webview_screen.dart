import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/navigation/url_policy.dart';
import '../../../shared/widgets/branded_splash_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../services/external_link_service.dart';
import 'error_view.dart';
import 'loading_view.dart';
import 'webview_controller_manager.dart';
import 'webview_state.dart';

/// Hosts a single WebView instance pointed at [url].
///
/// Reused for both the primary BitInstantView home surface and for the
/// static legal pages (Terms, Privacy) pushed from Settings, so there is
/// exactly one WebView configuration code path in the whole app.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({
    super.key,
    this.url = AppConfig.homeUrl,
    this.title,
    this.showSettingsAction = true,
  });

  final String url;

  /// When set, the screen gets a normal [AppBar] with a back button and
  /// this title -- appropriate for a pushed sub-page like Terms or Privacy.
  /// When null, the screen renders full-bleed with no app bar, which is
  /// correct for the primary home surface.
  final String? title;

  final bool showSettingsAction;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with WidgetsBindingObserver {
  final WebViewStateController _state = WebViewStateController();
  final ExternalLinkService _externalLinkService = const ExternalLinkService();

  WebViewControllerManager? _manager;
  bool _didAttemptInitialization = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeIfNeeded();
  }

  Future<void> _initializeIfNeeded() async {
    if (_didAttemptInitialization) return;
    _didAttemptInitialization = true;

    final manager = WebViewControllerManager(
      initialUrl: widget.url,
      state: _state,
      onExternalNavigation: _handleExternalNavigation,
    );

    try {
      await manager.initialize();
      if (!mounted) return;
      setState(() => _manager = manager);
    } catch (error) {
      if (!mounted) return;
      _state.failed(AppError.webViewUnavailable(error));
      setState(() {});
    }
  }

  void _handleExternalNavigation(Uri uri, LinkTarget target) {
    _externalLinkService.open(uri, target).then((success) {
      if (!success && mounted) {
        _showSnackBar(AppConstants.externalLinkFailedMessage);
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: AppConstants.snackBarDuration,
        ),
      );
  }

  Future<void> _retry() async {
    final manager = _manager;
    if (manager == null) {
      // The WebView engine itself failed to initialize; the only recovery
      // is to attempt building it again.
      _didAttemptInitialization = false;
      await _initializeIfNeeded();
      return;
    }
    await manager.retry();
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The WebView retains its own navigation history and session cookies
    // across background/foreground transitions; no reload is triggered here
    // intentionally, matching "preserve the website's own session
    // management" and avoiding a jarring full reload every time the user
    // switches apps.
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manager?.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      top: widget.title == null,
      bottom: false,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          final current = _state.state;

          return PopScope(
            canPop: !current.canGoBack,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                _manager?.goBack();
              }
            },
            child: Stack(
              children: [
                if (current.status == WebViewLoadStatus.initial &&
                    current.error == null)
                  const Positioned.fill(child: BrandedSplashScreen()),
                if (_manager != null)
                  Positioned.fill(
                    child: WebViewWidget(controller: _manager!.controller),
                  ),
                if (current.status == WebViewLoadStatus.loading)
                  LoadingView(progress: current.progress),
                if (current.status == WebViewLoadStatus.failed &&
                    current.error != null)
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: ErrorView(
                        error: current.error!,
                        onRetry: _retry,
                        isRetrying: current.isRetrying,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    if (widget.title == null) {
      return Scaffold(
        body: Stack(
          children: [
            body,
            if (widget.showSettingsAction)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    // `IconButton`'s own `tooltip` already supplies its
                    // accessible label and button role; no extra
                    // `Semantics` wrapper is needed (one was tried and
                    // removed after it produced a duplicate accessibility
                    // node -- see the same fix in AccessibleActionButton).
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: AppConstants.settingsTitle,
                      onPressed: _openSettings,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title!)),
      body: body,
    );
  }
}
