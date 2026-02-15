import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:training_app/models/training_record.dart';
import 'package:training_app/repositories/training_repository.dart';
import 'package:training_app/screens/training_record_list.dart';

class MockTrainingRepository extends Mock implements TrainingRepository {}

void main() {
  late MockTrainingRepository mockRepository;

  setUp(() {
    mockRepository = MockTrainingRepository();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: TrainingRecordList(repositoryOverride: mockRepository),
    );
  }

  group('TrainingRecordList', () {
    testWidgets('レコードがない場合は空状態メッセージを表示する', (tester) async {
      when(() => mockRepository.getAllRecords()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      // 初回pumpでFutureを解決
      await tester.pump();

      expect(find.text('記録がありません'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('ローディング中はCircularProgressIndicatorを表示する', (tester) async {
      // Completerで解決しないFutureを作りローディング状態を維持
      final completer = Completer<List<TrainingRecord>>();
      when(
        () => mockRepository.getAllRecords(),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('記録がありません'), findsNothing);

      // テスト後にCompleterを完了させてクリーンアップ
      completer.complete([]);
      await tester.pump();
    });

    testWidgets('レコードがある場合はリストを表示する', (tester) async {
      final records = [
        TrainingRecord(
          id: 'test-1',
          date: DateTime(2024, 3, 5),
          activity: 'ランニング',
          duration: '30分',
          monthlyCount: 5,
        ),
      ];
      when(
        () => mockRepository.getAllRecords(),
      ).thenAnswer((_) async => records);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('記録がありません'), findsNothing);
      expect(find.textContaining('ランニング'), findsOneWidget);
    });

    testWidgets('複数レコードがある場合は全て表示される', (tester) async {
      final records = [
        TrainingRecord(
          id: 'test-1',
          date: DateTime(2024, 3, 6),
          activity: '筋トレ',
          duration: '45分',
          monthlyCount: 6,
        ),
        TrainingRecord(
          id: 'test-2',
          date: DateTime(2024, 3, 5),
          activity: 'ランニング',
          duration: '30分',
          monthlyCount: 5,
        ),
      ];
      when(
        () => mockRepository.getAllRecords(),
      ).thenAnswer((_) async => records);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.textContaining('ランニング'), findsOneWidget);
      expect(find.textContaining('筋トレ'), findsOneWidget);
    });

    testWidgets('FABが表示される', (tester) async {
      when(() => mockRepository.getAllRecords()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('AppBarにタイトルが表示される', (tester) async {
      when(() => mockRepository.getAllRecords()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('トレーニング記録'), findsOneWidget);
    });
  });
}
