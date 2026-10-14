import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Subtle, branded loading indicator shown while a navigation is in
/// flight. Deliberately lightweight: it must not add perceptible delay on
/// top of the real network latency.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.progress});

  /// 0.0 - 1.0, or null to show an indeterminate indicator (used for the
  /// very first frame before the WebView reports any progress).
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress =
        (progress != null && progress! > 0 && progress! < 1) ? progress : null;

    return Semantics(
      label: AppConstants.loadingLabel,
      liveRegion: true,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: normalizedProgress,
              backgroundColor: Colors.transparent,
              color: AppConstants.primaryGold,
            ),
          ),
        ),
      ),
    );
  }
}
