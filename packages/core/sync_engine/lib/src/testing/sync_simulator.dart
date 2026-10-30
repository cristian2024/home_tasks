import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:core_di/core_di.dart';
import 'package:core_secrets/core_secrets.dart';
import 'package:core_secrets/testing.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:core_utils/core_utils.dart';

import '../controller/sync_controller.dart';
import '../engine/local_recorder.dart';
import '../engine/sync_engine.dart';
import '../engine/sync_session.dart';
import '../household/household_invitation.dart';
import '../household/household_keys.dart';
import '../household/household_service.dart';
import '../inbox/conflict_inbox.dart';
import '../sync_module.dart';
import 'key_value_store.dart';

/// Un dispositivo simulado: dobles en memoria de todos los contratos, un
/// [KeyValueStore] como participante y el motor compuesto con [SyncModule],
/// como lo haría una app.
class SimulatedDevice {
  SimulatedDevice._(this.name, this.services, this.transport, this.store);

  /// Crea un dispositivo en [network]. [clock] es compartido para que el
  /// tiempo avance igual en todos; [ids] da ids deterministas.
  static Future<SimulatedDevice> create(
    String name, {
    required InMemorySyncNetwork network,
    required Clock clock,
    required IdGenerator ids,
    Duration debounce = const Duration(milliseconds: 10),
  }) async {
    final ServiceLocator services = ServiceLocator();
    final InMemorySyncTransport transport = network.transport();
    final KeyValueStore store = KeyValueStore(
      recorder: () => LocalRecorder(log: services.get<ChangeLog>(), hlcClock: services.get<HlcClock>(), ids: ids),
    );
    services
      ..registerSingleton<ChangeLog>(InMemoryChangeLog())
      ..registerSingleton<SyncStateRepository>(InMemorySyncStateRepository())
      ..registerSingleton<ConflictRepository>(InMemoryConflictRepository())
      ..registerSingleton<SecretStore>(InMemorySecretStore())
      ..registerSingleton<SyncCipher>(FakeSyncCipher(random: Random(name.hashCode)));
    SyncTransports.of(services).add(transport);
    SyncParticipants.of(services).add(store);
    await SyncModule(deviceName: name, clock: clock, ids: ids, debounce: debounce).register(services);
    return SimulatedDevice._(name, services, transport, store);
  }

  final String name;
  final ServiceLocator services;
  final InMemorySyncTransport transport;
  final KeyValueStore store;
  final List<Future<void>> _accepted = <Future<void>>[];
  StreamSubscription<SyncChannel>? _incoming;

  String get deviceId => services.get<HlcClock>().deviceId;
  ChangeLog get log => services.get<ChangeLog>();
  SyncEngine get engine => services.get<SyncEngine>();
  HouseholdService get households => services.get<HouseholdService>();
  SyncController get controller => services.get<SyncController>();
  ConflictInbox get inbox => services.get<ConflictInbox>();
  SyncStateRepository get state => services.get<SyncStateRepository>();

  /// Se anuncia con la clave del hogar y acepta las sesiones, sin el
  /// controlador: el simulador decide cuándo sincroniza cada par. No usar
  /// junto con `controller.start()`, que también acepta.
  Future<void> advertise() async {
    _incoming ??= transport.incoming.listen((SyncChannel channel) {
      _accepted.add(engine.accept(channel).then<void>((_) {}, onError: (Object _) {}));
    });
    final HouseholdKeys keys = (await households.keys())!;
    await transport.start(SyncAdvertisement(
      discoveryId: await keys.discoveryId(),
      deviceId: deviceId,
      deviceName: name,
    ));
  }

  /// Sincroniza con [other] si lo ve y espera a que el otro termine. Devuelve
  /// `null` si no lo ve o la sesión falla.
  Future<SyncSessionResult?> syncWith(SimulatedDevice other) async {
    final SyncEndpoint? endpoint = (await transport.watchEndpoints().first)
        .where((SyncEndpoint endpoint) => endpoint.deviceId == other.deviceId)
        .firstOrNull;
    if (endpoint == null) {
      return null;
    }
    try {
      return await engine.syncWith(transport, endpoint);
    } on Object {
      return null;
    } finally {
      await other.settle();
    }
  }

  /// Espera a que terminen las sesiones aceptadas.
  Future<void> settle() async {
    while (_accepted.isNotEmpty) {
      await _accepted.removeAt(0);
    }
  }

  Future<void> dispose() async {
    await _incoming?.cancel();
    await transport.dispose();
    await services.reset();
  }
}

/// Simulador de N dispositivos de un hogar con ediciones concurrentes,
/// sincronizaciones por pares en orden aleatorio y cortes de red. Con la misma
/// [seed] repite exactamente lo mismo.
///
/// ```dart
/// final SyncSimulator simulator = await SyncSimulator.create(devices: 4, seed: 7);
/// await simulator.run(steps: 300);
/// await simulator.converge();
/// expect(simulator.converged, isTrue);
/// ```
class SyncSimulator {
  SyncSimulator._(this.seed, this.network, this.clock, this.devices, this._random);

