import 'package:bitinstantview/core/errors/app_error.dart';
import 'package:bitinstantview/features/webview/presentation/webview_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebViewScreenState defaults', () {
    test('starts in the initial status with no error and no progress', () {
      const state = WebViewScreenState();
      expect(state.status, WebViewLoadStatus.initial);
      expect(state.progress, 0);
      expect(state.error, isNull);
      expect(state.isRetrying, isFalse);
      expect(state.canGoBack, isFalse);
    });
  });

  group('WebViewStateController transitions', () {
    test('navigationStarted moves to loading and clears any prior error', () {
      final controller = WebViewStateController();
      controller.failed(AppError.offline());
      expect(controller.state.status, WebViewLoadStatus.failed);

      controller.navigationStarted();
      expect(controller.state.status, WebViewLoadStatus.loading);
      expect(controller.state.error, isNull);
      expect(controller.state.progress, 0);
    });

    test('progressChanged clamps and normalizes to a 0-1 fraction', () {
      final controller = WebViewStateController();
      controller.progressChanged(150);
      expect(controller.state.progress, 1.0);

      controller.progressChanged(-20);
      expect(controller.state.progress, 0.0);

      controller.progressChanged(42);
      expect(controller.state.progress, closeTo(0.42, 0.0001));
    });

    test(
      'navigationFinished reports success, full progress, and clears errors',
      () {
        final controller = WebViewStateController();
        controller.failed(AppError.offline());

        controller.navigationFinished(canGoBack: true);
        expect(controller.state.status, WebViewLoadStatus.success);
        expect(controller.state.progress, 1);
        expect(controller.state.error, isNull);
        expect(controller.state.canGoBack, isTrue);
        expect(controller.state.isRetrying, isFalse);
      },
    );

    test('failed records the error and moves to the failed status', () {
      final controller = WebViewStateController();
      final error = AppError.navigationBlocked();

      controller.failed(error);
      expect(controller.state.status, WebViewLoadStatus.failed);
      expect(controller.state.error, isNotNull);
      expect(controller.state.error!.type, AppErrorType.navigationBlocked);
    });

    test('retryStarted marks isRetrying and loading while clearing the prior error', () {
      final controller = WebViewStateController();
      controller.failed(AppError.offline());

      controller.retryStarted();
      expect(controller.state.status, WebViewLoadStatus.loading);
      expect(controller.state.isRetrying, isTrue);
      expect(controller.state.error, isNull);
    });

    test('a retry that succeeds clears isRetrying', () {
      final controller = WebViewStateController();
      controller.failed(AppError.offline());
      controller.retryStarted();
      expect(controller.state.isRetrying, isTrue);

      controller.navigationFinished(canGoBack: false);
      expect(controller.state.isRetrying, isFalse);
      expect(controller.state.status, WebViewLoadStatus.success);
    });

    test(
      'a retry that fails again clears isRetrying but keeps the failed status',
      () {
        final controller = WebViewStateController();
        controller.retryStarted();

        controller.failed(AppError.offline());
        expect(controller.state.isRetrying, isFalse);
        expect(controller.state.status, WebViewLoadStatus.failed);
      },
    );

    test('canGoBackChanged updates independently of load status', () {
      final controller = WebViewStateController();
      expect(controller.state.canGoBack, isFalse);

      controller.canGoBackChanged(true);
      expect(controller.state.canGoBack, isTrue);
      expect(controller.state.status, WebViewLoadStatus.initial);
    });

    test(
      'notifyListeners only fires when the emitted state actually changes',
      () {
        final controller = WebViewStateController();
        var notifications = 0;
        controller.addListener(() => notifications++);

        controller.navigationStarted();
        expect(notifications, 1);

        // Same status/progress/error/retry/canGoBack as current state: no-op.
        controller.navigationStarted();
        expect(notifications, 1);

        controller.progressChanged(50);
        expect(notifications, 2);
      },
    );
  });
}
