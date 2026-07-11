# 7. 無料枠と keep-alive

関連フェーズ: Phase 7（`.github/workflows/supabase-keepalive.yml`）

## 概念

### Free プランの一時停止（pause）の仕組み

Supabase Free プランのプロジェクトは、**約1週間アクティビティがないと自動的に一時停止（pause）** される。ここでの「アクティビティ」は API リクエスト（REST / Auth / Functions 等）や DB への接続を指す。

一時停止されると:

- REST API がエラーを返す → アプリは記録の読み書きができなくなる
- データは消えない（restore すれば戻る）が、**復帰はダッシュボードから手動**
- つまり「数日サボって久しぶりに記録しようとしたらアプリが動かない」が起こり得る

トレーニング記録アプリは性質上、毎日使うとは限らないため、この1週間ルールに現実的に引っかかる。対策が **定期的に無害な API リクエストを投げて「アクティブ」扱いを維持する** keep-alive。

### なぜ「anon key で SELECT 1件」が安全な ping なのか

keep-alive のリクエストは:

```
GET /rest/v1/training_records?select=id&limit=1
apikey: <anon key>
```

- anon key はログインしていないので、RLS（01 参照）により **結果は常に `[]`（空配列）**。データは1バイトも漏れない
- 読み取りなので何も変更しない。Database Webhook（04）も発火しない（発火条件は INSERT/UPDATE）
- それでも PostgREST へのリクエストとしてカウントされ、アクティビティ扱いになる
- 使うのは公開可能な anon key だけなので、GitHub **Variables** に置ける（Secrets 不要）。deploy.yml と同じ変数を共用できる

「認証なしで叩けて、必ず空が返り、それでも活動実績になる」— RLS の副産物として理想的な ping になっている。

### cron 頻度の設計

計画では `0 21 * * 2,5`（週2回）。GitHub Actions の cron は **UTC** なので、21:00 UTC 火・金 = **JST 水・土の朝6時**。

- 1週間の猶予に対して週2回 = 最大間隔3〜4日で、1回失敗しても次で間に合う余裕がある
- GitHub Actions の schedule は**正確な時刻実行が保証されず、混雑時は遅延・スキップされ得る**。「毎週ぴったり」ではなく「週2回ならどれか動くだろう」という冗長性込みの設計
- `workflow_dispatch` を併記して手動実行もできるようにする（pause 復帰直後の動作確認などに使う）

## このプロジェクトでの具体例

Phase 7 で作る workflow の全体像:

```yaml
# .github/workflows/supabase-keepalive.yml
name: Supabase keep-alive

on:
  schedule:
    - cron: "0 21 * * 2,5" # UTC火金21時 = JST水土朝6時
  workflow_dispatch:

jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - name: Ping Supabase REST API
        run: |
          curl --fail-with-body -sS \
            "${{ vars.SUPABASE_URL }}/rest/v1/training_records?select=id&limit=1" \
            -H "apikey: ${{ vars.SUPABASE_ANON_KEY }}" \
            -H "Authorization: Bearer ${{ vars.SUPABASE_ANON_KEY }}"
```

- `vars.SUPABASE_URL` / `vars.SUPABASE_ANON_KEY` は手動セットアップ手順7で登録する GitHub Variables。deploy.yml の `--dart-define` 注入と**同じ変数を共用**する（二重管理しない）
- `--fail-with-body` により、pause 中などでエラーが返ればジョブが**失敗として可視化**される（GitHub から失敗通知が来る = pause の検知装置も兼ねる）
- checkout 不要（リポジトリのコードを使わない）なので1ステップで完結

## 最小演習

1. 使い捨てプロジェクトに対して手元で ping を打ち、`[]` が返ることを確認:

   ```bash
   curl -i "https://<ref>.supabase.co/rest/v1/training_records?select=id&limit=1" \
     -H "apikey: <anon-key>" -H "Authorization: Bearer <anon-key>"
   ```

2. わざと存在しないテーブル名にして 404 系エラーを見る（keep-alive が「失敗を検知できる」ことの確認）
3. GitHub の適当なリポジトリに上記 workflow を置き、Actions タブから `workflow_dispatch` で手動実行 → ログで `[]` を確認

計画どおり Phase 7 は Phase 3（テーブルの存在）にしか依存しないので、カットオーバー前でも先行導入できる。
