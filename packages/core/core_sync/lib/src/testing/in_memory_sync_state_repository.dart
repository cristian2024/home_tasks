import 'dart:async';

import 'package:hlc/hlc.dart';

import '../contracts/sync_state_repository.dart';
import '../model/household.dart';
import 'watch.dart';

/// [SyncStateRepository] en memoria. Cumple `syncStateRepositoryContract`.
class InMemorySyncStateRepository implements SyncStateRepository {
  InMemorySyncStateRepository({DeviceIdentity? device, Household? household})
      : _device = device,
        _household = household;

  DeviceIdentity? _device;
  Household? _household;
  Hlc? _lastHlc;
  final Map<String, SyncPeer> _peers = <String, SyncPeer>{};
  final StreamController<void> _householdChanges = StreamController<void>.broadcast(sync: true);

  @override
  Future<DeviceIdentity?> readDevice() async => _device;

  @override
  Future<void> saveDevice(DeviceIdentity device) async => _device = device;

  @override
  Future<Household?> readHousehold() async => _household;

  @override
  Stream<Household?> watchHousehold() => watchValue(_householdChanges.stream, () => _household);

  @override
  Future<void> saveHousehold(Household household) async {
    _household = household;
    _householdChanges.add(null);
  }

  @override
  Future<void> clearHousehold() async {
    _household = null;
    _peers.clear();
    _householdChanges.add(null);
  }

  @override
  Future<Hlc?> readLastHlc() async => _lastHlc;

  @override
  Future<void> saveLastHlc(Hlc hlc) async => _lastHlc = hlc;

  @override
  Future<List<SyncPeer>> peers() async =>
      _peers.values.toList()..sort((SyncPeer a, SyncPeer b) => a.deviceId.compareTo(b.deviceId));

  @override
  Future<void> savePeer(SyncPeer peer) async => _peers[peer.deviceId] = peer;

  @override
  Future<void> removePeer(String deviceId) async => _peers.remove(deviceId);
}
