import 'package:flutter/material.dart';

/// Gradient pill CTA. Min 48dp, pressed scale (transform only, no saveLayer).
class LiquidGlassButton extends StatefulWidget {
  const LiquidGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final radius = BorderRadius.circular(999);
    final fg = enabled
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: 0.75);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                colors: enabled
                    ? [
                        scheme.primary,
                        Color.lerp(
                          scheme.primary,
                          const Color(0xFF6366F1),
                          0.3,
                        )!,
                      ]
                    : [
                        scheme.onSurface.withValues(alpha: 0.16),
                        scheme.onSurface.withValues(alpha: 0.10),
                      ],
              ),
            ),
            child: InkWell(
              key: const ValueKey('liquid-glass-button-ink'),
              borderRadius: radius,
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisSize: widget.expand
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: fg,
                          ),
                        )
                      else if (widget.icon != null)
                        Icon(widget.icon, size: 20, color: fg),
                      if (widget.isLoading || widget.icon != null)
                        const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
