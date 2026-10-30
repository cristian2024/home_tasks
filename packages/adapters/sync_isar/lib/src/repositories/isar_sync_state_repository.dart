import 'package:core_sync/core_sync.dart';
import 'package:storage_isar/adapter.dart';

import '../mappers/sync_mappers.dart';
import '../models/isar_sync_peer.dart';
import '../models/isar_sync_state.dart';

/// [SyncStateRepository] sobre Isar. El dispositivo, el hogar y el último HLC
/// van en un solo objeto; los dispositivos conocidos, en su colección.
class IsarSyncStateRepository implements SyncStateRepository {
  IsarSyncStateRepository(this._isar);

  final Isar _isar;

  @override
  Future<DeviceIdentity?> readDevice() async => SyncMappers.deviceOf(await _state());

  @override
  Future<void> saveDevice(DeviceIdentity device) =>
      _update((IsarSyncState state) => SyncMappers.writeDevice(state, device));

  @override
  Future<Household?> readHousehold() async => SyncMappers.householdOf(await _state());

  @override
  Stream<Household?> watchHousehold() => _isar.isarSyncStates
      .watchObject(IsarSyncState.singletonId, fireImmediately: true)
      .map(SyncMappers.householdOf)
      .distinct();

  @override
  Future<void> saveHousehold(Household household) =>
      _update((IsarSyncState state) => SyncMappers.writeHousehold(state, household));

  @override
  Future<void> clearHousehold() => _isar.writeTxn(() async {
        final IsarSyncState state = await _state() ?? IsarSyncState();
        SyncMappers.writeHousehold(state, null);
        await _isar.isarSyncStates.put(state);
        await _isar.isarSyncPeers.clear();
      });

  @override
  Future<Hlc?> readLastHlc() async => SyncMappers.lastHlcOf(await _state());

  @override
  Future<void> saveLastHlc(Hlc hlc) => _update((IsarSyncState state) => state.lastHlc = hlc.encode());

  @override
  Future<List<SyncPeer>> peers() async =>
      (await _isar.isarSyncPeers.where().sortByDeviceId().findAll()).map(SyncMappers.fromIsarPeer).toList();

  @override
  Future<void> savePeer(SyncPeer peer) => _isar.writeTxn(() => _isar.isarSyncPeers.put(SyncMappers.toIsarPeer(peer)));

  @override
  Future<void> removePeer(String deviceId) => _isar.writeTxn(() => _isar.isarSyncPeers.deleteByDeviceId(deviceId));

  Future<IsarSyncState?> _state() => _isar.isarSyncStates.get(IsarSyncState.singletonId);

  Future<void> _update(void Function(IsarSyncState state) change) => _isar.writeTxn(() async {
        final IsarSyncState state = await _state() ?? IsarSyncState();
        change(state);
        await _isar.isarSyncStates.put(state);
      });
}
