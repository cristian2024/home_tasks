import 'package:core_di/core_di.dart';
import 'package:core_secrets/core_secrets.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';

import 'controller/sync_controller.dart';
import 'engine/local_recorder.dart';
import 'engine/record_applier.dart';
import 'engine/sync_engine.dart';
import 'household/household_service.dart';
import 'inbox/conflict_inbox.dart';

/// Compone el motor a partir de lo que los adaptadores registraron:
/// `ChangeLog`, `SyncStateRepository`, `ConflictRepository`, `SyncCipher`,
/// `SecretStore`, y los transportes y participantes de [SyncTransports] y
/// [SyncParticipants]. Va **después** de esos adaptadores en la lista de quien
/// compone.
///
/// Crea la identidad del dispositivo si no existe y registra [HlcClock] (si
/// ningún adaptador lo hizo), [HouseholdService], [SyncEngine],
/// [ConflictInbox] y [SyncController]. El controlador no arranca solo: quien
/// compone llama a `start()` cuando la app está lista.
class SyncModule implements DependencyModule {
  const SyncModule({
    this.deviceName = 'Dispositivo',
    this.clock = const SystemClock(),
    this.ids = const UuidV4Generator(),
    this.debounce = const Duration(seconds: 2),
  });

  /// Nombre del dispositivo la primera vez.
  final String deviceName;

  final Clock clock;
  final IdGenerator ids;

  /// Espera tras un cambio local antes de sincronizar.
  final Duration debounce;

  @override
  Future<void> register(ServiceLocator services) async {
    final SyncStateRepository state = services.get<SyncStateRepository>();
    final ChangeLog log = services.get<ChangeLog>();
    final ConflictRepository conflicts = services.get<ConflictRepository>();
    final SyncCipher cipher = services.get<SyncCipher>();
    final SyncParticipants participants = SyncParticipants.of(services);
    final SyncTransports transports = SyncTransports.of(services);

    final HouseholdService households =
        HouseholdService(state: state, secrets: services.get<SecretStore>(), cipher: cipher, ids: ids);
    final DeviceIdentity device = await households.ensureDevice(defaultName: deviceName);
    if (!services.isRegistered<HlcClock>()) {
      services.registerSingleton<HlcClock>(
        HlcClock(deviceId: device.deviceId, clock: clock, last: await state.readLastHlc()),
      );
    }
    final HlcClock hlcClock = services.get<HlcClock>();
    final RecordApplier applier = RecordApplier(
      log: log,
      participants: participants,
      conflicts: conflicts,
      state: state,
      hlcClock: hlcClock,
    );
    final SyncEngine engine =
        SyncEngine(households: households, state: state, log: log, applier: applier, cipher: cipher, clock: clock);

    services
      ..registerSingleton<HouseholdService>(households)
      ..registerSingleton<SyncEngine>(engine)
      ..registerSingleton<ConflictInbox>(ConflictInbox(
        conflicts: conflicts,
        participants: participants,
        recorder: LocalRecorder(log: log, hlcClock: hlcClock, ids: ids),
      ))
      ..registerSingleton<SyncController>(
        SyncController(
          engine: engine,
          households: households,
          log: log,
          transports: transports,
          state: state,
          hlcClock: hlcClock,
          clock: clock,
          debounce: debounce,
        ),
        dispose: (SyncController controller) => controller.stop(),
      );
  }
}
