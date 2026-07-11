# 学習ドキュメント: Supabase 移行の要素技術

「Supabase 移行 + DB更新駆動 Slack 連携 実装計画」を実行する前に学ぶ要素技術のまとめ。
各ドキュメントは「概念の解説（なぜそうなっているか）」「このプロジェクトでの具体例」「最小演習」の3部構成。

| # | ドキュメント | 関連フェーズ |
|---|---|---|
| 1 | [Postgres + RLS](01-postgres-rls.md) | Phase 3（SQL マイグレーション） |
| 2 | [Supabase Auth](02-supabase-auth.md) | Phase 4（認証） |
| 3 | [Edge Functions (Deno/TS)](03-edge-functions.md) | Phase 3（post-to-slack） |
| 4 | [Database Webhooks](04-database-webhooks.md) | Phase 3（DB更新駆動の要） |
| 5 | [Supabase CLI](05-supabase-cli.md) | 手動セットアップ全般 |
| 7 | [無料枠と keep-alive](07-keepalive.md) | Phase 7 |
| 9 | [supabase_flutter SDK](09-supabase-flutter.md) | Phase 4〜5（アプリ側実装） |

読む順番は表の上から。1〜4 でバックエンドの全体像（データが保存されてから Slack に届くまで）がつながり、5 と 7 で運用、9 でアプリ側の実装に降りる。
