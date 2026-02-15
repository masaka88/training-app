# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application project named `training_app`. It's a minimal Flutter project initialized with a basic "Hello World" app structure.

## Communication Language

When communicating with users, respond in Japanese.

## Architecture and Structure

- **Framework**: Flutter 3.9.0+ with Dart
- **Main Entry Point**: `lib/main.dart` - Contains the main app with a simple MaterialApp showing "Hello World"
- **Dependencies**: Uses Material Design components (`uses-material-design: true`)
- **Linting**: Uses `flutter_lints` package with standard Flutter linting rules
- **Platforms**: Supports web and macOS (evidenced by `/web` and `/macos` directories)

## Development Commands

Flutter/Dartコマンドはdevcontainer内で実行すること。ローカルホストからは以下のプレフィックスを付けて実行する：

```
devcontainer exec --workspace-folder <プロジェクトルートの絶対パス> <command>
```

例：
- `devcontainer exec --workspace-folder <プロジェクトルートの絶対パス> flutter pub get`
- `devcontainer exec --workspace-folder <プロジェクトルートの絶対パス> flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0`

### Essential Commands

- **Install dependencies**: `flutter pub get`
- **Run the app (web)**: `flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0` → ブラウザで http://localhost:3000 にアクセス
- **Build for release**: `flutter build apk` (Android) or `flutter build ios` (iOS)
- **Run tests**: `flutter test`
- **Run tests (specific file)**: `flutter test test/models/training_record_test.dart`
- **Analyze code**: `flutter analyze`
- **Format code**: `dart format .`

### Development Workflow

- **Hot reload**: Available when running `flutter run` in debug mode
- **Clean build cache**: `flutter clean` then `flutter pub get`
- **Generate platform-specific code**: `flutter create --platforms android,ios .` (if needed)

## Configuration Files

- `pubspec.yaml`: Project configuration and dependencies
- `analysis_options.yaml`: Includes Flutter linting rules from `package:flutter_lints/flutter.yaml`
- `lib/main.dart`: Single-file app with `MainApp` StatelessWidget

## Testing

テストフレームワーク: `flutter_test` + `mocktail`（コード生成不要のモックライブラリ）

### テスト構成

```
test/
├── models/
│   └── training_record_test.dart      # Model Unit Test
├── repositories/
│   └── training_repository_test.dart  # Repository Unit Test (Real Hive + tempDir)
├── utils/
│   └── display_helpers_test.dart      # ロジック関数 Unit Test
└── screens/
    └── training_record_list_test.dart # Widget Test (mocktail)
```

### テスト実行

```bash
# 全テスト実行
flutter test

# 特定ファイルのみ
flutter test test/models/training_record_test.dart

# 特定グループのみ（--plain-name で部分一致）
flutter test --plain-name 'toSlackMessage'
```

### テスト作成時の注意

- **Widget Test**: `pumpAndSettle` ではなく `pump` を使う（Hive非同期操作でハングする）
- **Widget Test**: 未解決のFutureには `Completer` を使う（`Future.delayed` はタイマーエラーになる）
- **Repository Test**: `setUp` で `Hive.init(tempDir)` + Adapter登録、`tearDown` で `box.close()` + `Hive.close()` + tempDir削除

## Code Formatting

Dartコードは最初から `dart format` 準拠のスタイルで書くこと。後から `dart format` を実行してフォーマット差分が発生しないようにする。これにより、差分にはロジック変更のみが含まれ、レビューしやすくなる。

## Git Workflow

PRの作成を依頼された場合は、`/create-pr` スキルが利用可能であれば必ず使用すること。

`/create-pr` スキルが利用できない場合は、以下のルールに従う:

- コミットは論理単位で分割する（設定変更、コード変更、フォーマット、CI、ドキュメントは別コミット）
- テストは対応する実装と同じコミットにまとめてよい
- Conventional Commits形式でメッセージを記述する

## Development Notes

- Project uses standard Flutter project structure
- Material Design is enabled for UI components
- Currently supports web and macOS platforms out of the box
