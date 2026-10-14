import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/accessible_action_button.dart';

/// Dedicated offline state, distinct from a generic page error so the
/// message accurately reflects a connectivity problem rather than implying
/// the website itself is broken.
class OfflineView extends StatelessWidget {
  const OfflineView({
    super.key,
    required this.onRetry,
    this.isRetrying = false,
  });

  final VoidCallback onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: AppConstants.primaryBlack,
                semanticLabel: 'Offline',
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.offlineTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.offlineMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              AccessibleActionButton(
                label: isRetrying
                    ? AppConstants.retryingLabel
                    : AppConstants.retryLabel,
                onPressed: onRetry,
                isLoading: isRetrying,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
