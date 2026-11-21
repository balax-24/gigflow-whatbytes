import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gigflow/core/utils/validators.dart';
import 'package:gigflow/core/widgets/liquid_glass_button.dart';
import 'package:gigflow/core/widgets/liquid_glass_text_field.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:gigflow/features/auth/presentation/widgets/auth_layout.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const emailKey = ValueKey('login-email');
  static const passwordKey = ValueKey('login-password');
  static const submitKey = ValueKey('login-submit');

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
      AuthLoginSubmitted(email: _email.text.trim(), password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Welcome back',
      footer: TextButton(
        onPressed: () => context.go('/register'),
        child: const Text('New to GigFlow? Create account'),
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
                  key: LoginScreen.emailKey,
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
                  key: LoginScreen.passwordKey,
                  controller: _password,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscured,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  autocorrect: false,
                  validator: Validators.loginPassword,
                  onChanged: _clearError,
                  onFieldSubmitted: (_) => _submit(),
                  suffix: PasswordVisibilityToggle(
                    obscured: _obscured,
                    onPressed: () => setState(() => _obscured = !_obscured),
                  ),
                ),
                const SizedBox(height: 22),
                LiquidGlassButton(
                  key: LoginScreen.submitKey,
                  label: 'Sign In',
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
