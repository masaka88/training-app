import 'package:supabase_flutter/supabase_flutter.dart';

/// 認証操作のインターフェース。
///
/// Supabaseの型を画面側に漏らさないための薄い抽象化で、
/// テストではmocktailによるモックに差し替える。
abstract interface class AuthService {
  /// 現在ログイン中かどうか
  bool get isSignedIn;

  /// ログイン状態の変化を通知するストリーム
  Stream<bool> get signedInChanges;

  /// email+passwordでログインする。失敗時は例外を投げる。
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// ログアウトする
  Future<void> signOut();
}

/// Supabase Authを使用した[AuthService]の実装
class SupabaseAuthService implements AuthService {
  final GoTrueClient _auth;

  SupabaseAuthService(this._auth);

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  Stream<bool> get signedInChanges =>
      _auth.onAuthStateChange.map((state) => state.session != null);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
