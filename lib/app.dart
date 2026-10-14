import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/webview/presentation/webview_screen.dart';

/// Root widget. Deliberately thin: all real behavior lives in
/// [WebViewScreen] and the modules it composes.
class BitInstantViewApp extends StatelessWidget {
  const BitInstantViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const WebViewScreen(),
    );
  }
}
