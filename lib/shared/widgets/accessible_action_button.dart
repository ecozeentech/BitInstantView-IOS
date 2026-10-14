import 'package:flutter/material.dart';

/// A primary action button with a guaranteed minimum hit area and an
/// explicit semantic label, used by every retry/recovery affordance in the
/// app so accessibility behavior stays consistent in one place instead of
/// being repeated (and potentially forgotten) at each call site.
class AccessibleActionButton extends StatelessWidget {
  const AccessibleActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // `ElevatedButton` already provides correct button semantics (role,
    // enabled state, and a label merged from its `Text` child), so no extra
    // `Semantics` wrapper is added here -- doing so would create a second,
    // duplicate accessibility node with the same label.
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88, minHeight: 48),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon ?? Icons.refresh),
        label: Text(label),
      ),
    );
  }
}
