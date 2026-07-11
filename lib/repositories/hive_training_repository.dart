import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/training_record.dart';
import 'training_repository.dart';

/// Hive Boxを使用した[TrainingRepository]のローカル実装。
///
/// 一部メソッド（getAllRecords, getRecordById, getRecordsByDateRange）は
/// 同期的に完結するが、インターフェースに合わせてFuture型を維持している。
class HiveTrainingRepository implements TrainingRepository {
  final Box<TrainingRecord> _box;
  final Uuid _uuid;

  HiveTrainingRepository(this._box, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  @override
  Future<void> saveRecord(TrainingRecord record) async {
    // IDがない場合は新規作成
    final recordWithId = record.id == null
        ? record.copyWith(id: _uuid.v4())
        : record;

    await _box.put(recordWithId.id, recordWithId);
  }

  @override
  Future<List<TrainingRecord>> getAllRecords() async {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 新しい順にソート
  }

  @override
  Future<TrainingRecord?> getRecordById(String id) async {
    return _box.get(id);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteAllRecords() async {
    await _box.clear();
  }

  @override
  Future<List<TrainingRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _box.values.where((record) {
      return record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          record.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }
}
