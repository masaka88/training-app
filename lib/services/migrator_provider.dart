import 'local_data_migrator.dart';

/// アプリ全体で使用するLocalDataMigratorインスタンス。
/// main.dartで初期化される。移行が不要になったらnullのままでよい。
LocalDataMigrator? localDataMigrator;
