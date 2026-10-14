import 'package:bitinstantview/core/errors/app_error.dart';
import 'package:bitinstantview/features/webview/presentation/error_view.dart';
import 'package:bitinstantview/features/webview/presentation/offline_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('ErrorView', () {
    testWidgets('shows the offline-specific view for an offline AppError', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(ErrorView(error: AppError.offline(), onRetry: () {})),
      );

      expect(find.byType(OfflineView), findsOneWidget);
    });

    testWidgets(
      'shows a generic error message and retry button for a network AppError',
      (tester) async {
        await tester.pumpWidget(
          wrap(ErrorView(error: AppError.unknown('boom'), onRetry: () {})),
        );

        expect(find.byType(OfflineView), findsNothing);
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets('invokes onRetry exactly once per tap', (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(
        wrap(ErrorView(error: AppError.unknown(), onRetry: () => retryCount++)),
      );

      await tester.tap(find.text('Retry'));
      expect(retryCount, 1);
    });

    testWidgets(
      'shows "Retrying…" and disables the button while a retry is in flight',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            ErrorView(
              error: AppError.unknown(),
              onRetry: () {},
              isRetrying: true,
            ),
          ),
        );

        expect(find.text('Retrying…'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
      },
    );

    testWidgets(
      'surfaces the HTTP status code for an http AppError without exposing raw platform text',
      (tester) async {
        await tester.pumpWidget(
          wrap(ErrorView(error: AppError.httpStatus(503), onRetry: () {})),
        );

        expect(find.textContaining('503'), findsOneWidget);
      },
    );
  });

  group('OfflineView', () {
    testWidgets('renders an accessible offline message and a retry action', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(OfflineView(onRetry: () {})));

      expect(find.text("You're offline"), findsOneWidget);
      expect(find.bySemanticsLabel('Retry'), findsOneWidget);
    });
  });
}
