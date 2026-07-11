# 1. Postgres + RLS（Row Level Security）

関連フェーズ: Phase 3（`supabase/migrations/..._create_training_records.sql`）

## 概念

### RLS とは何か、なぜ必要か

Supabase では、アプリ（ブラウザ）が Postgres に **PostgREST という REST API 経由で直接アクセスする**。従来の「アプリ → 自作APIサーバー → DB」という構成のAPIサーバー層が存在しないため、「このユーザーはこの行を読んでよいか」という認可ロジックを置く場所が DB 自身しかない。それが RLS。

RLS を有効にしたテーブルは、**ポリシーで明示的に許可された行しか見えない・触れない**（デフォルト拒否）。ポリシーは SQL の `WHERE` 句が全クエリに自動付与されるイメージ:

```sql
alter table training_records enable row level security;
```

これだけだと誰も何もできない。そこに操作別のポリシーを足していく。

### ポリシーの4操作と USING / WITH CHECK

| 操作 | 検査タイミング | 使う句 |
|---|---|---|
| SELECT | 行を読むとき | `USING` |
| INSERT | 行を作るとき | `WITH CHECK` |
| UPDATE | 行を書き換えるとき | `USING`（対象行の特定）+ `WITH CHECK`（変更後の行の検証） |
| DELETE | 行を消すとき | `USING` |

- `USING` = 「既にある行が条件を満たすか」
- `WITH CHECK` = 「これから書き込む行が条件を満たすか」

UPDATE に両方あるのは「自分の行を、他人の行に書き換える」攻撃（`user_id` を他人のIDに変更）を防ぐため。

### auth.uid() の正体

Supabase の認証はJWT（後述の 02 参照）で行われ、PostgREST はリクエストの JWT を検証してその中身を Postgres のセッション変数に展開する。`auth.uid()` はそこから `sub` クレーム（= ログイン中ユーザーの UUID）を取り出すだけの関数。未ログイン（anon key のみ）なら `NULL` を返すので、`user_id = auth.uid()` はどの行にもマッチせず自然に全拒否になる。

`user_id uuid not null default auth.uid()` とデフォルトを付けると、**アプリ側は user_id を送らなくてよい**（計画の Phase 5「`user_id` は送らず DB default に任せる」の根拠）。クライアントが偽の user_id を送っても `WITH CHECK` で弾かれる。

### date 型 vs timestamptz 型

| 型 | 中身 | 用途 |
|---|---|---|
| `date` | 年月日のみ。タイムゾーン概念なし | 「7月11日にトレーニングした」という**暦の日付** |
| `timestamptz` | UTC の瞬間（マイクロ秒精度）。表示時にTZ変換 | 「この瞬間に投稿された」という**時刻** |

トレーニングの `date` は「何日にやったか」であって瞬間ではないので `date` 型が正しい。`timestamptz` にすると「JST 7/11 00:30 = UTC 7/10 15:30」のように**格納・取得の経路次第で日付がズレる**（詳細は計画のリスク欄と、学習トピック13）。一方 `slack_posted_at` や `created_at` は瞬間なので `timestamptz`。

## このプロジェクトでの具体例

Phase 3 で作るマイグレーション SQL の全体像（計画のテーブル定義を SQL に起こしたもの）:

```sql
create table training_records (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id),
  date date not null,
  activity text not null,
  duration text not null,
  comment text,
  location text,
  monthly_count int not null,
  share_to_slack boolean not null default false,
  slack_posted_at timestamptz,
  created_at timestamptz not null default now()
);

alter table training_records enable row level security;

create policy "owner can select" on training_records
  for select using (user_id = auth.uid());

create policy "owner can insert" on training_records
  for insert with check (user_id = auth.uid());

create policy "owner can update" on training_records
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "owner can delete" on training_records
  for delete using (user_id = auth.uid());

-- 一覧は常に「新しい順」なので複合インデックス
create index training_records_user_date_idx
  on training_records (user_id, date desc);
```

対応関係:

- `id uuid` … Hive 実装と同じく**アプリ側で uuid v4 を採番**して upsert する（`TrainingRepository.saveRecord` の `_uuid.v4()` と同じ挙動を保つ）
- `activity` / `duration` は既存モデルどおり自由入力の text
- `monthly_count` … Dart の `monthlyCount` が snake_case になる（マッピングは `toSupabaseJson()` が担当）
- Edge Function が使う **service role key は RLS を素通りする**。`slack_posted_at` の書き戻しが owner-only ポリシーに阻まれないのはこのため

## 最小演習

1. Supabase ダッシュボード → SQL Editor で上の SQL を実行（本番プロジェクト作成前なら使い捨てプロジェクトで可）
2. 同じ SQL Editor で `select * from training_records;` → **管理者権限（postgres ロール）なので RLS を素通りして**空テーブルが見える
3. SQL Editor のロール切替（画面上部の「postgres」ドロップダウン）で `anon` に切り替えて同じ SELECT → 0行（エラーではなく「見えない」）になることを確認
4. `insert into training_records (id, date, activity, duration, monthly_count) values (gen_random_uuid(), '2026-07-11', 'ランニング', '30分', 5);` を anon ロールで実行 → `WITH CHECK` 違反（auth.uid() が NULL）で失敗することを確認

この「エラーではなく0行」「INSERT はポリシー違反エラー」という挙動の違いを体感しておくと、Phase 6 のカットオーバー時のトラブルシュートが楽になる。
