# 2. Supabase Auth

関連フェーズ: Phase 4（ログイン画面・セッションゲート）、手動セットアップ手順2

## 概念

### 全体像: JWT ベースの認証

Supabase Auth（内部実装は GoTrue）は、ログイン成功時に **JWT（署名付きトークン）** を発行する。以降のリクエストはこの JWT を `Authorization: Bearer <jwt>` ヘッダに付けて送り、PostgREST が署名を検証して「誰か」を確定し、RLS の `auth.uid()` に流し込む（01 参照）。

JWT の中身（ペイロード）は Base64 デコードすれば誰でも読める。重要なクレームは:

- `sub` … ユーザーの UUID（= `auth.uid()` の値）
- `role` … `anon`（未ログイン）/ `authenticated`（ログイン済み）
- `exp` … 有効期限（デフォルト1時間。SDK が refresh token で自動更新する）

### 3種類のキーの役割

| キー | role | RLS | 置き場所 |
|---|---|---|---|
| anon key | `anon` | **適用される** | 公開OK（ビルドに埋め込む） |
| ユーザーの JWT | `authenticated` | **適用される** | SDK がセッションとして管理 |
| service role key | `service_role` | **素通り（全行アクセス）** | サーバーのみ。絶対に公開しない |

**anon key が公開可能な理由**: anon key は「どの Supabase プロジェクトか」を識別するだけのキーで、それ自体に権限はほぼない。anon key で `training_records` を SELECT しても、RLS により 0 行が返るだけ。つまり **セキュリティの実体は RLS であって、anon key の秘匿ではない**。これが計画で「anon key は RLS 前提で公開可」「GitHub *Variables*（Secretsでなく）でよい」としている根拠。

逆に service role key は RLS を無視できるので、Edge Function の中（サーバー側）でのみ使う。`slack_posted_at` の書き戻しがこれ。

### サインアップ無効化と単一ユーザー運用

ダッシュボード → Authentication → Sign In / Up で「Allow new users to sign up」を **OFF** にすると、`signUp` API 自体が拒否される。ユーザーはダッシュボードから手動作成（「Auto Confirm User」にチェックして確認メールを省略）。

これで「email+password のフォームが公開されていても、アカウントを作れるのは管理者だけ」という単一ユーザー構成が成立する。パスワード総当たりには Supabase 側のレート制限がかかる。

### セッション管理と onAuthStateChange

- Flutter Web では、セッション（JWT + refresh token）は **localStorage に永続化**される。ブラウザを閉じてもログイン状態が残る
- SDK は期限切れ前に refresh token で JWT を自動更新する
- `onAuthStateChange` は `signedIn` / `signedOut` / `tokenRefreshed` などのイベントを流す **Stream**。Phase 4 の `auth_gate.dart` はこれを `StreamBuilder` で聴いて Login 画面 ⇔ List 画面を切り替える

## このプロジェクトでの具体例

Phase 4 のテストシーム `AuthService` と、その Supabase 実装のイメージ:

```dart
// lib/services/auth_service.dart
abstract interface class AuthService {
  bool get isSignedIn;
  Stream<bool> get signedInChanges;
  Future<void> signInWithPassword(String email, String password);
  Future<void> signOut();
}
```

```dart
// SupabaseAuthService（実装側の骨子）
class SupabaseAuthService implements AuthService {
  final GoTrueClient _auth; // Supabase.instance.client.auth

  SupabaseAuthService(this._auth);

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  Stream<bool> get signedInChanges =>
      _auth.onAuthStateChange.map((_) => isSignedIn);

  @override
  Future<void> signInWithPassword(String email, String password) async {
    await _auth.signInWithPassword(email: email, password: password);
    // 失敗時は AuthException が投げられる（メッセージをログイン画面で表示）
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
```

interface を挟むことで、widget テストでは `MockAuthService`（mocktail）を使い、Supabase 初期化なしで Login ⇔ List の切替をテストできる。

## 最小演習

1. 使い捨てプロジェクトで Authentication → Users → 「Add user」→ email/password 入力、**Auto Confirm** で作成
2. curl でパスワードログインを叩き、JWT を取得:

   ```bash
   curl -s -X POST "https://<project-ref>.supabase.co/auth/v1/token?grant_type=password" \
     -H "apikey: <anon-key>" \
     -H "Content-Type: application/json" \
     -d '{"email":"you@example.com","password":"..."}'
   ```

3. レスポンスの `access_token`（JWT）の2番目のドット区切り部分を Base64 デコードして `sub` と `role: "authenticated"` を確認:

   ```bash
   echo '<JWTの2つ目のセグメント>' | base64 -d
   ```

4. サインアップ無効化を ON にしてから `/auth/v1/signup` を叩き、拒否されることを確認

「JWT はただの署名付き JSON で、中身の `sub` が RLS の `auth.uid()` になる」という一本の線が見えれば、この項は完了。
