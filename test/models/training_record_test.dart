import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/training_record.dart';

void main() {
  group('TrainingRecord', () {
    late TrainingRecord record;

    setUp(() {
      record = TrainingRecord(
        id: 'test-id-123',
        date: DateTime(2024, 3, 5),
        activity: 'ランニング',
        duration: '30分',
        comment: 'いい天気だった',
        location: '公園',
        monthlyCount: 5,
        createdAt: DateTime(2024, 3, 5, 10, 0),
      );
    });

    group('formattedDate', () {
      test('yyyy/M/d形式で日付を返す', () {
        expect(record.formattedDate, '2024/3/5');
      });

      test('月・日が2桁の場合もゼロパディングなし', () {
        final r = record.copyWith(date: DateTime(2024, 12, 25));
        expect(r.formattedDate, '2024/12/25');
      });

      test('月・日が1桁の場合', () {
        final r = record.copyWith(date: DateTime(2024, 1, 1));
        expect(r.formattedDate, '2024/1/1');
      });
    });

    group('toJson / fromJson', () {
      test('ラウンドトリップで全フィールドが保持される', () {
        final json = record.toJson();
        final restored = TrainingRecord.fromJson(json);

        expect(restored.id, record.id);
        expect(restored.date, record.date);
        expect(restored.activity, record.activity);
        expect(restored.duration, record.duration);
        expect(restored.comment, record.comment);
        expect(restored.location, record.location);
        expect(restored.monthlyCount, record.monthlyCount);
        expect(restored.createdAt, record.createdAt);
      });

      test('nullableフィールドがnullの場合もラウンドトリップできる', () {
        final r = TrainingRecord(
          id: null,
          date: DateTime(2024, 1, 1),
          activity: 'テスト',
          duration: '10分',
          comment: null,
          location: null,
          monthlyCount: 1,
        );
        final json = r.toJson();
        final restored = TrainingRecord.fromJson(json);

        expect(restored.id, isNull);
        expect(restored.comment, isNull);
        expect(restored.location, isNull);
      });

      test('toJsonが正しいキーと型を含む', () {
        final json = record.toJson();

        expect(json['id'], isA<String>());
        expect(json['date'], isA<String>());
        expect(json['activity'], isA<String>());
        expect(json['duration'], isA<String>());
        expect(json['comment'], isA<String>());
        expect(json['location'], isA<String>());
        expect(json['monthlyCount'], isA<int>());
        expect(json['createdAt'], isA<String>());
      });

      test('dateはISO8601形式で保存される', () {
        final json = record.toJson();
        expect(json['date'], record.date.toIso8601String());
      });
    });

    group('copyWith', () {
      test('指定したフィールドだけ変更される', () {
        final copied = record.copyWith(activity: '水泳', monthlyCount: 10);

        expect(copied.activity, '水泳');
        expect(copied.monthlyCount, 10);
        // 変更していないフィールドは元のまま
        expect(copied.id, record.id);
        expect(copied.date, record.date);
        expect(copied.duration, record.duration);
        expect(copied.comment, record.comment);
        expect(copied.location, record.location);
        expect(copied.createdAt, record.createdAt);
      });

      test('引数なしで呼ぶと全フィールドが同一のコピーが返る', () {
        final copied = record.copyWith();

        expect(copied.id, record.id);
        expect(copied.date, record.date);
        expect(copied.activity, record.activity);
        expect(copied.duration, record.duration);
        expect(copied.comment, record.comment);
        expect(copied.location, record.location);
        expect(copied.monthlyCount, record.monthlyCount);
        expect(copied.createdAt, record.createdAt);
      });

      test('nullableフィールドにnullを渡しても元の値が維持される（既知の制約）', () {
        // copyWithの現在の実装では comment: null で元の値をクリアできない
        final copied = record.copyWith(comment: null);
        expect(copied.comment, record.comment);
      });
    });

    group('toSlackMessage', () {
      test('基本的なフォーマットが正しい', () {
        final message = record.toSlackMessage();

        expect(message, contains('*日付*'));
        expect(message, contains('2024/03/05'));
        expect(message, contains('*何をしたか*'));
        expect(message, contains('ランニング'));
        expect(message, contains('*どれくらいやったか*'));
        expect(message, contains('30分'));
        expect(message, contains('*コメント*'));
        expect(message, contains('いい天気だった'));
        expect(message, contains('*どこでやったか*'));
        expect(message, contains('公園'));
        expect(message, contains('*3月の運動回数*'));
        expect(message, contains('5'));
      });

      test('日付がゼロパディングされている', () {
        final message = record.toSlackMessage();
        expect(message, contains('2024/03/05'));
      });

      test('commentがnullの場合はコメントセクションが含まれない', () {
        // copyWithではnullに設定できないので、新規作成
        final noComment = TrainingRecord(
          date: DateTime(2024, 3, 5),
          activity: 'ランニング',
          duration: '30分',
          comment: null,
          monthlyCount: 5,
        );
        final message = noComment.toSlackMessage();
        expect(message, isNot(contains('*コメント*')));
      });

      test('commentが空白文字のみの場合はコメントセクションが含まれない', () {
        final r = TrainingRecord(
          date: DateTime(2024, 3, 5),
          activity: 'ランニング',
          duration: '30分',
          comment: '   ',
          monthlyCount: 5,
        );
        final message = r.toSlackMessage();
        expect(message, isNot(contains('*コメント*')));
      });

      test('locationがnullの場合は場所セクションが含まれない', () {
        final noLocation = TrainingRecord(
          date: DateTime(2024, 3, 5),
          activity: 'ランニング',
          duration: '30分',
          location: null,
          monthlyCount: 5,
        );
        final message = noLocation.toSlackMessage();
        expect(message, isNot(contains('*どこでやったか*')));
      });

      test('locationが空白文字のみの場合は場所セクションが含まれない', () {
        final r = TrainingRecord(
          date: DateTime(2024, 3, 5),
          activity: 'ランニング',
          duration: '30分',
          location: '   ',
          monthlyCount: 5,
        );
        final message = r.toSlackMessage();
        expect(message, isNot(contains('*どこでやったか*')));
      });

      test('メッセージが改行で結合されている', () {
        final message = record.toSlackMessage();
        final lines = message.split('\n');
        // 最低でも日付、活動、時間、月の回数のペアがある
        expect(lines.length, greaterThanOrEqualTo(8));
      });
    });

    group('コンストラクタ', () {
      test('createdAtを指定しない場合はDateTime.now()が使われる', () {
        final before = DateTime.now();
        final r = TrainingRecord(
          date: DateTime(2024, 1, 1),
          activity: 'テスト',
          duration: '10分',
          monthlyCount: 1,
        );
        final after = DateTime.now();

        expect(r.createdAt.isAfter(before) || r.createdAt == before, isTrue);
        expect(r.createdAt.isBefore(after) || r.createdAt == after, isTrue);
      });

      test('createdAtを指定した場合はその値が使われる', () {
        final specific = DateTime(2023, 6, 15);
        final r = TrainingRecord(
          date: DateTime(2024, 1, 1),
          activity: 'テスト',
          duration: '10分',
          monthlyCount: 1,
          createdAt: specific,
        );
        expect(r.createdAt, specific);
      });
    });
  });
}
