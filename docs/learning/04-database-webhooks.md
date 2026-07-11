# 4. Database Webhooks

関連フェーズ: Phase 3（DB更新駆動 Slack 連携の要）、手動セットアップ手順5

## 概念

### 仕組み: トリガー + 非同期HTTP

Database Webhook は「テーブルの INSERT / UPDATE / DELETE を検知して、指定 URL に HTTP リクエストを送る」機能。実体は Postgres の **AFTER トリガー** が `pg_net` 拡張（非同期HTTPクライアント）にリクエストを積むだけの薄い仕組み。

重要な性質:

- **非同期**: HTTP 送信はトランザクションのコミット後にバックグラウンドで行われる。アプリの `saveRecord` は Webhook の成否を待たないし、知らない
- **fire-and-forget**: 送信失敗時の自動リトライは保証されない。「確実に一度だけ」ではなく「たぶん送られる」程度の保証
- だからこそ受け側（Edge Function）に **冪等なガード**が必要で、失敗時の回復手段が「レコードを touch して再送」になる

この「アプリは記録を保存するだけで Slack を一切知らない」疎結合が、計画の中心設計。アプリのコードには Slack の文字が一切現れない。

### payload の構造

Edge Function が受け取る JSON:

```json
{
  "type": "UPDATE",
  "table": "training_records",
  "schema": "public",
  "record": {
    "id": "0b9f...",
    "user_id": "a1c2...",
    "date": "2026-07-11",
    "activity": "ランニング",
    "duration": "30分",
    "comment": null,
    "location": null,
    "monthly_count": 5,
    "share_to_slack": true,
    "slack_posted_at": null,
    "created_at": "2026-07-11T09:15:00.123456+00:00"
  },
  "old_record": { "...UPDATE時のみ、変更前の行..." }
}
```

- `record` が変更後の行（INSERT では新しい行）。**カラム名は snake_case、`date` は `"yyyy-MM-dd"` 文字列**で届く
- `old_record` は UPDATE のときだけ入る（INSERT では null）

post-to-slack のガードが `record.share_to_slack && record.slack_posted_at === null` だけを見て `old_record` を使わないのは、判定を「行の現在の状態」だけで完結させるため。イベントの種類（INSERT か UPDATE か）に依存しない = 冪等。

### x-webhook-secret による検証

`verify_jwt = false` の関数はURLを知っていれば誰でも叩ける（03 参照）。そこで Webhook 作成時に **HTTP ヘッダ `x-webhook-secret: <ランダム値>`** を付与する設定を入れ、関数側で照合する。シークレットは:

- Webhook 側: ダッシュボードの Webhook 設定画面で入力（**SQLマイグレーションに埋めない** — マイグレーションは git に入るため）
- 関数側: `supabase secrets set WEBHOOK_SECRET=...`

の2箇所に同じ値を置く。

### 再発火とループ防止

post-to-slack は最後に `slack_posted_at` を UPDATE で書き戻す。この UPDATE も Webhook の発火条件（INSERT + UPDATE）に合致するので、**関数がもう一度呼ばれる**。流れ:

```
アプリが share_to_slack=true で保存
  → Webhook発火(1回目): ガード通過 → Slack投稿 → posted_at 書き戻し
    → Webhook発火(2回目): slack_posted_at ≠ null なのでガードで skip
      → UPDATE しないので3回目は発生しない。ここで収束
```

「書き戻しが再発火する」こと自体は止められないが、**ガードが状態収束点になっている**ので無限ループにならない。この構造は「再送 = `slack_posted_at` を null に戻す UPDATE」にもそのまま効く（null に戻す UPDATE が発火 → ガード通過 → 投稿 → 書き戻し → skip で収束）。

## このプロジェクトでの具体例

手動セットアップ手順5の設定内容:

| 設定項目 | 値 |
|---|---|
| Table | `public.training_records` |
| Events | INSERT, UPDATE（DELETE は不要 — 消した記録は投稿しない） |
| Type | Supabase Edge Function → `post-to-slack` |
| HTTP Headers | `x-webhook-secret: <secrets set した値と同じもの>` |

アプリ側から見た一連の動き（Phase 6 の手動検証項目と対応）:

- チェックON で保存 → 投稿され、バッジ（`slack_posted_at`）が付く
- その記録を編集して保存（UPDATE）→ `slack_posted_at` が残っているので**再投稿されない**
- 詳細ダイアログの「Slackへ再送」→ `resendToSlack(id)` が `slack_posted_at` を null に → 再投稿される
- チェックOFF のまま保存 → `share_to_slack = false` なので何も起きない

## 最小演習

1. <https://webhook.site> で使い捨ての受信URLを取得
2. 使い捨て Supabase プロジェクトで適当なテーブルを作り、Database → Webhooks で INSERT + UPDATE を webhook.site のURLに送る Webhook を作成（ヘッダ `x-webhook-secret: test` も付与）
3. Table Editor から行を INSERT → webhook.site に届いた JSON で `type` / `record` / ヘッダを実際に確認
4. その行を UPDATE → `old_record` が入ることを確認

payload を一度目で見ておくと、Edge Function の `record.share_to_slack` などのフィールド参照を迷いなく書ける。
