import 'package:hive/hive.dart';

enum SyncOpType { create, update, delete }

typedef Json = Map<String, dynamic>;

class SyncOperation extends HiveObject {
  String id;
  String box; // target local box name (e.g., messages)
  String table; // remote table name (e.g., messages)
  SyncOpType type;
  Json payload;
  DateTime queuedAt;
  int retryCount;
  String? lastError;

  SyncOperation({
    required this.id,
    required this.box,
    required this.table,
    required this.type,
    required this.payload,
    DateTime? queuedAt,
    this.retryCount = 0,
    this.lastError,
  }) : queuedAt = queuedAt ?? DateTime.now();
}

class SyncOperationAdapter extends TypeAdapter<SyncOperation> {
  @override
  final int typeId = 6;

  @override
  SyncOperation read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return SyncOperation(
      id: fields[0] as String,
      box: fields[1] as String,
      table: fields[2] as String,
      type: SyncOpType.values[fields[3] as int],
      payload: (fields[4] as Map).cast<String, dynamic>(),
      queuedAt: fields[5] as DateTime,
      retryCount: fields[6] as int,
      lastError: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.box)
      ..writeByte(2)
      ..write(obj.table)
      ..writeByte(3)
      ..write(obj.type.index)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.queuedAt)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.lastError);
  }
}

class SyncQueue {
  static const queueBoxName = 'sync_queue';
  late Box<SyncOperation> _box;

  static final SyncQueue instance = SyncQueue._internal();
  SyncQueue._internal();

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    _box = await Hive.openBox<SyncOperation>(queueBoxName);
  }

  Future<void> enqueue(SyncOperation op) async {
    await _box.put(op.id, op);
  }

  List<SyncOperation> getAll() => _box.values.toList()..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));

  Future<void> remove(String id) async => _box.delete(id);
  Future<void> clear() async => _box.clear();

  bool get isEmpty => _box.isEmpty;
}
