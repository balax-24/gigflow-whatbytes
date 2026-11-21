import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/auth/presentation/screens/login_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late MockAuthBloc bloc;

  setUpAll(() => registerFallbackValue(const AuthErrorCleared()));

  setUp(() {
    bloc = MockAuthBloc();
    when(
      () => bloc.state,
    ).thenReturn(const AuthState(status: AuthStatus.unauthenticated));
  });

  Future<void> pump(WidgetTester tester) =>
      tester.pumpApp(const LoginScreen(), authBloc: bloc);

  testWidgets('empty submit shows both errors and sends no event', (t) async {
    await pump(t);
    await t.tap(find.byKey(LoginScreen.submitKey));
    await t.pump();
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('invalid email shows inline error', (t) async {
    await pump(t);
    await t.enterText(find.byKey(LoginScreen.emailKey), 'bad@');
    await t.enterText(find.byKey(LoginScreen.passwordKey), 'secret1');
    await t.tap(find.byKey(LoginScreen.submitKey));
    await t.pump();
    expect(find.text('Please enter a valid email address.'), findsOneWidget);
    verifyNever(() => bloc.add(any(that: isA<AuthLoginSubmitted>())));
  });

  testWidgets('valid form dispatches trimmed login', (t) async {
    await pump(t);
    await t.enterText(find.byKey(LoginScreen.emailKey), ' rider@gig.dev ');
    await t.enterText(find.byKey(LoginScreen.passwordKey), 'secret1');
    await t.tap(find.byKey(LoginScreen.submitKey));
    await t.pump();
    verify(
      () => bloc.add(
        const AuthLoginSubmitted(email: 'rider@gig.dev', password: 'secret1'),
      ),
    ).called(1);
  });

  testWidgets('error message renders banner', (t) async {
    when(() => bloc.state).thenReturn(
      const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Incorrect email or password.',
      ),
    );
    await pump(t);
    expect(find.byKey(const ValueKey('auth-error-banner')), findsOneWidget);
    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('stale error from another screen is cleared on open', (t) async {
    when(() => bloc.state).thenReturn(
      const AuthState(status: AuthStatus.unauthenticated, errorMessage: 'old'),
    );
    await pump(t);
    verify(() => bloc.add(const AuthErrorCleared())).called(1);
  });

  testWidgets('keyboard Next skips the visibility icon', (t) async {
    await pump(t);
    final toggle = find.byTooltip('Show password');
    expect(
      find.ancestor(of: toggle, matching: find.byType(ExcludeFocus)),
      findsOneWidget,
    );
  });

  testWidgets('password visibility toggles', (t) async {
    await pump(t);
    EditableText field() => t.widget<EditableText>(
      find.descendant(
        of: find.byKey(LoginScreen.passwordKey),
        matching: find.byType(EditableText),
      ),
    );
    expect(field().obscureText, isTrue);
    await t.tap(find.byTooltip('Show password'));
    await t.pump();
    expect(field().obscureText, isFalse);
  });

  testWidgets('CTA disabled while submitting', (t) async {
    when(() => bloc.state).thenReturn(
      const AuthState(status: AuthStatus.unauthenticated, isSubmitting: true),
    );
    await pump(t);
    final ink = t.widget<InkWell>(
      find.byKey(const ValueKey('liquid-glass-button-ink')),
    );
    expect(ink.onTap, isNull);
  });

  testWidgets('meets tap-target and label guidelines', (t) async {
    final handle = t.ensureSemantics();
    await pump(t);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
