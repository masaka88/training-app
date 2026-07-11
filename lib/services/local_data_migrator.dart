import 'package:hive_ce/hive.dart';
import '../models/training_record.dart';
import '../repositories/training_records_api.dart';

/// ローカルHiveに残っている記録をSupabaseへ一括移行する。
///
/// リモートの件数がローカルより少ない間だけ移行を提案する。移行はIDを保持した
/// upsertのため何度実行しても重複せず、途中で失敗しても次回起動時に再提案されて
/// 残りが補完される。移行後もローカルデータは消さず、切り戻し時のバックアップ
/// として残す。
///
/// 既知の制約: 移行完了後にリモート側の削除で件数がローカルを下回ると、再び
/// 移行が提案され削除済みの記録が復元され得る（Hive撤去までの一時的な仕組み）。
class LocalDataMigrator {
  final Box<TrainingRecord> localBox;
  final TrainingRecordsApi remoteApi;

  LocalDataMigrator({required this.localBox, required this.remoteApi});

  /// ローカルの記録件数
  int get localCount => localBox.length;

  /// 移行が必要か（リモートの記録がローカルより少ない）
  Future<bool> shouldMigrate() async {
    if (localBox.isEmpty) {
      return false;
    }
    return await remoteApi.count() < localBox.length;
  }

  /// ローカルの全記録をリモートへ移行し、移行した件数を返す。
  ///
  /// ローカルの記録は保存時に必ずIDが採番されているため、そのままのIDで
  /// upsertする（再実行しても重複しない）。
  Future<int> migrate() async {
    var migrated = 0;
    for (final record in localBox.values) {
      await remoteApi.upsert(record.toSupabaseJson());
      migrated++;
    }
    return migrated;
  }
}
