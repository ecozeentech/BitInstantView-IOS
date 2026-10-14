import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../webview/presentation/webview_screen.dart';

/// Native settings surface. Hosts the legal pages, the account-management
/// entry point, and app version metadata.
///
/// This screen intentionally does not attempt to recreate account
/// management, deletion, or authentication natively: those remain the
/// website's responsibility (see docs/APP_STORE_READINESS.md). The app only
/// provides fast, accessible navigation to the real pages that implement
/// them.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openLegalPage(BuildContext context, String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            WebViewScreen(url: url, title: title, showSettingsAction: false),
      ),
    );
  }

  Future<void> _openInSystemBrowser(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.settingsTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text(AppConstants.termsRowLabel),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openLegalPage(
                context,
                AppConfig.termsUrl,
                AppConstants.termsRowLabel,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text(AppConstants.privacyRowLabel),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openLegalPage(
                context,
                AppConfig.privacyUrl,
                AppConstants.privacyRowLabel,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text(AppConstants.accountRowLabel),
              subtitle: const Text(AppConstants.accountRowSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openLegalPage(
                context,
                AppConfig.accountSettingsUrl,
                AppConstants.accountRowLabel,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text(AppConstants.openWebsiteRowLabel),
              onTap: () => _openInSystemBrowser(AppConfig.homeUrl),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Version'),
              subtitle: Text(
                '${AppConfig.appVersion} (${AppConfig.appBuildNumber})',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
