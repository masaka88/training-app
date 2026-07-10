import 'package:uuid/uuid.dart';
import '../models/training_record.dart';
import 'training_records_api.dart';
import 'training_repository.dart';

/// Supabaseを使用した[TrainingRepository]のリモート実装。
///
/// 行データとの相互変換とID採番を担い、実際のクエリは
/// [TrainingRecordsApi]に委譲する。
class SupabaseTrainingRepository implements TrainingRepository {
  final TrainingRecordsApi _api;
  final Uuid _uuid;

  SupabaseTrainingRepository(this._api, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  @override
  Future<void> saveRecord(TrainingRecord record) async {
    // IDがない場合は新規作成（Hive実装と同じ採番規則）
    final recordWithId = record.id == null
        ? record.copyWith(id: _uuid.v4())
        : record;

    await _api.upsert(recordWithId.toSupabaseJson());
  }

  @override
  Future<List<TrainingRecord>> getAllRecords() async {
    final rows = await _api.fetchAllOrderedByDateDesc();
    return rows.map(TrainingRecord.fromSupabaseJson).toList();
  }

  @override
  Future<TrainingRecord?> getRecordById(String id) async {
    final row = await _api.fetchById(id);
    return row == null ? null : TrainingRecord.fromSupabaseJson(row);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _api.delete(id);
  }

  @override
  Future<void> deleteAllRecords() async {
    await _api.deleteAll();
  }

  @override
  Future<List<TrainingRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final rows = await _api.fetchByDateRange(
      TrainingRecord.formatDateOnly(startDate),
      TrainingRecord.formatDateOnly(endDate),
    );
    return rows.map(TrainingRecord.fromSupabaseJson).toList();
  }
}
