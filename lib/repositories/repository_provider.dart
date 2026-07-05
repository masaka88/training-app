import '../utils/storage_persistence_prompt.dart';
import 'training_repository.dart';

/// アプリ全体で使用するTrainingRepositoryインスタンス。
/// main.dartで初期化される。
late final TrainingRepository repository;

/// 永続ストレージ要求のプロンプト制御。
/// main.dartで初期化される。
late final StoragePersistencePrompt storagePersistencePrompt;
