import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

class SyncOperationModel extends Equatable {
  final String operationId;
  final String entityType; // e.g. 'task'
  final String entityId;
  final String operationType; // 'create', 'update', 'delete'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final DateTime nextRetryAt;
  final String status; // 'pending', 'processing', 'failed', 'completed'
  final String idempotencyKey;

  const SyncOperationModel({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    required this.nextRetryAt,
    this.status = 'pending',
    required this.idempotencyKey,
  });

  SyncOperationModel copyWith({
    String? operationId,
    String? entityType,
    String? entityId,
    String? operationType,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    DateTime? nextRetryAt,
    String? status,
    String? idempotencyKey,
  }) {
    return SyncOperationModel(
      operationId: operationId ?? this.operationId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      status: status ?? this.status,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  @override
  List<Object?> get props => [
        operationId,
        entityType,
        entityId,
        operationType,
        payload,
        createdAt,
        retryCount,
        nextRetryAt,
        status,
        idempotencyKey,
      ];
}

class SyncOperationModelAdapter extends TypeAdapter<SyncOperationModel> {
  @override
  final int typeId = 1;

  @override
  SyncOperationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // Handle Map<String, dynamic> safely from Hive binary
    Map<String, dynamic> parsedPayload = {};
    if (fields[4] != null) {
      if (fields[4] is Map) {
        parsedPayload = Map<String, dynamic>.from(fields[4] as Map);
      }
    }

    return SyncOperationModel(
      operationId: fields[0] as String,
      entityType: fields[1] as String,
      entityId: fields[2] as String,
      operationType: fields[3] as String,
      payload: parsedPayload,
      createdAt: fields[5] as DateTime,
      retryCount: fields[6] as int,
      nextRetryAt: fields[7] as DateTime,
      status: fields[8] as String,
      idempotencyKey: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperationModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.operationId)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.operationType)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.nextRetryAt)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.idempotencyKey);
  }
}
