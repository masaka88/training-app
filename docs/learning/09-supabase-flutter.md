# 9. supabase_flutter SDK

関連フェーズ: Phase 4（認証）、Phase 5（SupabaseTrainingRepository）

## 概念

### 初期化とクライアント

`supabase_flutter` はアプリ起動時に一度だけ初期化し、以降はシングルトンのクライアントを使う:

```dart
await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
final SupabaseClient client = Supabase.instance.client;
```

初期化時に localStorage から**前回のセッションを自動復元**し、JWT の自動リフレッシュも始まる（02 参照）。だから `main.dart` の `Supabase.initialize` → `AuthGate` の順に並べるだけで「ブラウザ再訪時はログイン済みで一覧が出る」が成立する。

クライアントは大きく2つの顔を持つ:

- `client.auth` … GoTrueClient（signInWithPassword / signOut / onAuthStateChange）
- `client.from('table')` … PostgrestClient（CRUD）

### PostgREST のメソッドチェーン

SQL を書く代わりに、メソッドチェーンでクエリを組み立てる。**行は `Map<String, dynamic>`、結果は `List<Map<String, dynamic>>`** で返る:

```dart
// SELECT * FROM training_records ORDER BY date DESC（RLSにより自分の行だけ）
final rows = await client
    .from('training_records')
    .select()
    .order('date', ascending: false);

// WHERE id = ? の1件取得（0件なら null。.single() だと0件で例外なので maybeSingle を使う）
final row = await client
    .from('training_records')
    .select()
    .eq('id', id)
    .maybeSingle();

// 日付範囲（date は 'yyyy-MM-dd' 文字列で比較する — トピック13の核心）
final ranged = await client
    .from('training_records')
    .select()
    .gte('date', '2026-07-01')
    .lte('date', '2026-07-31')
    .order('date', ascending: false);

// UPSERT（id が既存なら UPDATE、なければ INSERT — Hive の box.put と同じ意味論）
await client.from('training_records').upsert(record.toSupabaseJson());

// DELETE
await client.from('training_records').delete().eq('id', id);

// 件数だけ取得（移行判定の「リモート0件」チェックに使う）
final count = await client.from('training_records').count();
```

押さえるべき性質:

- チェーンの各段は Builder を返し、**await した時点で初めて HTTP リクエストが飛ぶ**
- エラーは戻り値でなく **例外**（`PostgrestException`）で通知される
- `upsert` が `saveRecord` の実装になるのは、既存 Hive 実装の `box.put(id, record)` が「あれば上書き・なければ追加」だから。意味論を揃えることで画面側のコードを変えずに済む

### auth API

```dart
await client.auth.signInWithPassword(email: email, password: password);
await client.auth.signOut();
client.auth.currentSession;    // null ならログアウト状態
client.auth.onAuthStateChange; // Stream<AuthState>
```

詳細と AuthService への包み方は 02 を参照。

### なぜ Repository が SDK を直接使わないのか（Phase 5 の設計）

チェーンの各段が返す Builder 型（`PostgrestFilterBuilder` 等）は多段でモックが困難。そこで計画では **`Map<String, dynamic>` を境界とする `TrainingRecordsApi` interface** を挟む:

```
画面 → TrainingRepository(interface)
         → SupabaseTrainingRepository   … uuid採番 + Map⇔モデル変換（単体テスト対象）
             → TrainingRecordsApi(interface)  … ここを mocktail でモック
                 → SupabaseTrainingRecordsApi … 上記チェーンを書く唯一の場所（テスト対象外の薄い層）
```

「テストしにくいコードは、テストしなくて済むほど薄くする」という Humble Object パターン。

## このプロジェクトでの具体例

導入は Phase 4 で:

```bash
devcontainer exec --workspace-folder <プロジェクトルート> flutter pub add supabase_flutter
```

接続情報はコンパイル時定数で注入（anon key は公開可 — 02 参照）:

```dart
// lib/config/supabase_config.dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```

```bash
devcontainer exec --workspace-folder <プロジェクトルート> flutter run \
  -d web-server --web-port=3000 --web-hostname=0.0.0.0 \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

`SupabaseTrainingRepository.getAllRecords()` のイメージ（既存 Hive 実装の「新しい順ソート」を DB 側の `order` に置き換える）:

```dart
@override
Future<List<TrainingRecord>> getAllRecords() async {
  final rows = await _api.fetchAllOrderedByDateDesc();
  return rows.map(TrainingRecord.fromSupabaseJson).toList();
}
```

## 最小演習

1. 使い捨てプロジェクトの `training_records`（01 の演習で作成済み）にダッシュボードから手動で1行 INSERT（user_id は演習ユーザーのIDを指定）
2. 素の Dart スクリプトか小さな Flutter アプリで `Supabase.initialize` → `signInWithPassword` → `select().order('date', ascending: false)` を実行し、`List<Map<String, dynamic>>` の生の形（snake_case キー、date が文字列）を print で確認
3. ログインせずに同じ SELECT を実行 → 例外ではなく**空リスト**が返ることを確認（RLS の「エラーでなく0行」を SDK 越しに体感）

手順2で見た Map の形が、そのまま Phase 5 の `TrainingRecordsApi` の境界データ、Phase 2 の `fromSupabaseJson()` の入力になる。
