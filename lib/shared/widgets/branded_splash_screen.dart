import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';

/// Minimal branded splash shown for the first frame, before the WebView
/// has reported any progress at all. Intentionally has no animation and no
/// artificial delay: Apple and users both penalize splash screens that
/// linger past the point where real content is ready.
class BrandedSplashScreen extends StatelessWidget {
  const BrandedSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.white,
      alignment: Alignment.center,
      child: Semantics(
        label: AppConfig.appName,
        image: true,
        child: Image.asset(
          'assets/branding/bitinstantview_logo.png',
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}
