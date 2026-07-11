import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'models/training_record.dart';
import 'repositories/repository_provider.dart';
import 'repositories/supabase_training_records_api.dart';
import 'repositories/supabase_training_repository.dart';
import 'screens/auth_gate.dart';
import 'services/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/local_data_migrator.dart';
import 'services/migrator_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabaseの初期化（セッションは自動で永続化・復元される）
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  authService = SupabaseAuthService(Supabase.instance.client.auth);

  // Repositoryの初期化（永続化の正はSupabase）
  final recordsApi = SupabaseTrainingRecordsApi(Supabase.instance.client);
  repository = SupabaseTrainingRepository(recordsApi);

  // Hiveは移行元としてのみ初期化する（移行完了・動作確認後に撤去予定）
  await Hive.initFlutter();
  Hive.registerAdapter(TrainingRecordAdapter());
  final box = await Hive.openBox<TrainingRecord>('training_records');
  localDataMigrator = LocalDataMigrator(localBox: box, remoteApi: recordsApi);

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
      home: const AuthGate(),
    );
  }
}
