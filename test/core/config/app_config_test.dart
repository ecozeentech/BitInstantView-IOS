import 'package:bitinstantview/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig defaults', () {
    test('home URL is HTTPS and points at the verified apex domain', () {
      final uri = Uri.parse(AppConfig.homeUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.bitinstantview.com');
    });

    test('terms and privacy URLs are HTTPS and first-party', () {
      for (final url in [AppConfig.termsUrl, AppConfig.privacyUrl]) {
        final uri = Uri.parse(url);
        expect(uri.scheme, 'https');
        expect(uri.host.endsWith(AppConfig.primaryDomain), isTrue);
      }
    });

    test(
      'bundle identifier placeholder is a plausible reverse-DNS identifier',
      () {
        expect(
          AppConfig.bundleIdentifierPlaceholder,
          matches(RegExp(r'^[a-zA-Z0-9.]+$')),
        );
        expect(
          AppConfig.bundleIdentifierPlaceholder.split('.').length,
          greaterThanOrEqualTo(3),
        );
      },
    );

    test(
      'trusted auth bridge hosts do not include the first-party domain itself',
      () {
        expect(
          AppConfig.trustedAuthBridgeHosts.contains(AppConfig.primaryDomain),
          isFalse,
        );
      },
    );
  });
}
