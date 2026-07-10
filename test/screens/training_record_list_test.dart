import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:training_app/models/training_record.dart';
import 'package:training_app/repositories/training_repository.dart';
import 'package:training_app/screens/training_record_list.dart';
import 'package:training_app/services/local_data_migrator.dart';

class MockTrainingRepository extends Mock implements TrainingRepository {}

class MockLocalDataMigrator extends Mock implements LocalDataMigrator {}

void main() {
  late MockTrainingRepository mockRepository;

  setUp(() {
    mockRepository = MockTrainingRepository();
  });

  Widget buildTestWidget({LocalDataMigrator? migrator}) {
    return MaterialApp(
      home: TrainingRecordList(
        repositoryOverride: mockRepository,
        migratorOverride: migrator,
      ),
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

  group('データ移行ダイアログ', () {
    late MockLocalDataMigrator mockMigrator;

    setUp(() {
      mockMigrator = MockLocalDataMigrator();
      when(() => mockRepository.getAllRecords()).thenAnswer((_) async => []);
    });

    testWidgets('移行が必要な場合は確認ダイアログが表示される', (tester) async {
      when(() => mockMigrator.shouldMigrate()).thenAnswer((_) async => true);
      when(() => mockMigrator.localCount).thenReturn(3);

      await tester.pumpWidget(buildTestWidget(migrator: mockMigrator));
      await tester.pump();
      await tester.pump();

      expect(find.text('データ移行'), findsOneWidget);
      expect(find.text('この端末に保存されている3件の記録をサーバーへ移行しますか？'), findsOneWidget);
    });

    testWidgets('「移行する」を選ぶとmigrateが呼ばれ完了メッセージが出る', (tester) async {
      when(() => mockMigrator.shouldMigrate()).thenAnswer((_) async => true);
      when(() => mockMigrator.localCount).thenReturn(3);
      when(() => mockMigrator.migrate()).thenAnswer((_) async => 3);

      await tester.pumpWidget(buildTestWidget(migrator: mockMigrator));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('移行する'));
      await tester.pump();
      await tester.pump();

      verify(() => mockMigrator.migrate()).called(1);
      expect(find.text('3件の記録を移行しました'), findsOneWidget);
    });

    testWidgets('「あとで」を選ぶとmigrateは呼ばれない', (tester) async {
      when(() => mockMigrator.shouldMigrate()).thenAnswer((_) async => true);
      when(() => mockMigrator.localCount).thenReturn(3);

      await tester.pumpWidget(buildTestWidget(migrator: mockMigrator));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('あとで'));
      await tester.pump();

      verifyNever(() => mockMigrator.migrate());
      expect(find.text('データ移行'), findsNothing);
    });

    testWidgets('移行が不要な場合はダイアログが表示されない', (tester) async {
      when(() => mockMigrator.shouldMigrate()).thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget(migrator: mockMigrator));
      await tester.pump();
      await tester.pump();

      expect(find.text('データ移行'), findsNothing);
    });
  });
}
