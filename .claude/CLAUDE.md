# CLAUDE.md

Claude Code 向けのプロジェクト固有ルール。一般的な Flutter/Dart の知識や `pubspec.yaml`・ディレクトリ構造から読み取れる事項は記載しない。

## Communication Language

ユーザーへの応答は日本語で行う。

## Development Environment

Flutter/Dart コマンドは devcontainer 内で実行する。ローカルホストから実行する場合は以下のプレフィックスを付ける：

```
devcontainer exec --workspace-folder <プロジェクトルートの絶対パス> <command>
```

Web 起動時は `flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0` を使い、ブラウザで `http://localhost:3000` にアクセスする。

## Testing

- フレームワーク: `flutter_test` + `mocktail`（コード生成不要）
- **Widget Test**: `pumpAndSettle` ではなく `pump` を使う（Hive の非同期操作でハングするため）
- **Widget Test**: 未解決の Future には `Completer` を使う（`Future.delayed` はタイマーエラーになる）
- **Repository Test**: `setUp` で `Hive.init(tempDir)` + Adapter 登録、`tearDown` で `box.close()` → `Hive.close()` → tempDir 削除

## Code Formatting

Dart コードは最初から `dart format` 準拠のスタイルで書く。後から `dart format` を実行してフォーマット差分が発生しないようにし、差分にはロジック変更のみが含まれるようにする。

## Git Workflow

- コミットは論理単位で分割する（設定変更、コード変更、フォーマット、CI、ドキュメントは別コミット）
- テストは対応する実装と同じコミットにまとめてよい
- Conventional Commits 形式でメッセージを記述する
