import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'models/training_record.dart';
import 'repositories/repository_provider.dart';
import 'repositories/training_repository.dart';
import 'screens/training_record_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hiveの初期化
  await Hive.initFlutter();

  // TrainingRecordAdapterの登録
  Hive.registerAdapter(TrainingRecordAdapter());

  // Repositoryの初期化
  final box = await Hive.openBox<TrainingRecord>('training_records');
  repository = TrainingRepository(box);

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
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            backgroundColor: WidgetStateProperty.all(Colors.blueAccent),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 16),
            ),
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      home: const TrainingRecordList(),
    );
  }
}
