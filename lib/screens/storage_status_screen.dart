import 'package:flutter/material.dart';
import '../utils/persistent_storage.dart';

class StorageStatusScreen extends StatefulWidget {
  const StorageStatusScreen({super.key});

  @override
  State<StorageStatusScreen> createState() => _StorageStatusScreenState();
}

class _StorageStatusScreenState extends State<StorageStatusScreen> {
  bool _loading = true;
  bool _persisted = false;
  StorageEstimate _estimate = const StorageEstimate();
  String? _lastActionMessage;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final persisted = await PersistentStorage.isPersisted();
    final estimate = await PersistentStorage.estimate();
    if (!mounted) return;
    setState(() {
      _persisted = persisted;
      _estimate = estimate;
      _loading = false;
    });
  }

  Future<void> _requestPersist() async {
    final granted = await PersistentStorage.requestPersist();
    if (!mounted) return;
    setState(() {
      _lastActionMessage = granted
          ? '永続ストレージが許可されました'
          : '永続ストレージは許可されませんでした（ブラウザが未対応か拒否されました）';
    });
    await _refresh();
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '不明';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final supported = PersistentStorage.isSupported;
    return Scaffold(
      appBar: AppBar(title: const Text('ストレージの状態')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusCard(
                  icon: _persisted ? Icons.lock : Icons.lock_open,
                  iconColor: _persisted ? Colors.green : Colors.orange,
                  title: '永続化状態',
                  value: _persisted ? '永続化済み' : '一時的（退避対象）',
                  description: _persisted
                      ? 'ブラウザはこのサイトのデータを容量逼迫時にも削除しません。'
                      : 'ブラウザは容量逼迫時や一定期間の未訪問でデータを削除する可能性があります。',
                ),
                const SizedBox(height: 12),
                _StatusCard(
                  icon: Icons.storage,
                  iconColor: Colors.blueAccent,
                  title: '使用量 / 割り当て',
                  value:
                      '${_formatBytes(_estimate.usage)} / ${_formatBytes(_estimate.quota)}',
                  description: 'ブラウザがこのオリジンに割り当てている容量と現在の使用量です。',
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: supported && !_persisted ? _requestPersist : null,
                  icon: const Icon(Icons.verified_user),
                  label: Text(
                    _persisted ? '既に永続化されています' : '永続ストレージをリクエスト',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再読み込み'),
                ),
                if (_lastActionMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _lastActionMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 24),
                if (!supported)
                  const Text(
                    'このプラットフォームでは navigator.storage API が使えません。'
                    'Flutter Web で実行してください。',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  const Text(
                    '注意: Safari はこの API を受け付けても ITP により 7 日間の未操作でデータを削除します。'
                    '根本的な対策はサーバ側保存への移行です。',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
