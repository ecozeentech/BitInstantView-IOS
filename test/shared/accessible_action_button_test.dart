import 'dart:ui' as ui;

import 'package:bitinstantview/shared/widgets/accessible_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  group('AccessibleActionButton', () {
    testWidgets('renders its label and responds to taps', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          AccessibleActionButton(
            label: 'Retry',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.byType(AccessibleActionButton));
      expect(tapped, isTrue);
    });

    testWidgets('exposes a tappable semantics node with the expected label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(AccessibleActionButton(label: 'Retry', onPressed: () {})),
      );

      final data = tester
          .getSemantics(find.bySemanticsLabel('Retry'))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    });

    testWidgets('meets the minimum 48x48 hit-target size', (tester) async {
      await tester.pumpWidget(
        wrap(AccessibleActionButton(label: 'Retry', onPressed: () {})),
      );

      final size = tester.getSize(find.byType(AccessibleActionButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets(
      'disables interaction and shows a progress indicator while loading',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          wrap(
            AccessibleActionButton(
              label: 'Retrying…',
              onPressed: () => tapped = true,
              isLoading: true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(
          find.byType(AccessibleActionButton),
          warnIfMissed: false,
        );
        expect(tapped, isFalse);
      },
    );

    testWidgets('does not respond to taps when onPressed is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AccessibleActionButton(label: 'Retry', onPressed: null)),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
