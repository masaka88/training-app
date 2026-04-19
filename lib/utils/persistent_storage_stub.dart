class StorageEstimate {
  const StorageEstimate({this.usage, this.quota});

  final int? usage;
  final int? quota;
}

class PersistentStorage {
  static bool get isSupported => false;

  static Future<bool> isPersisted() async => false;

  static Future<bool> requestPersist() async => false;

  static Future<StorageEstimate> estimate() async => const StorageEstimate();
}
