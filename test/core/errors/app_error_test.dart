import 'package:bitinstantview/core/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  group('AppError.fromWebResourceError', () {
    test('classifies hostLookup failures as offline', () {
      final error = AppError.fromWebResourceError(
        const WebResourceError(
          errorCode: -2,
          description: 'host lookup failed',
          errorType: WebResourceErrorType.hostLookup,
        ),
      );
      expect(error.type, AppErrorType.offline);
    });

    test('classifies connect failures as offline', () {
      final error = AppError.fromWebResourceError(
        const WebResourceError(
          errorCode: -6,
          description: 'connection refused',
          errorType: WebResourceErrorType.connect,
        ),
      );
      expect(error.type, AppErrorType.offline);
    });

    test('classifies timeout failures as offline', () {
      final error = AppError.fromWebResourceError(
        const WebResourceError(
          errorCode: -8,
          description: 'timed out',
          errorType: WebResourceErrorType.timeout,
        ),
      );
      expect(error.type, AppErrorType.offline);
    });

    test('classifies an unrelated error type as a generic network failure, not offline', () {
      final error = AppError.fromWebResourceError(
        const WebResourceError(
          errorCode: -10,
          description: 'unsupported scheme',
          errorType: WebResourceErrorType.unsupportedScheme,
        ),
      );
      expect(error.type, AppErrorType.network);
    });

    test('classifies a null error type as a generic network failure', () {
      final error = AppError.fromWebResourceError(
        const WebResourceError(errorCode: -1, description: 'unknown'),
      );
      expect(error.type, AppErrorType.network);
    });

    test(
      'never surfaces the raw platform description in the user-facing message',
      () {
        const rawDescription = 'net::ERR_INTERNAL::secret-internal-detail';
        final error = AppError.fromWebResourceError(
          const WebResourceError(errorCode: -1, description: rawDescription),
        );
        expect(error.userMessage.contains(rawDescription), isFalse);
      },
    );
  });

  group('AppError factories', () {
    test(
      'httpStatus carries the status code and mentions it in the message',
      () {
        final error = AppError.httpStatus(503);
        expect(error.type, AppErrorType.http);
        expect(error.httpStatusCode, 503);
        expect(error.userMessage.contains('503'), isTrue);
      },
    );

    test('navigationBlocked produces a navigationBlocked type', () {
      expect(AppError.navigationBlocked().type, AppErrorType.navigationBlocked);
    });

    test('offline produces an offline type', () {
      expect(AppError.offline().type, AppErrorType.offline);
    });

    test('webViewUnavailable keeps the cause out of the user message', () {
      final error = AppError.webViewUnavailable(
        Exception('internal/path/leak.swift:42'),
      );
      expect(error.userMessage.contains('leak.swift'), isFalse);
      expect(error.debugDetail, isNotNull);
    });
  });
}
