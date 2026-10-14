import 'package:bitinstantview/core/navigation/url_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrlPolicy.classify - first-party navigation', () {
    test('allows the exact https apex domain', () {
      expect(
        UrlPolicy.classify('https://bitinstantview.com/'),
        LinkTarget.webView,
      );
    });

    test('allows the https www subdomain', () {
      expect(
        UrlPolicy.classify('https://www.bitinstantview.com/login'),
        LinkTarget.webView,
      );
    });

    test('allows a legitimate deeper subdomain', () {
      expect(
        UrlPolicy.classify('https://api.bitinstantview.com/v1/markets'),
        LinkTarget.webView,
      );
    });

    test('is case-insensitive on the host', () {
      expect(
        UrlPolicy.classify('https://WWW.BitInstantView.COM/terms'),
        LinkTarget.webView,
      );
    });

    test('blocks plain-http first-party navigation instead of silently upgrading it', () {
      expect(
        UrlPolicy.classify('http://www.bitinstantview.com/'),
        LinkTarget.blocked,
      );
    });
  });

  group('UrlPolicy.classify - domain boundary / lookalike protection', () {
    test('does not treat a suffix-lookalike host as first-party', () {
      // Contains "bitinstantview.com" as a literal substring, but the real
      // registrable domain here is evil.org.
      final target = UrlPolicy.classify(
        'https://www.bitinstantview.com.evil.org/login',
      );
      expect(target, isNot(LinkTarget.webView));
      expect(target, LinkTarget.externalBrowser);
    });

    test('does not treat a prefixed-lookalike host as first-party', () {
      final target = UrlPolicy.classify('https://evilbitinstantview.com/login');
      expect(target, isNot(LinkTarget.webView));
    });

    test('resolves userinfo-prefixed URLs by the real host after @, not the lookalike before it', () {
      // The text before "@" is attacker-controlled userinfo, not the host.
      final target = UrlPolicy.classify(
        'https://www.bitinstantview.com@evil.com/',
      );
      expect(target, isNot(LinkTarget.webView));
      expect(target, LinkTarget.externalBrowser);
    });
  });

  group('UrlPolicy.classify - trusted auth bridge', () {
    test('keeps the confirmed Google OAuth hop inside the WebView', () {
      expect(
        UrlPolicy.classify(
          'https://accounts.google.com/o/oauth2/v2/auth?client_id=abc',
        ),
        LinkTarget.webView,
      );
    });

    test(
      'does not trust an unrelated host merely because it mentions google',
      () {
        expect(
          UrlPolicy.classify('https://accounts.google.evil.com/'),
          isNot(LinkTarget.webView),
        );
      },
    );
  });

  group('UrlPolicy.classify - external https', () {
    test(
      'routes unrelated third-party https destinations to the system browser',
      () {
        expect(
          UrlPolicy.classify('https://twitter.com/BitInstantView'),
          LinkTarget.externalBrowser,
        );
      },
    );

    test('blocks unrelated third-party http destinations', () {
      expect(UrlPolicy.classify('http://example.com/'), LinkTarget.blocked);
    });
  });

  group('UrlPolicy.classify - schemes', () {
    test('blocks javascript: URLs', () {
      expect(UrlPolicy.classify('javascript:alert(1)'), LinkTarget.blocked);
    });

    test('blocks file: URLs', () {
      expect(UrlPolicy.classify('file:///etc/passwd'), LinkTarget.blocked);
    });

    test('blocks data: URLs', () {
      expect(
        UrlPolicy.classify('data:text/html,<script>alert(1)</script>'),
        LinkTarget.blocked,
      );
    });

    test('routes mailto: to the system handler', () {
      expect(
        UrlPolicy.classify('mailto:support@bitinstantview.com'),
        LinkTarget.systemHandler,
      );
    });

    test('routes tel: to the system handler', () {
      expect(UrlPolicy.classify('tel:+15551234567'), LinkTarget.systemHandler);
    });

    test('blocks an empty mailto: with no address', () {
      expect(UrlPolicy.classify('mailto:'), LinkTarget.blocked);
    });

    test('blocks unrecognized custom schemes', () {
      expect(
        UrlPolicy.classify('bitinstantview-app://open'),
        LinkTarget.blocked,
      );
    });
  });

  group('UrlPolicy.classify - malformed input', () {
    test('blocks an empty string', () {
      expect(UrlPolicy.classify(''), LinkTarget.blocked);
    });

    test('blocks a string with no scheme or host', () {
      expect(UrlPolicy.classify('not a url'), LinkTarget.blocked);
    });
  });

  group('UrlPolicy.isFirstParty', () {
    test('is true for the verified apex and www host over https', () {
      expect(
        UrlPolicy.isFirstParty(Uri.parse('https://bitinstantview.com/')),
        isTrue,
      );
      expect(
        UrlPolicy.isFirstParty(Uri.parse('https://www.bitinstantview.com/')),
        isTrue,
      );
    });

    test('is false over http even for the first-party host', () {
      expect(
        UrlPolicy.isFirstParty(Uri.parse('http://www.bitinstantview.com/')),
        isFalse,
      );
    });

    test('is false for a lookalike host', () {
      expect(
        UrlPolicy.isFirstParty(
          Uri.parse('https://bitinstantview.com.evil.org/'),
        ),
        isFalse,
      );
    });
  });
}
