/// training_recordsテーブルへの行単位のアクセスAPI。
///
/// Supabaseクライアントのクエリビルダはメソッドチェーンで構成されるため
/// モックが難しい。そこで「行 = Map&lt;String, dynamic&gt;」を境界とする
/// このインターフェースを挟み、リポジトリ層をテスト可能にする。
/// 日付は 'yyyy-MM-dd' 形式の文字列で受け渡す。
abstract interface class TrainingRecordsApi {
  /// 全行を日付の新しい順で取得
  Future<List<Map<String, dynamic>>> fetchAllOrderedByDateDesc();

  /// IDで1行取得（存在しなければnull）
  Future<Map<String, dynamic>?> fetchById(String id);

  /// 日付範囲（両端含む）の行を日付の新しい順で取得
  Future<List<Map<String, dynamic>>> fetchByDateRange(
    String startDate,
    String endDate,
  );

  /// 1行を挿入または更新
  Future<void> upsert(Map<String, dynamic> row);

  /// IDで1行削除
  Future<void> delete(String id);

  /// 全行削除（デバッグ用）
  Future<void> deleteAll();

  /// 行数を取得
  Future<int> count();
}
