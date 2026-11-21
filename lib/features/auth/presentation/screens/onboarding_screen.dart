import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gigflow/app/di/injection_container.dart';
import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/widgets/liquid_glass_card.dart';
import 'package:gigflow/features/tasks/data/datasources/local_preferences_datasource.dart';
import 'package:go_router/go_router.dart';

class _Slide {
  const _Slide(this.emoji, this.title, this.body);
  final String emoji;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    '⚡',
    'Get things done.',
    'Plan every delivery, ride and errand in one place. Just a tap away.',
  ),
  _Slide(
    '⏰',
    'Never miss a drop-off.',
    'Tasks sort themselves by due time, with overdue alerts and a live shift progress bar.',
  ),
  _Slide(
    '📶',
    'No signal? No problem.',
    'Keep working in basements and lifts. Everything syncs the moment you are back online.',
  ),
];

/// One-time intro shown on first launch, before login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinish});

  /// Defaults to persisting the "seen" flag and opening login.
  final Future<void> Function(BuildContext context)? onFinish;

  static const nextKey = ValueKey('onboarding-next');
  static const skipKey = ValueKey('onboarding-skip');

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    unawaited(HapticFeedback.mediumImpact());
    final custom = widget.onFinish;
    if (custom != null) return custom(context);
    await sl<LocalPreferencesDataSource>().writeOnboardingSeen();
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_isLast) {
      unawaited(_finish());
      return;
    }
    HapticFeedback.selectionClick();
    _pages.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _isLast ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  key: OnboardingScreen.skipKey,
                  onPressed: _isLast ? null : _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 24, 24),
              child: Row(
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: _isLast ? 'Get started' : 'Next',
                    excludeSemantics: true,
                    child: Material(
                      color: scheme.primary,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        key: OnboardingScreen.nextKey,
                        customBorder: const StadiumBorder(),
                        onTap: _next,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _isLast ? 24 : 18,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isLast) ...[
                                  Text(
                                    'Get started',
                                    style: TextStyle(
                                      color: scheme.onPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: scheme.onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  width: 168,
                  height: 168,
                  child: LiquidGlassCard(
                    radius: 44,
                    padding: EdgeInsets.zero,
                    child: Center(
                      child: Text(
                        slide.emoji,
                        style: const TextStyle(fontSize: 76),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Text(
                slide.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.body,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.glass.textMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
