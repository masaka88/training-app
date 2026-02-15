import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/utils/display_helpers.dart';

void main() {
  group('formatActivityDisplay', () {
    test('改行を「 / 」で結合する', () {
      expect(formatActivityDisplay('ランニング\n筋トレ'), 'ランニング / 筋トレ');
    });

    test('空行を除外する', () {
      expect(formatActivityDisplay('ランニング\n\n筋トレ'), 'ランニング / 筋トレ');
    });

    test('空白のみの行を除外する', () {
      expect(formatActivityDisplay('ランニング\n   \n筋トレ'), 'ランニング / 筋トレ');
    });

    test('1行の場合はそのまま返す', () {
      expect(formatActivityDisplay('ランニング'), 'ランニング');
    });

    test('全行が空白の場合は空文字列を返す', () {
      expect(formatActivityDisplay('\n\n\n'), '');
    });

    test('空文字列の場合は空文字列を返す', () {
      expect(formatActivityDisplay(''), '');
    });

    test('3行以上の結合', () {
      expect(
        formatActivityDisplay('ランニング\n筋トレ\nストレッチ'),
        'ランニング / 筋トレ / ストレッチ',
      );
    });
  });

  group('formatCommentPreview', () {
    test('nullの場合はnullを返す', () {
      expect(formatCommentPreview(null), isNull);
    });

    test('空文字列の場合はnullを返す', () {
      expect(formatCommentPreview(''), isNull);
    });

    test('空白文字のみの場合はnullを返す', () {
      expect(formatCommentPreview('   '), isNull);
    });

    test('20文字以下の場合はそのまま返す', () {
      expect(formatCommentPreview('短いコメント'), '短いコメント');
    });

    test('20文字を超える場合は切り詰めて...を付ける', () {
      final longComment = 'あ' * 25;
      final result = formatCommentPreview(longComment);
      expect(result, '${'あ' * 20}...');
    });

    test('ちょうど20文字の場合はそのまま返す', () {
      final comment = 'あ' * 20;
      expect(formatCommentPreview(comment), comment);
    });

    test('前後の空白がトリムされる', () {
      expect(formatCommentPreview('  コメント  '), 'コメント');
    });

    test('maxLengthを指定できる', () {
      expect(formatCommentPreview('12345678', maxLength: 5), '12345...');
    });
  });

  group('emptyToNull', () {
    test('nullの場合はnullを返す', () {
      expect(emptyToNull(null), isNull);
    });

    test('空文字列の場合はnullを返す', () {
      expect(emptyToNull(''), isNull);
    });

    test('空白文字のみの場合はnullを返す', () {
      expect(emptyToNull('   '), isNull);
    });

    test('内容がある場合はそのまま返す', () {
      expect(emptyToNull('テスト'), 'テスト');
    });

    test('前後に空白がある場合もそのまま返す（トリムしない）', () {
      expect(emptyToNull('  テスト  '), '  テスト  ');
    });
  });

  group('parseIntOrDefault', () {
    test('正常な数値文字列をパースする', () {
      expect(parseIntOrDefault('42'), 42);
    });

    test('nullの場合はデフォルト値を返す', () {
      expect(parseIntOrDefault(null), 0);
    });

    test('パースできない文字列の場合はデフォルト値を返す', () {
      expect(parseIntOrDefault('abc'), 0);
    });

    test('空文字列の場合はデフォルト値を返す', () {
      expect(parseIntOrDefault(''), 0);
    });

    test('fallback値を指定できる', () {
      expect(parseIntOrDefault('abc', fallback: -1), -1);
    });

    test('0をパースできる', () {
      expect(parseIntOrDefault('0'), 0);
    });

    test('負の数をパースできる', () {
      expect(parseIntOrDefault('-5'), -5);
    });

    test('小数点を含む文字列はパースできない', () {
      expect(parseIntOrDefault('3.14'), 0);
    });
  });
}
