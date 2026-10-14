import 'package:bitinstantview/features/webview/presentation/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('LoadingView', () {
    testWidgets('exposes an accessible, live-updating loading label', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const LoadingView(progress: 0.3)));

      final semantics = tester.getSemantics(find.byType(LoadingView));
      expect(semantics.label, contains('Loading'));
    });

    testWidgets(
      'shows a determinate progress bar for a mid-range progress value',
      (tester) async {
        await tester.pumpWidget(wrap(const LoadingView(progress: 0.5)));

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, closeTo(0.5, 0.0001));
      },
    );

    testWidgets('shows an indeterminate progress bar when progress is null', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const LoadingView()));

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, isNull);
    });

    testWidgets(
      'shows an indeterminate progress bar at the boundary values 0 and 1',
      (tester) async {
        await tester.pumpWidget(wrap(const LoadingView(progress: 0)));
        var indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, isNull);

        await tester.pumpWidget(wrap(const LoadingView(progress: 1)));
        indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, isNull);
      },
    );
  });
}
