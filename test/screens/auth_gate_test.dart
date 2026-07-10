import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:training_app/repositories/repository_provider.dart';
import 'package:training_app/repositories/training_repository.dart';
import 'package:training_app/screens/auth_gate.dart';
import 'package:training_app/screens/login_screen.dart';
import 'package:training_app/screens/training_record_list.dart';
import 'package:training_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockTrainingRepository extends Mock implements TrainingRepository {}

void main() {
  late MockAuthService mockAuthService;
  late StreamController<bool> signedInController;

  // TrainingRecordListが参照するグローバルrepositoryを初期化する
  // （late finalのためisolateごとに一度だけ代入できる）
  final mockRepository = MockTrainingRepository();
  repository = mockRepository;

  setUp(() {
    mockAuthService = MockAuthService();
    signedInController = StreamController<bool>();
    when(
      () => mockAuthService.signedInChanges,
    ).thenAnswer((_) => signedInController.stream);
    when(() => mockRepository.getAllRecords()).thenAnswer((_) async => []);
  });

  tearDown(() async {
    await signedInController.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(home: AuthGate(authServiceOverride: mockAuthService));
  }

  group('AuthGate', () {
    testWidgets('未ログインの場合はログイン画面を表示する', (tester) async {
      when(() => mockAuthService.isSignedIn).thenReturn(false);

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TrainingRecordList), findsNothing);
    });

    testWidgets('ログイン済みの場合は一覧画面を表示する', (tester) async {
      when(() => mockAuthService.isSignedIn).thenReturn(true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(TrainingRecordList), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('ログイン状態がtrueに変化すると一覧画面に切り替わる', (tester) async {
      when(() => mockAuthService.isSignedIn).thenReturn(false);

      await tester.pumpWidget(buildTestWidget());
      expect(find.byType(LoginScreen), findsOneWidget);

      signedInController.add(true);
      await tester.pump();
      await tester.pump();

      expect(find.byType(TrainingRecordList), findsOneWidget);
    });

    testWidgets('ログイン状態がfalseに変化するとログイン画面に切り替わる', (tester) async {
      when(() => mockAuthService.isSignedIn).thenReturn(true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      signedInController.add(false);
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
