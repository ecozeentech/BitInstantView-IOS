import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';

/// Coarse lifecycle of the main WebView surface.
enum WebViewLoadStatus {
  /// Nothing has started loading yet.
  initial,

  /// A navigation is in flight (initial load, retry, or a follow-on page).
  loading,

  /// The current page finished loading successfully.
  success,

  /// Loading failed; [WebViewScreenState.error] describes why.
  failed,
}

/// Immutable snapshot of everything the WebView screen's UI needs to decide
/// what to render. Immutability keeps `==`-based rebuilds in
/// [ListenableBuilder] predictable and makes the transition table trivial to
/// unit test without touching Flutter widgets at all.
@immutable
class WebViewScreenState {
  const WebViewScreenState({
    this.status = WebViewLoadStatus.initial,
    this.progress = 0,
    this.error,
    this.isRetrying = false,
    this.canGoBack = false,
  });

  final WebViewLoadStatus status;

  /// 0.0 - 1.0 load progress of the current navigation.
  final double progress;

  final AppError? error;

  /// True while a user-initiated retry is in flight, used to disable the
  /// retry button and avoid stacking duplicate reloads from repeated taps.
  final bool isRetrying;

  final bool canGoBack;

  WebViewScreenState copyWith({
    WebViewLoadStatus? status,
    double? progress,
    AppError? error,
    bool clearError = false,
    bool? isRetrying,
    bool? canGoBack,
  }) {
    return WebViewScreenState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
      isRetrying: isRetrying ?? this.isRetrying,
      canGoBack: canGoBack ?? this.canGoBack,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WebViewScreenState &&
      other.status == status &&
      other.progress == progress &&
      other.error?.type == error?.type &&
      other.error?.userMessage == error?.userMessage &&
      other.isRetrying == isRetrying &&
      other.canGoBack == canGoBack;

  @override
  int get hashCode => Object.hash(
    status,
    progress,
    error?.type,
    error?.userMessage,
    isRetrying,
    canGoBack,
  );
}

/// Holds and mutates [WebViewScreenState], notifying listeners on change.
///
/// A plain [ChangeNotifier] is used instead of a state-management package:
/// the screen has a single owner, a handful of transitions, and no need for
/// dependency injection across a widget subtree, so adding Provider/Bloc/
/// Riverpod here would be complexity without benefit.
class WebViewStateController extends ChangeNotifier {
  WebViewScreenState _state = const WebViewScreenState();

  WebViewScreenState get state => _state;

  void _emit(WebViewScreenState next) {
    if (next == _state) return;
    _state = next;
    notifyListeners();
  }

  void navigationStarted() {
    _emit(
      _state.copyWith(
        status: WebViewLoadStatus.loading,
        clearError: true,
        progress: 0,
      ),
    );
  }

  void progressChanged(int percent) {
    _emit(_state.copyWith(progress: (percent.clamp(0, 100)) / 100));
  }

  void navigationFinished({required bool canGoBack}) {
    _emit(
      _state.copyWith(
        status: WebViewLoadStatus.success,
        progress: 1,
        clearError: true,
        isRetrying: false,
        canGoBack: canGoBack,
      ),
    );
  }

  void failed(AppError error) {
    _emit(
      _state.copyWith(
        status: WebViewLoadStatus.failed,
        error: error,
        isRetrying: false,
      ),
    );
  }

  void canGoBackChanged(bool canGoBack) {
    _emit(_state.copyWith(canGoBack: canGoBack));
  }

  void retryStarted() {
    _emit(
      _state.copyWith(
        status: WebViewLoadStatus.loading,
        isRetrying: true,
        clearError: true,
        progress: 0,
      ),
    );
  }
}
