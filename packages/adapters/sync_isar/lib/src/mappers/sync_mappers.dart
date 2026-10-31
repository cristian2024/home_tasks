import 'dart:convert';

import 'package:core_sync/core_sync.dart';

import '../models/isar_sync_change_record.dart';
import '../models/isar_sync_conflict.dart';
import '../models/isar_sync_peer.dart';
import '../models/isar_sync_state.dart';

/// Conversión entre los modelos de `core_sync` y los de Isar.
abstract final class SyncMappers {
  static IsarSyncChangeRecord toIsarRecord(ChangeRecord record) => IsarSyncChangeRecord()
    ..opId = record.opId
    ..deviceId = record.deviceId
    ..seq = record.seq
    ..json = jsonEncode(record.toJson());

  static ChangeRecord fromIsarRecord(IsarSyncChangeRecord record) => ChangeRecord.fromJson(jsonDecode(record.json));

  static DeviceIdentity? deviceOf(IsarSyncState? state) {
    final String? deviceId = state?.deviceId;
    return deviceId == null ? null : DeviceIdentity(deviceId: deviceId, name: state?.deviceName ?? '');
  }

  static void writeDevice(IsarSyncState state, DeviceIdentity device) => state
    ..deviceId = device.deviceId
    ..deviceName = device.name;

  static Household? householdOf(IsarSyncState? state) {
    final String? id = state?.householdId;
    final int? epoch = state?.householdEpoch;
    final String? creator = state?.householdCreatorDeviceId;
    if (id == null || epoch == null || creator == null) {
      return null;
    }
    return Household(id: id, epoch: epoch, creatorDeviceId: creator);
  }

  static void writeHousehold(IsarSyncState state, Household? household) => state
    ..householdId = household?.id
    ..householdEpoch = household?.epoch
    ..householdCreatorDeviceId = household?.creatorDeviceId;

  static Hlc? lastHlcOf(IsarSyncState? state) {
    final String? encoded = state?.lastHlc;
    return encoded == null ? null : Hlc.parse(encoded);
  }

  static IsarSyncPeer toIsarPeer(SyncPeer peer) => IsarSyncPeer()
    ..deviceId = peer.deviceId
    ..name = peer.name
    ..lastSyncedAt = peer.lastSyncedAt;

  static SyncPeer fromIsarPeer(IsarSyncPeer peer) =>
      SyncPeer(deviceId: peer.deviceId, name: peer.name, lastSyncedAt: peer.lastSyncedAt);

  static IsarSyncConflict toIsarConflict(SyncConflict conflict) => IsarSyncConflict()
    ..conflictId = conflict.id
    ..collection = conflict.collection
    ..kind = conflict.kind
    ..entityIds = List<String>.of(conflict.entityIds)
    ..options = jsonEncode(<Map<String, Object?>>[
      for (final ConflictOption option in conflict.options) <String, Object?>{'id': option.id, 'details': option.details},
    ])
    ..provisionalOptionId = conflict.provisionalOptionId
    ..detectedAt = conflict.detectedAt
    ..resolvedOptionId = conflict.resolvedOptionId;

  static SyncConflict fromIsarConflict(IsarSyncConflict conflict) => SyncConflict(
        id: conflict.conflictId,
        collection: conflict.collection,
        kind: conflict.kind,
        entityIds: conflict.entityIds,
        options: <ConflictOption>[
          for (final Object? option in jsonDecode(conflict.options) as List<Object?>) _optionOf(option! as Map<String, Object?>),
        ],
        provisionalOptionId: conflict.provisionalOptionId,
        detectedAt: conflict.detectedAt,
        resolvedOptionId: conflict.resolvedOptionId,
      );

  static ConflictOption _optionOf(Map<String, Object?> json) =>
      ConflictOption(json['id']! as String, details: Map<String, String>.from(json['details']! as Map<String, Object?>));
}
