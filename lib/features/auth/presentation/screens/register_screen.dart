import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gigflow/core/utils/validators.dart';
import 'package:gigflow/core/widgets/liquid_glass_button.dart';
import 'package:gigflow/core/widgets/liquid_glass_text_field.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:gigflow/features/auth/presentation/widgets/auth_layout.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const emailKey = ValueKey('register-email');
  static const passwordKey = ValueKey('register-password');
  static const confirmKey = ValueKey('register-confirm');
  static const submitKey = ValueKey('register-submit');

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    // Don't carry an error over from the login screen.
    final bloc = context.read<AuthBloc>();
    if (bloc.state.errorMessage != null) bloc.add(const AuthErrorCleared());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _clearError(String _) {
    final bloc = context.read<AuthBloc>();
    if (bloc.state.errorMessage != null) bloc.add(const AuthErrorCleared());
  }

  void _submit() {
    final bloc = context.read<AuthBloc>();
    if (bloc.state.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    bloc.add(
      AuthRegisterSubmitted(
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final toggle = PasswordVisibilityToggle(
      obscured: _obscured,
      onPressed: () => setState(() => _obscured = !_obscured),
    );
    return AuthLayout(
      title: 'Create your account',
      footer: TextButton(
        onPressed: () => context.go('/login'),
        child: const Text('Already have an account? Sign in'),
      ),
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (a, b) =>
            a.isSubmitting != b.isSubmitting ||
            a.errorMessage != b.errorMessage,
        builder: (context, state) => Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthErrorBanner(message: state.errorMessage),
                LiquidGlassTextField(
                  key: RegisterScreen.emailKey,
                  controller: _email,
                  label: 'Email',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  validator: Validators.email,
                  onChanged: _clearError,
                ),
                const SizedBox(height: 14),
                LiquidGlassTextField(
                  key: RegisterScreen.passwordKey,
                  controller: _password,
                  label: 'Password',
                  hint: 'At least 6 characters, a letter and a number',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscured,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  autocorrect: false,
                  validator: Validators.newPassword,
                  onChanged: _clearError,
                  suffix: toggle,
                ),
                const SizedBox(height: 14),
                LiquidGlassTextField(
                  key: RegisterScreen.confirmKey,
                  controller: _confirm,
                  label: 'Confirm password',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: _obscured,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  autocorrect: false,
                  validator: (v) =>
                      Validators.confirmPassword(v, _password.text),
                  onChanged: _clearError,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 22),
                LiquidGlassButton(
                  key: RegisterScreen.submitKey,
                  label: 'Create Account',
                  isLoading: state.isSubmitting,
                  onPressed: state.isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
