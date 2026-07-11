# Supabase セットアップ手順

アプリの永続化バックエンド（Postgres + Auth）のセットアップ手順。
コードの変更だけでは完結しない、Supabase ダッシュボード等での手動作業をまとめる。

## 1. プロジェクト作成

1. [Supabase](https://supabase.com/) にサインアップし、新規プロジェクトを作成する
   - プラン: Free
   - リージョン: Northeast Asia (Tokyo) 推奨
2. プロジェクトの `Project URL` と `Publishable key` を控える（Settings → API Keys）

## 2. 認証設定（単一ユーザー運用）

1. Authentication → Sign In / Providers → Email を有効にする
2. **「Allow new users to sign up」を OFF にする**（サインアップ無効化）
3. Authentication → Users → Add user で利用者を1件作成する
   - email + password を設定し、Auto Confirm を有効にする

## 3. スキーマ適用

[Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started) で
`supabase/migrations/` を適用する:

```sh
supabase login
supabase link --project-ref <プロジェクトref>
supabase db push
```

適用後、Table Editor に `training_records` テーブルが作成されていることを確認する。

## 4. GitHub リポジトリの Variables 設定

GitHub Pages へのデプロイビルドに Supabase の接続情報を注入するため、
リポジトリの Settings → Secrets and variables → Actions → **Variables** に以下を追加する:

| Name | Value |
| ------------------- | ---------------------------- |
| `SUPABASE_URL` | プロジェクトの Project URL |
| `SUPABASE_PUBLISHABLE_KEY` | プロジェクトの Publishable key |

Publishable key は RLS（Row Level Security）を前提とした公開可能なキーのため、
Secrets ではなく Variables で管理してよい。

## 5. ローカル開発時の起動

接続情報は `--dart-define` で渡す:

```sh
flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0 \
  --dart-define=SUPABASE_URL=<Project URL> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<Publishable key>
```

## 補足: 無料プランの一時停止対策

Free プランのプロジェクトは約1週間データベースへのアクティビティがないと一時停止される。
`.github/workflows/supabase-keepalive.yml` が定期的に REST API へアクセスして停止を防ぐ
（上記 Variables を共用する）。停止してしまった場合はダッシュボードから手動で再開できる。
