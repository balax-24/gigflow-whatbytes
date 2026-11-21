import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/services/connectivity_cubit.dart';
import 'package:gigflow/core/utils/validators.dart';
import 'package:gigflow/core/widgets/liquid_glass_button.dart';
import 'package:gigflow/core/widgets/liquid_glass_chrome.dart';
import 'package:gigflow/core/widgets/liquid_glass_text_field.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';

/// Green check inside the email field once the address is valid.
class EmailValidTick extends StatelessWidget {
  const EmailValidTick({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final valid = Validators.email(value.text) == null;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: valid
                ? Icon(
                    Icons.check_circle_rounded,
                    key: const ValueKey('email-valid-tick'),
                    color: context.glass.complete,
                    semanticLabel: 'Valid email',
                  )
                : const SizedBox.shrink(key: ValueKey('email-no-tick')),
          );
        },
      );
}

/// "or continue with" divider + Google button.
class SocialSignInSection extends StatelessWidget {
  const SocialSignInSection({super.key, required this.enabled});

  final bool enabled;

  static const googleKey = ValueKey('google-sign-in');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.glass.textMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Divider(color: muted.withValues(alpha: 0.4))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or continue with',
                style: TextStyle(color: muted, fontSize: 12.5),
              ),
            ),
            Expanded(child: Divider(color: muted.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          key: googleKey,
          onPressed: enabled ? () => _startGoogle(context) : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.22)),
            foregroundColor: scheme.onSurface,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GoogleMark(),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Continue with Google',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _startGoogle(BuildContext context) {
  final online = context.read<ConnectivityCubit?>()?.state ?? true;
  if (!online) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            "You're offline. Connect to the internet to continue with Google.",
          ),
        ),
      );
    return;
  }
  context.read<AuthBloc>().add(const AuthGoogleRequested());
}

/// Simple four-colour "G" badge (no bundled trademark asset).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
    child: ShaderMask(
      shaderCallback: (rect) => const SweepGradient(
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
          Color(0xFF4285F4),
        ],
      ).createShader(rect),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
    ),
  );
}

/// Bottom sheet asking for the reset email (prefilled).
Future<void> showForgotPasswordSheet(BuildContext context, String email) {
  final bloc = context.read<AuthBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _ForgotPasswordSheet(bloc: bloc, initialEmail: email),
    ),
  );
}

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({required this.bloc, required this.initialEmail});

  final AuthBloc bloc;
  final String initialEmail;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail.trim());

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.bloc.add(AuthPasswordResetRequested(_email.text));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LiquidGlassChrome(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reset your password', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              "We'll email you a secure link to choose a new password.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            LiquidGlassTextField(
              key: const ValueKey('reset-email'),
              controller: _email,
              label: 'Email',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              autocorrect: false,
              autofocus: widget.initialEmail.isEmpty,
              validator: Validators.email,
              suffix: EmailValidTick(controller: _email),
              onFieldSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 18),
            LiquidGlassButton(
              key: const ValueKey('reset-send'),
              label: 'Send reset link',
              icon: Icons.send_rounded,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
