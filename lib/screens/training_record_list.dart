import 'package:flutter/material.dart';
import '../models/training_record.dart';
import '../repositories/training_repository.dart';
import 'training_record_form.dart';

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

  void _showDetailDialog(TrainingRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${record.date.year}/${record.date.month}/${record.date.day}',
        ),
        content: SingleChildScrollView(
          child: Text(record.toSlackMessage()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トレーニング記録'),
      ),
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
                    final dateText =
                        '${record.date.year}/${record.date.month}/${record.date.day}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(record.activity),
                        subtitle: Text('$dateText ・ ${record.duration}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showDetailDialog(record),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const TrainingRecordForm(),
            ),
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
