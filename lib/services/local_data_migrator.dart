import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/training_record.dart';
import '../repositories/training_records_api.dart';

/// ローカルHiveに残っている記録をSupabaseへ一括移行する。
///
/// 「リモートが空のときだけ移行する」条件により、二重移行は起こらない。
/// 移行後もローカルデータは消さず、切り戻し時のバックアップとして残す。
class LocalDataMigrator {
  final Box<TrainingRecord> localBox;
  final TrainingRecordsApi remoteApi;
  final Uuid _uuid;

  LocalDataMigrator({
    required this.localBox,
    required this.remoteApi,
    Uuid uuid = const Uuid(),
  }) : _uuid = uuid;

  /// ローカルの記録件数
  int get localCount => localBox.length;

  /// 移行が必要か（ローカルに記録があり、リモートが空）
  Future<bool> shouldMigrate() async {
    if (localBox.isEmpty) {
      return false;
    }
    return await remoteApi.count() == 0;
  }

  /// ローカルの全記録をリモートへ移行し、移行した件数を返す。
  /// 既存のIDは保持する（IDがない場合のみ採番）。
  Future<int> migrate() async {
    var migrated = 0;
    for (final record in localBox.values) {
      final recordWithId = record.id == null
          ? record.copyWith(id: _uuid.v4())
          : record;
      await remoteApi.upsert(recordWithId.toSupabaseJson());
      migrated++;
    }
    return migrated;
  }
}
