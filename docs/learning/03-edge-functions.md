# 3. Edge Functions（Deno / TypeScript）

関連フェーズ: Phase 3（`supabase/functions/post-to-slack/index.ts`）

## 概念

### Edge Function とは

Supabase がホストするサーバーレス関数。**Deno ランタイム**上で TypeScript がそのまま動く（tsconfig や webpack 等のビルド設定が不要）。このプロジェクトでの役割はただ一つ: **秘密（Slack Webhook URL）を持てる場所を用意すること**。Flutter Web のビルド成果物は誰でも中身を見られるので、Webhook URL をアプリに埋め込むことはできない。Edge Function ならサーバー側の secrets として保持できる。

### Deno の特徴（Node.js との違いで押さえる）

- `import` は URL または `npm:` 指定子で直接書く（`package.json` / `node_modules` なし）
- Web 標準 API がそのまま使える: `fetch`, `Request`, `Response`, `crypto`
- エントリポイントは `Deno.serve(handler)`。handler は `(req: Request) => Response | Promise<Response>`
- 環境変数（secrets）は `Deno.env.get('NAME')`

```ts
Deno.serve(async (req: Request) => {
  const body = await req.json();
  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

### verify_jwt = false の意味

デフォルトでは、Supabase のゲートウェイが Edge Function の手前で「`Authorization` ヘッダに有効な JWT（anon または authenticated）があるか」を検査し、なければ 401 を返す。

ところが post-to-slack の呼び出し元は **Database Webhook（DB内部からのHTTP呼び出し）** であり、ユーザーの JWT を持たない。そこで `supabase/config.toml` で:

```toml
[functions.post-to-slack]
verify_jwt = false
```

とし、JWT 検査を外す。**代わりの認証が `x-webhook-secret` ヘッダの自前検証**（04 参照）。「verify_jwt を外す = 認証を無くす」ではなく「認証方式を JWT から共有シークレットに差し替える」と理解する。

### secrets の設定と参照

```bash
supabase secrets set SLACK_WEBHOOK_URL=https://hooks.slack.com/services/... WEBHOOK_SECRET=<ランダム値>
```

関数内からは `Deno.env.get('SLACK_WEBHOOK_URL')`。なお `SUPABASE_URL` と `SUPABASE_SERVICE_ROLE_KEY` は**予約済み secrets として自動注入される**ので、自分で set しなくても `Deno.env.get` で取れる（書き戻し UPDATE に使う）。

## このプロジェクトでの具体例

`post-to-slack/index.ts` の骨子（計画の処理順 1〜4 に対応）:

```ts
Deno.serve(async (req: Request) => {
  // 1. 共有シークレット検証（不一致は403）
  if (req.headers.get("x-webhook-secret") !== Deno.env.get("WEBHOOK_SECRET")) {
    return new Response("forbidden", { status: 403 });
  }

  // 2. ガード: share_to_slack && slack_posted_at IS NULL 以外は skip
  //    → 自分自身の書き戻しUPDATEで再発火してもここで止まる（ループ防止）
  const { record } = await req.json(); // Database Webhook の payload（04参照）
  if (!record.share_to_slack || record.slack_posted_at !== null) {
    return new Response("skipped", { status: 200 });
  }

  // 3. テンプレ整形（Dart側 TrainingRecord.toSlackMessage() の TS 移植。
  //    相互参照コメントで二重管理を明示する）
  const text = toSlackMessage(record);

  // 4a. Slack Incoming Webhook へ POST
  const res = await fetch(Deno.env.get("SLACK_WEBHOOK_URL")!, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text }),
  });
  if (!res.ok) {
    // posted_at は null のままなので、レコードを touch すれば再送される
    return new Response("slack error", { status: 500 });
  }

  // 4b. service role で slack_posted_at を書き戻し（RLS素通り）
  await fetch(
    `${Deno.env.get("SUPABASE_URL")}/rest/v1/training_records?id=eq.${record.id}`,
    {
      method: "PATCH",
      headers: {
        apikey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
        Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ slack_posted_at: new Date().toISOString() }),
    },
  );

  return new Response("posted", { status: 200 });
});
```

ポイント:

- **POST 成功 → 書き戻し** の順なので、Slack 送信に失敗しても `slack_posted_at` は null のまま = 再送（touch）で自然リトライできる
- `toSlackMessage()` は `lib/models/training_record.dart` の同名メソッド（`*日付*` 見出し + 任意項目のスキップ + `N月の運動回数`）を忠実に移植する

## 最小演習

1. ローカルで関数を作る（Supabase CLI が必要。05 参照）:

   ```bash
   supabase functions new hello
   supabase functions serve hello
   ```

2. curl で叩く:

   ```bash
   curl -s http://localhost:54321/functions/v1/hello -d '{"name":"training"}'
   ```

3. `index.ts` に `if (req.headers.get("x-webhook-secret") !== "test") return new Response("forbidden", { status: 403 });` を足し、ヘッダあり/なしで 200/403 が切り替わることを確認

   ```bash
   curl -i http://localhost:54321/functions/v1/hello -d '{}'                       # 403
   curl -i -H "x-webhook-secret: test" http://localhost:54321/functions/v1/hello -d '{}'  # 200
   ```

これは Phase 3 の検証項目「curl で模擬 payload → Slack 投稿 / secret なし 403」の予行演習そのもの。
