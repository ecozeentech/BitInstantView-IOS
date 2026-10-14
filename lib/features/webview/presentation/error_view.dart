import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/accessible_action_button.dart';
import 'offline_view.dart';

/// Generic, accessible recovery screen for any non-offline [AppError].
///
/// Deliberately renders a single inline message plus one clear action
/// rather than a dialog: dialogs interrupt VoiceOver flow and are easy for
/// a user to dismiss by accident, losing the recovery action entirely.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.isRetrying = false,
  });

  final AppError error;
  final VoidCallback onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    if (error.type == AppErrorType.offline) {
      return OfflineView(onRetry: onRetry, isRetrying: isRetrying);
    }

    final title = switch (error.type) {
      AppErrorType.http => AppConstants.httpErrorTitlePrefix,
      AppErrorType.navigationBlocked => 'Navigation blocked',
      AppErrorType.webViewUnavailable => AppConstants.genericErrorTitle,
      _ => AppConstants.genericErrorTitle,
    };

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                error.type == AppErrorType.navigationBlocked
                    ? Icons.shield_outlined
                    : Icons.error_outline,
                size: 56,
                color: AppConstants.errorRed,
                semanticLabel: 'Error',
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.userMessage,
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
