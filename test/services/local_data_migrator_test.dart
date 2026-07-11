import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:training_app/models/training_record.dart';
import 'package:training_app/repositories/training_records_api.dart';
import 'package:training_app/services/local_data_migrator.dart';

class MockTrainingRecordsApi extends Mock implements TrainingRecordsApi {}

void main() {
  late Directory tempDir;
  late Box<TrainingRecord> box;
  late MockTrainingRecordsApi mockApi;
  late LocalDataMigrator migrator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TrainingRecordAdapter());
    }
    box = await Hive.openBox<TrainingRecord>('test_box');
    mockApi = MockTrainingRecordsApi();
    migrator = LocalDataMigrator(localBox: box, remoteApi: mockApi);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  TrainingRecord createRecord({required String id, String activity = 'ランニング'}) {
    return TrainingRecord(
      id: id,
      date: DateTime(2024, 3, 5),
      activity: activity,
      duration: '30分',
      monthlyCount: 1,
    );
  }

  group('shouldMigrate', () {
    test('ローカルが空の場合はfalse（リモートへの問い合わせもしない）', () async {
      expect(await migrator.shouldMigrate(), isFalse);
      verifyNever(() => mockApi.count());
    });

    test('リモートがローカル以上の場合はfalse', () async {
      await box.put('a', createRecord(id: 'a'));
      when(() => mockApi.count()).thenAnswer((_) async => 3);

      expect(await migrator.shouldMigrate(), isFalse);
    });

    test('リモートとローカルが同数の場合はfalse（移行完了後の再プロンプト防止）', () async {
      await box.put('a', createRecord(id: 'a'));
      await box.put('b', createRecord(id: 'b'));
      when(() => mockApi.count()).thenAnswer((_) async => 2);

      expect(await migrator.shouldMigrate(), isFalse);
    });

    test('ローカルに記録がありリモートが空の場合はtrue', () async {
      await box.put('a', createRecord(id: 'a'));
      when(() => mockApi.count()).thenAnswer((_) async => 0);

      expect(await migrator.shouldMigrate(), isTrue);
    });

    test('リモートがローカルより少ない場合はtrue（部分失敗後の再開）', () async {
      await box.put('a', createRecord(id: 'a'));
      await box.put('b', createRecord(id: 'b'));
      when(() => mockApi.count()).thenAnswer((_) async => 1);

      expect(await migrator.shouldMigrate(), isTrue);
    });
  });

  group('migrate', () {
    test('全レコードがIDを保持したままupsertされ、件数が返る', () async {
      await box.put('id-1', createRecord(id: 'id-1', activity: '筋トレ'));
      await box.put('id-2', createRecord(id: 'id-2', activity: '水泳'));
      when(() => mockApi.upsert(any())).thenAnswer((_) async {});

      final migrated = await migrator.migrate();

      expect(migrated, 2);
      final rows = verify(
        () => mockApi.upsert(captureAny()),
      ).captured.cast<Map<String, dynamic>>();
      final ids = rows.map((row) => row['id']).toSet();
      expect(ids, {'id-1', 'id-2'});
    });

    test('ローカルが空の場合は0を返しupsertしない', () async {
      expect(await migrator.migrate(), 0);
      verifyNever(() => mockApi.upsert(any()));
    });
  });

  group('localCount', () {
    test('ローカルの件数を返す', () async {
      expect(migrator.localCount, 0);
      await box.put('a', createRecord(id: 'a'));
      expect(migrator.localCount, 1);
    });
  });
}
