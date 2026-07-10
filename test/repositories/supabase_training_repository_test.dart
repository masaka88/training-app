import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:training_app/models/training_record.dart';
import 'package:training_app/repositories/supabase_training_repository.dart';
import 'package:training_app/repositories/training_records_api.dart';

class MockTrainingRecordsApi extends Mock implements TrainingRecordsApi {}

void main() {
  late MockTrainingRecordsApi mockApi;
  late SupabaseTrainingRepository repository;

  setUp(() {
    mockApi = MockTrainingRecordsApi();
    repository = SupabaseTrainingRepository(mockApi);
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

  Map<String, dynamic> createRow({
    String id = 'row-id',
    String date = '2024-03-05',
    String activity = 'ランニング',
    String duration = '30分',
    String? comment,
    String? location,
    int monthlyCount = 1,
    String createdAt = '2024-03-05T10:00:00Z',
  }) {
    return {
      'id': id,
      'date': date,
      'activity': activity,
      'duration': duration,
      'comment': comment,
      'location': location,
      'monthly_count': monthlyCount,
      'created_at': createdAt,
    };
  }

  group('saveRecord', () {
    setUp(() {
      when(() => mockApi.upsert(any())).thenAnswer((_) async {});
    });

    test('IDなしのレコードはUUIDが採番されてupsertされる', () async {
      await repository.saveRecord(createRecord(id: null));

      final row =
          verify(() => mockApi.upsert(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(row['id'], isNotNull);
      expect(row['id'], isA<String>());
      expect((row['id'] as String).length, 36); // UUID v4
    });

    test('ID付きのレコードは元のIDでupsertされる', () async {
      await repository.saveRecord(createRecord(id: 'my-custom-id'));

      final row =
          verify(() => mockApi.upsert(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(row['id'], 'my-custom-id');
    });

    test('snake_caseの行としてupsertされ、dateは日付文字列になる', () async {
      await repository.saveRecord(
        createRecord(id: 'id-1', date: DateTime(2024, 3, 5), monthlyCount: 7),
      );

      final row =
          verify(() => mockApi.upsert(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(row['date'], '2024-03-05');
      expect(row['monthly_count'], 7);
      expect(row.keys, isNot(contains('user_id')));
    });
  });

  group('getAllRecords', () {
    test('APIの行がTrainingRecordに変換されて返る', () async {
      when(() => mockApi.fetchAllOrderedByDateDesc()).thenAnswer(
        (_) async => [
          createRow(id: 'new', date: '2024-03-01'),
          createRow(id: 'old', date: '2024-01-01'),
        ],
      );

      final records = await repository.getAllRecords();

      expect(records.length, 2);
      expect(records[0].id, 'new');
      expect(records[0].date, DateTime(2024, 3, 1));
      expect(records[1].id, 'old');
    });

    test('空の場合は空リストを返す', () async {
      when(
        () => mockApi.fetchAllOrderedByDateDesc(),
      ).thenAnswer((_) async => []);

      expect(await repository.getAllRecords(), isEmpty);
    });
  });

  group('getRecordById', () {
    test('存在するIDでレコードを取得できる', () async {
      when(
        () => mockApi.fetchById('target'),
      ).thenAnswer((_) async => createRow(id: 'target', activity: '筋トレ'));

      final record = await repository.getRecordById('target');

      expect(record, isNotNull);
      expect(record!.id, 'target');
      expect(record.activity, '筋トレ');
    });

    test('存在しないIDではnullが返る', () async {
      when(
        () => mockApi.fetchById('non-existent'),
      ).thenAnswer((_) async => null);

      expect(await repository.getRecordById('non-existent'), isNull);
    });
  });

  group('deleteRecord / deleteAllRecords', () {
    test('deleteRecordはIDを渡してAPIを呼ぶ', () async {
      when(() => mockApi.delete(any())).thenAnswer((_) async {});

      await repository.deleteRecord('to-delete');

      verify(() => mockApi.delete('to-delete')).called(1);
    });

    test('deleteAllRecordsはAPIのdeleteAllを呼ぶ', () async {
      when(() => mockApi.deleteAll()).thenAnswer((_) async {});

      await repository.deleteAllRecords();

      verify(() => mockApi.deleteAll()).called(1);
    });
  });

  group('getRecordsByDateRange', () {
    test('日付が文字列に変換されてAPIに渡り、結果が変換されて返る', () async {
      when(
        () => mockApi.fetchByDateRange('2024-02-01', '2024-03-31'),
      ).thenAnswer((_) async => [createRow(id: 'feb', date: '2024-02-15')]);

      final records = await repository.getRecordsByDateRange(
        DateTime(2024, 2, 1),
        DateTime(2024, 3, 31),
      );

      expect(records.length, 1);
      expect(records.first.id, 'feb');
      expect(records.first.date, DateTime(2024, 2, 15));
    });
  });
}
