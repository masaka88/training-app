/// Supabaseの接続情報。ビルド時に `--dart-define` で注入する。
///
/// publishable keyはRLS（Row Level Security）を前提とした公開可能なキーのため、
/// クライアントに埋め込んでよい。値の設定方法は supabase/README.md を参照。
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);
