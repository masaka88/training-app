import 'package:flutter/material.dart';
import '../models/training_record.dart';
import '../repositories/training_repository.dart';
import 'training_record_form.dart';
import 'training_record_card.dart';
import 'training_record_detail_dialog.dart';
import 'detail_dialog_result.dart';

class TrainingRecordList extends StatefulWidget {
  const TrainingRecordList({super.key});

  @override
  State<TrainingRecordList> createState() => _TrainingRecordListState();
}

class _TrainingRecordListState extends State<TrainingRecordList> {
  final _repository = TrainingRepository();
  List<TrainingRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _repository.getAllRecords();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('トレーニング記録')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        final dialogResult = await showRecordDetailDialog(context, record);
                        if (dialogResult == DetailDialogResult.delete) {
                          _loadRecords();
                        } else if (dialogResult == DetailDialogResult.edit && context.mounted) {
                          final formResult = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrainingRecordForm(record: record),
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
