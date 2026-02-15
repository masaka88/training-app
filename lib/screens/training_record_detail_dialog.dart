import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/training_record.dart';
import '../repositories/repository_provider.dart';
import 'detail_dialog_result.dart';

/// 戻り値: DetailDialogResult.edit なら編集要求、DetailDialogResult.delete なら削除済み、null はそれ以外
Future<DetailDialogResult?> showRecordDetailDialog(
  BuildContext context,
  TrainingRecord record,
) {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  return showDialog<DetailDialogResult>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.formattedDate,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  record.activity,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _detailRow(Icons.timer_outlined, '時間', record.duration),
                if (record.location != null)
                  _detailRow(Icons.place_outlined, '場所', record.location!),
                if (record.comment != null)
                  _detailRow(Icons.comment_outlined, 'コメント', record.comment!),
                _detailRow(
                  Icons.fitness_center,
                  '${record.date.month}月の運動回数',
                  '${record.monthlyCount}回',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, DetailDialogResult.edit);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('編集'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmAndDelete(context, record),
                        icon: const Icon(Icons.delete),
                        label: const Text('削除'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final message = record.toSlackMessage();
                      Clipboard.setData(ClipboardData(text: message));
                      Navigator.pop(context);
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Slackメッセージをコピーしました！')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Slackメッセージをコピー'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _confirmAndDelete(
  BuildContext context,
  TrainingRecord record,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('確認'),
      content: const Text('この記録を削除しますか？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('削除', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (confirm == true) {
    await repository.deleteRecord(record.id!);
    if (context.mounted) {
      Navigator.pop(context, DetailDialogResult.delete);
    }
  }
}

Widget _detailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    ),
  );
}
