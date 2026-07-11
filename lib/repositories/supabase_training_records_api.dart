import 'package:supabase_flutter/supabase_flutter.dart';
import 'training_records_api.dart';

/// Supabaseクライアントを使用した[TrainingRecordsApi]の実装。
///
/// クエリ構築をこのクラスに閉じ込める薄い層であり、ロジックを持たない。
/// 動作はSupabase接続込みの手動検証でカバーする（単体テスト対象外）。
class SupabaseTrainingRecordsApi implements TrainingRecordsApi {
  static const _table = 'training_records';

  final SupabaseClient _client;

  SupabaseTrainingRecordsApi(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchAllOrderedByDateDesc() async {
    return _client
        .from(_table)
        .select()
        .order('date', ascending: false)
        .order('created_at', ascending: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchById(String id) async {
    return _client.from(_table).select().eq('id', id).maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchByDateRange(
    String startDate,
    String endDate,
  ) async {
    return _client
        .from(_table)
        .select()
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date', ascending: false)
        .order('created_at', ascending: false);
  }

  @override
  Future<void> upsert(Map<String, dynamic> row) async {
    await _client.from(_table).upsert(row);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  @override
  Future<void> deleteAll() async {
    // deleteにはフィルタが必須のため、必ず偽にならない条件で全行を対象にする
    await _client
        .from(_table)
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');
  }

  @override
  Future<int> count() async {
    return _client.from(_table).count();
  }
}
