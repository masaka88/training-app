import '../models/training_record.dart';

/// トレーニング記録のデータアクセス層のインターフェース。
///
/// 実装をローカル（Hive）からリモート（Supabase等）へ差し替えられるよう、
/// すべてのメソッドをFuture型で統一している。
abstract interface class TrainingRepository {
  /// トレーニング記録を保存
  Future<void> saveRecord(TrainingRecord record);

  /// すべてのトレーニング記録を取得（新しい日付順）
  Future<List<TrainingRecord>> getAllRecords();

  /// 特定のIDのトレーニング記録を取得
  Future<TrainingRecord?> getRecordById(String id);

  /// トレーニング記録を削除
  Future<void> deleteRecord(String id);

  /// すべてのトレーニング記録を削除（デバッグ用）
  Future<void> deleteAllRecords();

  /// 指定された日付範囲のレコードを取得（新しい日付順）
  Future<List<TrainingRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}
