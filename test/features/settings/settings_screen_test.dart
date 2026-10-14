import 'package:bitinstantview/core/config/app_config.dart';
import 'package:bitinstantview/core/constants/app_constants.dart';
import 'package:bitinstantview/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap() => const MaterialApp(home: SettingsScreen());

  group('SettingsScreen', () {
    testWidgets(
      'lists the terms, privacy, and account rows with accessible labels',
      (tester) async {
        await tester.pumpWidget(wrap());
        await tester.pump();

        expect(find.text(AppConstants.termsRowLabel), findsOneWidget);
        expect(find.text(AppConstants.privacyRowLabel), findsOneWidget);
        expect(find.text(AppConstants.accountRowLabel), findsOneWidget);
        expect(find.text(AppConstants.accountRowSubtitle), findsOneWidget);
      },
    );

    testWidgets('does not claim an account was deleted anywhere in its copy', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(
        find.textContaining('account has been deleted', findRichText: true),
        findsNothing,
      );
      expect(find.textContaining('deleted', findRichText: true), findsNothing);
    });

    testWidgets(
      'shows version metadata synchronously, with no platform-channel round trip',
      (tester) async {
        await tester.pumpWidget(wrap());
        await tester.pump();

        expect(find.text('Version'), findsOneWidget);
        expect(
          find.text('${AppConfig.appVersion} (${AppConfig.appBuildNumber})'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping the Terms row pushes a screen titled Terms of Service',
      (tester) async {
        await tester.pumpWidget(wrap());
        await tester.pump();

        await tester.tap(find.text(AppConstants.termsRowLabel));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(
          find.widgetWithText(AppBar, AppConstants.termsRowLabel),
          findsOneWidget,
        );
      },
    );
  });
}
