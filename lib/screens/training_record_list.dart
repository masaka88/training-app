import 'package:flutter/material.dart';
import '../models/training_record.dart';
import '../repositories/repository_provider.dart';
import '../repositories/training_repository.dart';
import '../services/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/local_data_migrator.dart';
import '../services/migrator_provider.dart';
import 'training_record_form.dart';
import 'training_record_card.dart';
import 'training_record_detail_dialog.dart';
import 'detail_dialog_result.dart';

class TrainingRecordList extends StatefulWidget {
  final TrainingRepository? repositoryOverride;
  final AuthService? authServiceOverride;
  final LocalDataMigrator? migratorOverride;

  const TrainingRecordList({
    super.key,
    this.repositoryOverride,
    this.authServiceOverride,
    this.migratorOverride,
  });

  @override
  State<TrainingRecordList> createState() => _TrainingRecordListState();
}

class _TrainingRecordListState extends State<TrainingRecordList> {
  late final TrainingRepository _repository =
      widget.repositoryOverride ?? repository;
  late final LocalDataMigrator? _migrator =
      widget.migratorOverride ?? localDataMigrator;
  List<TrainingRecord> _records = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _maybeMigrateLocalData();
  }

  /// ローカルHiveに未移行の記録が残っていれば、確認のうえSupabaseへ移行する
  Future<void> _maybeMigrateLocalData() async {
    final migrator = _migrator;
    if (migrator == null || !await migrator.shouldMigrate()) {
      return;
    }
    if (!mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データ移行'),
        content: Text('この端末に保存されている${migrator.localCount}件の記録をサーバーへ移行しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('あとで'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移行する'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      final migrated = await migrator.migrate();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$migrated件の記録を移行しました'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRecords();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('移行に失敗しました。次回起動時に再試行できます。'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final records = await _repository.getAllRecords();
      if (!mounted) {
        return;
      }
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トレーニング記録'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () async {
              final auth = widget.authServiceOverride ?? authService;
              await auth.signOut();
              // ログアウト後の画面遷移はAuthGateがログイン状態の変化を検知して行う
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '記録の読み込みに失敗しました',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadRecords,
                    child: const Text('再試行'),
                  ),
                ],
              ),
            )
          : _records.isEmpty
          ? const Center(
              child: Text(
                '記録がありません',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                return TrainingRecordCard(
                  record: record,
                  onTap: () async {
                    final dialogResult = await showRecordDetailDialog(
                      context,
                      record,
                    );
                    if (dialogResult == DetailDialogResult.delete) {
                      _loadRecords();
                    } else if (dialogResult == DetailDialogResult.edit &&
                        context.mounted) {
                      final formResult = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TrainingRecordForm(record: record),
                        ),
                      );
                      if (formResult == true) {
                        _loadRecords();
                      }
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const TrainingRecordForm()),
          );
          if (result == true) {
            _loadRecords();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
