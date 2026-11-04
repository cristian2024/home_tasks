import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';

import '../household/household_keys.dart';
import '../household/household_service.dart';
import '../sync_engine_exception.dart';
import 'record_applier.dart';
import 'sync_session.dart';

/// Abre y acepta sesiones de sincronización con otros dispositivos del hogar.
class SyncEngine {
  SyncEngine({
    required HouseholdService households,
    required SyncStateRepository state,
    required ChangeLog log,
    required RecordApplier applier,
    required SyncCipher cipher,
    Clock clock = const SystemClock(),
    this.batchSize = 200,
    this.timeout = const Duration(seconds: 30),
  })  : _households = households,
        _state = state,
        _log = log,
        _applier = applier,
        _cipher = cipher,
        _clock = clock;

  final int batchSize;
  final Duration timeout;
  final HouseholdService _households;
  final SyncStateRepository _state;
  final ChangeLog _log;
  final RecordApplier _applier;
  final SyncCipher _cipher;
  final Clock _clock;

  /// Conecta con [endpoint] por [transport] y sincroniza. Lanza
  /// [NotInHouseholdException] sin hogar; ver [SyncSession.run] para el resto.
  Future<SyncSessionResult> syncWith(SyncTransport transport, SyncEndpoint endpoint) async {
    final (DeviceIdentity device, HouseholdKeys keys) = await _context();
    return _run(await transport.connect(endpoint), device, keys);
  }

  /// Sincroniza por un canal que abrió otro dispositivo. Sin hogar, lo cierra
  /// y lanza [NotInHouseholdException].
  Future<SyncSessionResult> accept(SyncChannel channel) async {
    try {
      final (DeviceIdentity device, HouseholdKeys keys) = await _context();
      return await _run(channel, device, keys);
    } on NotInHouseholdException {
      await channel.close();
      rethrow;
    }
  }

  Future<(DeviceIdentity, HouseholdKeys)> _context() async {
    final HouseholdKeys? keys = await _households.keys();
    final DeviceIdentity? device = await _state.readDevice();
    if (keys == null || device == null) {
      throw const NotInHouseholdException();
    }
    return (device, keys);
  }

  Future<SyncSessionResult> _run(SyncChannel channel, DeviceIdentity device, HouseholdKeys keys) async {
    final SyncSessionResult result = await SyncSession(
      channel: channel,
      device: device,
      keys: keys,
      log: _log,
      applier: _applier,
      cipher: _cipher,
      batchSize: batchSize,
      timeout: timeout,
    ).run();
    await _state.savePeer(
      SyncPeer(deviceId: result.peer.deviceId, name: result.peer.name, lastSyncedAt: _clock.nowUtc()),
    );
    return result;
  }
}
