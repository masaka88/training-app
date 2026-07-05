import 'package:flutter/material.dart';
import '../models/training_record.dart';
import '../repositories/repository_provider.dart';
import '../repositories/training_repository.dart';
import '../utils/persistent_storage.dart';
import 'storage_status_screen.dart';
import 'training_record_form.dart';
import 'training_record_card.dart';
import 'training_record_detail_dialog.dart';
import 'detail_dialog_result.dart';

class TrainingRecordList extends StatefulWidget {
  final TrainingRepository? repositoryOverride;

  const TrainingRecordList({super.key, this.repositoryOverride});

  @override
  State<TrainingRecordList> createState() => _TrainingRecordListState();
}

class _TrainingRecordListState extends State<TrainingRecordList> {
  late final TrainingRepository _repository =
      widget.repositoryOverride ?? repository;
  List<TrainingRecord> _records = [];
  bool _isLoading = true;
  bool _storageAtRisk = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _repository.getAllRecords();
    final atRisk =
        records.isNotEmpty &&
        PersistentStorage.isSupported &&
        !(await PersistentStorage.isPersisted());
    if (!mounted) return;
    setState(() {
      _records = records;
      _isLoading = false;
      _storageAtRisk = atRisk;
    });
  }

  Future<void> _openStorageStatus() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StorageStatusScreen()),
    );
    if (mounted) _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トレーニング記録'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'storage') _openStorageStatus();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'storage',
                child: Text('ストレージの状態'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_storageAtRisk)
                  _StorageAtRiskBanner(onTap: _openStorageStatus),
                Expanded(
                  child: _records.isEmpty
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
                                final dialogResult =
                                    await showRecordDetailDialog(
                                      context,
                                      record,
                                    );
                                if (dialogResult == DetailDialogResult.delete) {
                                  _loadRecords();
                                } else if (dialogResult ==
                                        DetailDialogResult.edit &&
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
                ),
              ],
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

class _StorageAtRiskBanner extends StatelessWidget {
  const _StorageAtRiskBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.amber.shade100,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '記録がブラウザに一時保存されています。長期保存を有効にすると安全です。',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
