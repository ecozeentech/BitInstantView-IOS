import 'dart:ui' as ui;

import 'package:bitinstantview/app.dart';
import 'package:bitinstantview/core/constants/app_constants.dart';
import 'package:bitinstantview/features/webview/presentation/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BitInstantViewApp startup', () {
    testWidgets(
      'builds without throwing and does not show a raw error screen',
      (tester) async {
        await tester.pumpWidget(const BitInstantViewApp());
        await tester.pump();
        // Give any pending async WebView initialization a chance to settle.
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );

    testWidgets(
      'a WebView-engine failure degrades to an accessible error view, not a crash',
      (tester) async {
        // This host environment (`flutter test`) has no registered
        // `WebViewPlatform` implementation, so WebViewControllerManager's
        // initialize() is expected to throw and be caught, producing a
        // webViewUnavailable AppError. This exercises the real defensive
        // fallback path, not a fabricated test double.
        await tester.pumpWidget(const BitInstantViewApp());
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorView), findsOneWidget);
        expect(find.text(AppConstants.retryLabel), findsOneWidget);
      },
    );

    testWidgets(
      'the retry action in the degraded state is reachable and accessible',
      (tester) async {
        await tester.pumpWidget(const BitInstantViewApp());
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        final retryButtonFinder = find.widgetWithText(
          ElevatedButton,
          AppConstants.retryLabel,
        );
        expect(retryButtonFinder, findsOneWidget);

        final data = tester
            .getSemantics(find.bySemanticsLabel(AppConstants.retryLabel))
            .getSemanticsData();
        expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
      },
    );
  });
}
