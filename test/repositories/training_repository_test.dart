import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:training_app/models/training_record.dart';
import 'package:training_app/repositories/training_repository.dart';

void main() {
  late Directory tempDir;
  late Box<TrainingRecord> box;
  late TrainingRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TrainingRecordAdapter());
    }
    box = await Hive.openBox<TrainingRecord>('test_box');
    repository = TrainingRepository(box);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  TrainingRecord createRecord({
    String? id,
    DateTime? date,
    String activity = 'ランニング',
    String duration = '30分',
    String? comment,
    String? location,
    int monthlyCount = 1,
  }) {
    return TrainingRecord(
      id: id,
      date: date ?? DateTime(2024, 3, 5),
      activity: activity,
      duration: duration,
      comment: comment,
      location: location,
      monthlyCount: monthlyCount,
    );
  }

  group('saveRecord', () {
    test('IDなしのレコードを保存するとIDが自動生成される', () async {
      final record = createRecord(id: null);
      await repository.saveRecord(record);

      final records = await repository.getAllRecords();
      expect(records.length, 1);
      expect(records.first.id, isNotNull);
      expect(records.first.id, isNotEmpty);
      expect(records.first.activity, 'ランニング');
    });

    test('ID付きのレコードを保存すると元のIDが維持される', () async {
      final record = createRecord(id: 'my-custom-id');
      await repository.saveRecord(record);

      final retrieved = await repository.getRecordById('my-custom-id');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'my-custom-id');
    });

    test('同じIDで保存すると上書きされる', () async {
      final record1 = createRecord(id: 'same-id', activity: '水泳');
      await repository.saveRecord(record1);

      final record2 = createRecord(id: 'same-id', activity: 'ヨガ');
      await repository.saveRecord(record2);

      final records = await repository.getAllRecords();
      expect(records.length, 1);
      expect(records.first.activity, 'ヨガ');
    });
  });

  group('getAllRecords', () {
    test('空の場合は空リストを返す', () async {
      final records = await repository.getAllRecords();
      expect(records, isEmpty);
    });

    test('新しい日付順にソートされる', () async {
      await repository.saveRecord(
          createRecord(id: 'old', date: DateTime(2024, 1, 1)));
      await repository.saveRecord(
          createRecord(id: 'new', date: DateTime(2024, 3, 1)));
      await repository.saveRecord(
          createRecord(id: 'mid', date: DateTime(2024, 2, 1)));

      final records = await repository.getAllRecords();
      expect(records.length, 3);
      expect(records[0].id, 'new');
      expect(records[1].id, 'mid');
      expect(records[2].id, 'old');
    });

    test('同じ日付のレコードが複数ある場合もエラーにならない', () async {
      await repository.saveRecord(
          createRecord(id: 'a', date: DateTime(2024, 1, 1)));
      await repository.saveRecord(
          createRecord(id: 'b', date: DateTime(2024, 1, 1)));

      final records = await repository.getAllRecords();
      expect(records.length, 2);
    });
  });

  group('getRecordById', () {
    test('存在するIDでレコードを取得できる', () async {
      await repository.saveRecord(
          createRecord(id: 'target', activity: '筋トレ'));

      final record = await repository.getRecordById('target');
      expect(record, isNotNull);
      expect(record!.activity, '筋トレ');
    });

    test('存在しないIDではnullが返る', () async {
      final record = await repository.getRecordById('non-existent');
      expect(record, isNull);
    });
  });

  group('deleteRecord', () {
    test('レコードを削除できる', () async {
      await repository.saveRecord(createRecord(id: 'to-delete'));

      await repository.deleteRecord('to-delete');

      final record = await repository.getRecordById('to-delete');
      expect(record, isNull);
      final records = await repository.getAllRecords();
      expect(records, isEmpty);
    });

    test('存在しないIDを削除してもエラーにならない', () async {
      await repository.deleteRecord('non-existent');
      // エラーが発生しないことを確認
    });
  });

  group('deleteAllRecords', () {
    test('全レコードが削除される', () async {
      await repository.saveRecord(createRecord(id: '1'));
      await repository.saveRecord(createRecord(id: '2'));
      await repository.saveRecord(createRecord(id: '3'));

      await repository.deleteAllRecords();

      final records = await repository.getAllRecords();
      expect(records, isEmpty);
    });
  });

  group('getRecordsByDateRange', () {
    setUp(() async {
      await repository.saveRecord(
          createRecord(id: 'jan', date: DateTime(2024, 1, 15)));
      await repository.saveRecord(
          createRecord(id: 'feb', date: DateTime(2024, 2, 15)));
      await repository.saveRecord(
          createRecord(id: 'mar', date: DateTime(2024, 3, 15)));
      await repository.saveRecord(
          createRecord(id: 'apr', date: DateTime(2024, 4, 15)));
    });

    test('範囲内のレコードのみ返される', () async {
      final records = await repository.getRecordsByDateRange(
        DateTime(2024, 2, 1),
        DateTime(2024, 3, 31),
      );

      expect(records.length, 2);
      final ids = records.map((r) => r.id).toList();
      expect(ids, contains('feb'));
      expect(ids, contains('mar'));
    });

    test('結果は新しい日付順にソートされる', () async {
      final records = await repository.getRecordsByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 12, 31),
      );

      expect(records.length, 4);
      expect(records[0].id, 'apr');
      expect(records[1].id, 'mar');
      expect(records[2].id, 'feb');
      expect(records[3].id, 'jan');
    });

    test('境界日のレコードが含まれる', () async {
      // startDateとendDateの当日のレコードが含まれるか確認
      final records = await repository.getRecordsByDateRange(
        DateTime(2024, 1, 15),
        DateTime(2024, 1, 15),
      );

      expect(records.length, 1);
      expect(records.first.id, 'jan');
    });

    test('範囲外のレコードは含まれない', () async {
      final records = await repository.getRecordsByDateRange(
        DateTime(2024, 5, 1),
        DateTime(2024, 12, 31),
      );

      expect(records, isEmpty);
    });
  });
}