  static Future<SyncSimulator> create({required int devices, required int seed}) async {
    final Random random = Random(seed);
    final InMemorySyncNetwork network = InMemorySyncNetwork();
    final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 30, 12));
    final _SeededIds ids = _SeededIds(random);
    final List<SimulatedDevice> created = <SimulatedDevice>[
      for (int i = 0; i < devices; i++)
        await SimulatedDevice.create('device-$i', network: network, clock: clock, ids: ids),
    ];
    final HouseholdInvitation invitation = await created.first.households.create();
    for (final SimulatedDevice device in created.skip(1)) {
      await device.households.join(invitation);
    }
    for (final SimulatedDevice device in created) {
      await device.advertise();
    }
    return SyncSimulator._(seed, network, clock, created, random);
  }

  static const List<String> _entities = <String>['leche', 'pan', 'huevos', 'caja', 'cajón'];
  static const List<String> _fields = <String>['name', 'quantity', 'urgent'];
  static const List<String> _tags = <String>['a', 'b', 'c'];

  final int seed;
  final InMemorySyncNetwork network;
  final FixedClock clock;
  final List<SimulatedDevice> devices;
  final Random _random;

  /// Sesiones que terminaron bien y que fallaron o no se vieron.
  int completedSessions = 0;
  int failedSessions = 0;

  /// Ejecuta [steps] pasos aleatorios: ediciones (60 %), sincronizaciones de un
  /// par (30 %) y cortes o reconexiones de red (10 %). Cada paso avanza el
  /// reloj unos milisegundos, a veces nada (marcas con el mismo tiempo).
  Future<void> run({required int steps}) async {
    for (int step = 0; step < steps; step++) {
      clock.advance(Duration(milliseconds: _random.nextInt(3)));
      final int roll = _random.nextInt(10);
      if (roll < 6) {
        await randomEdit(_pick(devices));
      } else if (roll < 9) {
        await _syncPair(_pick(devices), _pick(devices));
      } else {
        final SimulatedDevice a = _pick(devices);
        final SimulatedDevice b = _pick(devices);
        if (_random.nextBool()) {
          network.partition(a.deviceId, b.deviceId);
        } else {
          network.heal(a.deviceId, b.deviceId);
        }
      }
    }
  }

  /// Una edición aleatoria en [device]: un campo, un elemento de un conjunto
  /// o un borrado.
  Future<void> randomEdit(SimulatedDevice device) async {
    final String entity = _pick(_entities);
    final int kind = _random.nextInt(10);
    if (kind < 6) {
      await device.store.put(entity, <String, Object?>{_pick(_fields): '${device.name}:${_random.nextInt(100)}'});
    } else if (kind < 9) {
      await device.store.setElement(entity, 'tags', _pick(_tags), present: _random.nextBool());
    } else {
      await device.store.delete(entity);
    }
  }

  /// Quita los cortes y sincroniza todos los pares, en orden aleatorio, hasta
  /// que convergen (como mucho [maxRounds] rondas).
  Future<void> converge({int maxRounds = 5}) async {
    network.healAll();
    for (int round = 0; round < maxRounds && !converged; round++) {
      final List<(SimulatedDevice, SimulatedDevice)> pairs = <(SimulatedDevice, SimulatedDevice)>[
        for (final SimulatedDevice a in devices)
          for (final SimulatedDevice b in devices)
            if (a != b) (a, b),
      ]..shuffle(_random);
      for (final (SimulatedDevice a, SimulatedDevice b) in pairs) {
        await _syncPair(a, b);
      }
    }
  }

  /// Si todos los dispositivos tienen el mismo estado.
  bool get converged {
    final Map<String, Object?> first = devices.first.store.snapshot();
    return devices.every((SimulatedDevice device) => _equality.equals(device.store.snapshot(), first));
  }

  /// Si todos los dispositivos tienen los mismos registros.
  Future<bool> logsConverged() async {
    final VersionVector first = await devices.first.log.vector();
    for (final SimulatedDevice device in devices) {
      if (await device.log.vector() != first) {
        return false;
      }
    }
    return true;
  }

  /// Estado de cada dispositivo, por nombre.
  Map<String, Object?> get states => <String, Object?>{
        for (final SimulatedDevice device in devices) device.name: device.store.snapshot(),
      };

  Future<void> dispose() async {
    for (final SimulatedDevice device in devices) {
      await device.dispose();
    }
  }

  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  Future<void> _syncPair(SimulatedDevice a, SimulatedDevice b) async {
    if (a == b) {
      return;
    }
    if (await a.syncWith(b) == null) {
      failedSessions++;
    } else {
      completedSessions++;
    }
  }

  T _pick<T>(List<T> values) => values[_random.nextInt(values.length)];
}

/// Ids v4 reproducibles a partir del [Random] del simulador.
class _SeededIds implements IdGenerator {
  _SeededIds(this._random);

  final Random _random;

  @override
  String newId() {
    String hex(int length) => List<String>.generate(length, (_) => _random.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-${'89ab'[_random.nextInt(4)]}${hex(3)}-${hex(12)}';
  }
}
