import 'dart:js_interop';

@JS('navigator.storage')
external _StorageManager? get _storage;

extension type _StorageManager._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> persist();
  external JSPromise<JSBoolean> persisted();
  external JSPromise<_StorageEstimate> estimate();
}

extension type _StorageEstimate._(JSObject _) implements JSObject {
  external double? get quota;
  external double? get usage;
}

class StorageEstimate {
  const StorageEstimate({this.usage, this.quota});

  final int? usage;
  final int? quota;
}

class PersistentStorage {
  static bool get isSupported => _storage != null;

  static Future<bool> isPersisted() async {
    final storage = _storage;
    if (storage == null) return false;
    final result = await storage.persisted().toDart;
    return result.toDart;
  }

  static Future<bool> requestPersist() async {
    final storage = _storage;
    if (storage == null) return false;
    final result = await storage.persist().toDart;
    return result.toDart;
  }

  static Future<StorageEstimate> estimate() async {
    final storage = _storage;
    if (storage == null) return const StorageEstimate();
    final result = await storage.estimate().toDart;
    return StorageEstimate(
      usage: result.usage?.toInt(),
      quota: result.quota?.toInt(),
    );
  }
}
