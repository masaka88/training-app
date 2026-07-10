import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:training_app/screens/login_screen.dart';
import 'package:training_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget buildTestWidget() {
    return MaterialApp(home: LoginScreen(authServiceOverride: mockAuthService));
  }

  group('LoginScreen', () {
    testWidgets('メールアドレスとパスワードの入力欄とログインボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('ログイン'), findsWidgets);
    });

    testWidgets('入力した認証情報でsignInWithPasswordが呼ばれる', (tester) async {
      when(
        () => mockAuthService.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), ' user@example.com ');
      await tester.enterText(fields.at(1), 'secret');
      await tester.tap(find.widgetWithText(ElevatedButton, 'ログイン'));
      await tester.pump();

      verify(
        () => mockAuthService.signInWithPassword(
          email: 'user@example.com', // trimされる
          password: 'secret',
        ),
      ).called(1);
    });

    testWidgets('未入力で送信するとバリデーションエラーが表示されsignInは呼ばれない', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.widgetWithText(ElevatedButton, 'ログイン'));
      await tester.pump();

      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(find.text('パスワードを入力してください'), findsOneWidget);
      verifyNever(
        () => mockAuthService.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('ログイン失敗時はエラーのSnackBarが表示される', (tester) async {
      when(
        () => mockAuthService.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('invalid credentials'));

      await tester.pumpWidget(buildTestWidget());
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), 'wrong');
      await tester.tap(find.widgetWithText(ElevatedButton, 'ログイン'));
      await tester.pump();

      expect(find.text('ログインに失敗しました。メールアドレスとパスワードを確認してください。'), findsOneWidget);
    });
  });
}
