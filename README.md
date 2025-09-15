# training_app

トレーニングの記録を行うためのアプリ。

Slackに記録することを前提としてその支援を行う。

## 現時点での機能

- トレーニング内容の入力（何をしたか、時間、場所など）
- Slack投稿用フォーマットでのメッセージ生成

## 開発環境

- Flutter 3.9.0+
- Dart SDK

## セットアップ

```bash
# 依存関係のインストール
flutter pub get

# アプリの実行
flutter run
```

## その他のコマンド

```bash
# コード解析
flutter analyze

# コードフォーマット
dart format .

# クリーンビルド
flutter clean && flutter pub get
```
