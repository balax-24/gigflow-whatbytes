import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';

/// Animated pill for auth feedback: coral for errors, green for info.
/// Announced by screen readers.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, this.info});

  final String? message;

  /// Shown (green) only when there is no error message.
  final String? info;

  @override
  Widget build(BuildContext context) {
    final isError = message != null;
    final text = message ?? info;
    final color = isError ? context.glass.overdue : context.glass.complete;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Semantics(
                liveRegion: true,
                child: DecoratedBox(
                  key: ValueKey(
                    isError ? 'auth-error-banner' : 'auth-info-banner',
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.45)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isError
                              ? Icons.error_outline_rounded
                              : Icons.mark_email_read_outlined,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
