import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/auth/presentation/screens/register_screen.dart';
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

  Future<void> fill(WidgetTester t, String pw, String confirm) async {
    await t.pumpApp(const RegisterScreen(), authBloc: bloc);
    await t.enterText(find.byKey(RegisterScreen.emailKey), 'new@gig.dev');
    await t.enterText(find.byKey(RegisterScreen.passwordKey), pw);
    await t.enterText(find.byKey(RegisterScreen.confirmKey), confirm);
    await t.ensureVisible(find.byKey(RegisterScreen.submitKey));
    await t.tap(find.byKey(RegisterScreen.submitKey));
    await t.pump();
  }

  testWidgets('weak password is rejected', (t) async {
    await fill(t, 'abcdef', 'abcdef');
    expect(
      find.text('Include at least one letter and one number.'),
      findsOneWidget,
    );
    verifyNever(() => bloc.add(any(that: isA<AuthRegisterSubmitted>())));
  });

  testWidgets('confirm mismatch is rejected', (t) async {
    await fill(t, 'abc123', 'abc124');
    expect(find.text('Passwords do not match.'), findsOneWidget);
    verifyNever(() => bloc.add(any(that: isA<AuthRegisterSubmitted>())));
  });

  testWidgets('valid form dispatches register', (t) async {
    await fill(t, 'abc123', 'abc123');
    verify(
      () => bloc.add(
        const AuthRegisterSubmitted(email: 'new@gig.dev', password: 'abc123'),
      ),
    ).called(1);
  });
}
