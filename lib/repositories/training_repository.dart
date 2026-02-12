import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/training_record.dart';

class TrainingRepository {
  final Box<TrainingRecord> _box;
  final Uuid _uuid;

  TrainingRepository(this._box, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  /// トレーニング記録を保存
  Future<void> saveRecord(TrainingRecord record) async {
    // IDがない場合は新規作成
    final recordWithId = record.id == null
        ? record.copyWith(id: _uuid.v4())
        : record;

    await _box.put(recordWithId.id, recordWithId);
  }

  /// すべてのトレーニング記録を取得
  Future<List<TrainingRecord>> getAllRecords() async {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 新しい順にソート
  }

  /// 特定のIDのトレーニング記録を取得
  Future<TrainingRecord?> getRecordById(String id) async {
    return _box.get(id);
  }

  /// トレーニング記録を削除
  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
  }

  /// すべてのトレーニング記録を削除（デバッグ用）
  Future<void> deleteAllRecords() async {
    await _box.clear();
  }

  /// 指定された日付範囲のレコードを取得
  Future<List<TrainingRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _box.values.where((record) {
      return record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          record.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
