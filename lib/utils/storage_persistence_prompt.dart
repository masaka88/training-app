import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'persistent_storage.dart';

/// ブラウザによるローカルデータの自動退避を抑制するため、
/// 適切なタイミングで永続ストレージのリクエストをユーザーに確認する。
class StoragePersistencePrompt {
  StoragePersistencePrompt(this._settings);

  final Box<bool> _settings;

  static const _askedKey = 'storage_persistence_asked';

  bool get hasBeenAsked => _settings.get(_askedKey, defaultValue: false)!;

  /// 以下の条件をすべて満たすときのみダイアログを出す。
  /// - navigator.storage が使えるプラットフォーム（実質 Flutter Web）
  /// - まだ確認していない
  /// - 現時点で永続化されていない
  Future<void> maybePrompt(BuildContext context) async {
    if (!PersistentStorage.isSupported) return;
    if (hasBeenAsked) return;
    if (await PersistentStorage.isPersisted()) {
      await _settings.put(_askedKey, true);
      return;
    }
    if (!context.mounted) return;

    final agreed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('記録を長期保存しますか？'),
        content: const Text(
          '記録はブラウザ内に保存されています。容量不足や長期間アクセスがないと'
          'ブラウザが自動で削除する場合があります。\n\n'
          '長期保存を有効にすると、この可能性を減らせます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('あとで'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('長期保存する'),
          ),
        ],
      ),
    );

    await _settings.put(_askedKey, true);
    if (agreed == true) {
      await PersistentStorage.requestPersist();
    }
  }
}
