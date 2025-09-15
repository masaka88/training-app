import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'トレーニング記録',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Roboto',
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          filled: true,
          fillColor: Color(0xFFF5F7FB),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            backgroundColor: MaterialStatePropertyAll(Colors.blueAccent),
            foregroundColor: MaterialStatePropertyAll(Colors.white),
            padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
            textStyle: MaterialStatePropertyAll(
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      home: const TrainingRecordForm(),
    );
  }
}

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

  DateTime _selectedDate = DateTime.now();
  String _generatedText = '';

  @override
  void dispose() {
    _whatDidController.dispose();
    _howLongController.dispose();
    _commentController.dispose();
    _whereController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _generateSlackMessage() {
    final dateText =
        '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}';
    final monthText = '${_selectedDate.month}月の運動回数';

    final List<String> messageLines = [];
    messageLines.add('*日付*');
    messageLines.add(dateText);
    messageLines.add('*何をしたか*');
    messageLines.add(_whatDidController.text);
    messageLines.add('*どれくらいやったか*');
    messageLines.add(_howLongController.text);

    if (_commentController.text.trim().isNotEmpty) {
      messageLines.add('*コメント*');
      messageLines.add(_commentController.text);
    }
    if (_whereController.text.trim().isNotEmpty) {
      messageLines.add('*どこでやったか*');
      messageLines.add(_whereController.text);
    }
    messageLines.add('*$monthText*');
    messageLines.add(_countController.text);

    setState(() {
      _generatedText = messageLines.join('\n');
    });
  }

  void _copyToClipboard() {
    if (_generatedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('クリップボードにコピーしました！')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トレーニング記録'),
      ),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('日付', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(
                        '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}'),
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
                  const Text('何をしたか', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('どれくらいの時間やったか', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('コメント', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('どこでやったか', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _whereController,
                    decoration: const InputDecoration(
                      hintText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${_selectedDate.month}月の運動回数',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _generateSlackMessage();
                        }
                      },
                      child: const Text('投稿用メッセージを生成'),
                    ),
                  ),
                  if (_generatedText.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Card(
                      elevation: 2,
                      color: const Color(0xFFF5F7FB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '生成されたメッセージ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Text(
                                _generatedText,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _copyToClipboard,
                                icon: const Icon(Icons.copy),
                                label: const Text('クリップボードにコピー'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
