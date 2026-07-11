# 5. Supabase CLI

関連フェーズ: 手動セットアップ手順3〜4、Phase 3 の成果物のデプロイ全般

## 概念

### CLI の役割: 「git 管理できるもの」をリポジトリに置き、コマンドで本番に反映する

ダッシュボード（GUI）でもテーブルや関数は作れるが、それだと**構成がコード管理されず再現不能**になる。CLI を使うと:

- スキーマ = `supabase/migrations/*.sql`（git 管理）
- 関数 = `supabase/functions/<name>/index.ts`（git 管理）
- 関数の設定 = `supabase/config.toml`（git 管理）
- 秘密 = `supabase secrets`（git 管理**しない**）

という分離ができる。計画の Phase 3 が「アプリコード不干渉の inert な成果物」として成立するのは、この `supabase/` ディレクトリ一式が単なるファイルであり、`db push` するまで何も起こさないから。

### 主要コマンドの流れ

```bash
supabase init                  # supabase/ ディレクトリと config.toml を生成（リポジトリに1回だけ）
supabase login                 # アクセストークンで認証（ブラウザが開く）
supabase link --project-ref <ref>   # このリポジトリと本番プロジェクトを紐付け
supabase migration new create_training_records   # 空のマイグレーションSQLを作成
supabase db push               # 未適用のマイグレーションを本番DBに適用
supabase functions deploy post-to-slack          # Edge Function をデプロイ
supabase secrets set SLACK_WEBHOOK_URL=... WEBHOOK_SECRET=...
supabase secrets list          # 値は見えない（ダイジェストのみ）。設定済みかの確認用
```

`<ref>` はダッシュボードの Project Settings → General にある Project ID（URL の `https://<ref>.supabase.co` と同じ）。

### migrations の管理モデル

- ファイル名は `<UTCタイムスタンプ>_<名前>.sql`（例: `20260711091500_create_training_records.sql`）。**タイムスタンプ順に一度だけ適用**される
- 適用済みかどうかは本番DB内の管理テーブル（`supabase_migrations.schema_migrations`）に記録される。`db push` は未適用分だけを流す
- **一度 push したマイグレーションは編集しない**。スキーマを直したくなったら新しいマイグレーションを追加する（追記オンリー）。git の履歴と同じ考え方

### config.toml

プロジェクト設定のうちコード管理すべきものを書く。このプロジェクトで必要なのは1点だけ:

```toml
[functions.post-to-slack]
verify_jwt = false
```

`functions deploy` 時にこの設定が反映され、JWT なしの Database Webhook から呼べるようになる（03 参照）。

### ローカル開発スタック（任意）

`supabase start` で Docker 上にローカルの Postgres + Auth + Functions 一式が立つ（devcontainer 環境なら相性が良い）。`supabase functions serve` は 03 の演習で使ったとおり。本計画は規模が小さいので「本番 push 前の関数の動作確認」だけローカルを使い、DB はリモートに直接 push でも十分。

## このプロジェクトでの具体例

手動セットアップ手順3〜4を CLI コマンドに展開すると:

```bash
# リポジトリルートで（Phase 3 マージ後、supabase/ 一式が存在する状態）
supabase login
supabase link --project-ref <東京リージョンで作ったプロジェクトのref>
supabase db push                          # training_records + RLS + インデックス作成
supabase functions deploy post-to-slack   # config.toml の verify_jwt=false ごと反映
supabase secrets set \
  SLACK_WEBHOOK_URL=https://hooks.slack.com/services/... \
  WEBHOOK_SECRET=$(openssl rand -hex 32)
```

`WEBHOOK_SECRET` に使った値は、ダッシュボードで Database Webhook を作るとき（04 参照）にヘッダへ同じ値を入れる必要があるので控えておく。

リポジトリ構成（Phase 3 完了時点）:

```
supabase/
├── config.toml
├── migrations/
│   └── 20260711091500_create_training_records.sql
├── functions/
│   └── post-to-slack/
│       └── index.ts
└── README.md        # 手動セットアップ手順のチェックリスト
```

## 最小演習

1. CLI をインストール（macOS: `brew install supabase/tap/supabase`、または `npx supabase`）
2. 使い捨てディレクトリで `supabase init` → 生成された `config.toml` を眺める
3. `supabase migration new hello` → `supabase/migrations/` にタイムスタンプ付き空ファイルができることを確認
4. `create table hello (id serial primary key);` と書いて、使い捨てプロジェクトに `link` → `db push` → ダッシュボードの Table Editor で反映を確認
5. もう一度 `db push` して「適用済みなので何もしない」ことを確認（冪等性の体感）
