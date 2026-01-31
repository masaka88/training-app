import 'package:flutter/material.dart';
import '../models/training_record.dart';
import '../repositories/training_repository.dart';

class TrainingRecordForm extends StatefulWidget {
  const TrainingRecordForm({super.key});

  @override
  State<TrainingRecordForm> createState() => _TrainingRecordFormState();
}

class _TrainingRecordFormState extends State<TrainingRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _whatDidController = TextEditingController();
  final _howLongController = TextEditingController();
  final _commentController = TextEditingController();
  final _whereController = TextEditingController();
  final _countController = TextEditingController();
  final _repository = TrainingRepository();

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _whatDidController.dispose();
    _howLongController.dispose();
    _commentController.dispose();
    _whereController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      try {
        final record = TrainingRecord(
          date: _selectedDate,
          activity: _whatDidController.text,
          duration: _howLongController.text,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text,
          location: _whereController.text.trim().isEmpty
              ? null
              : _whereController.text,
          monthlyCount: int.tryParse(_countController.text) ?? 0,
        );

        await _repository.saveRecord(record);

        if (mounted) {
          FocusScope.of(context).unfocus();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('記録を保存しました！'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('トレーニング記録')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Actions(
              actions: <Type, Action<Intent>>{
                NextFocusIntent: _ComposingAwareNextFocusAction(),
              },
              child: Form(
                key: _formKey,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '日付',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(
                      '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '何をしたか',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _whatDidController,
                    decoration: const InputDecoration(
                      hintText: '',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '何をしたかを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'どれくらいの時間やったか',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _howLongController,
                    decoration: const InputDecoration(
                      hintText: '',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'どれくらいの時間やったかを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'コメント',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: '',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'どこでやったか',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _whereController,
                    decoration: const InputDecoration(
                      hintText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_selectedDate.month}月の運動回数',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _countController,
                    decoration: const InputDecoration(
                      hintText: '',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '運動回数を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveRecord,
                      child: const Text('登録'),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Flutter WebではIME変換中にTabキーを押すとフォーカスが次のフィールドに移動し、
/// TextInputConnectionの不整合によりアサーションエラーが発生する。
/// このActionはIME変換中（composing中）のみTabによるフォーカス移動を抑制し、
/// 通常時は標準のフォーカス移動を維持する。
class _ComposingAwareNextFocusAction extends Action<NextFocusIntent> {
  bool get _isComposing {
    final context = primaryFocus?.context;
    if (context == null) return false;
    final editableText = context.findAncestorStateOfType<EditableTextState>();
    if (editableText == null) return false;
    final composing = editableText.textEditingValue.composing;
    return composing.isValid && !composing.isCollapsed;
  }

  @override
  Object? invoke(NextFocusIntent intent) {
    if (_isComposing) {
      return null;
    }
    primaryFocus?.nextFocus();
    return null;
  }
}
