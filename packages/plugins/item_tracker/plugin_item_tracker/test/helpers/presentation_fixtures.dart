import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:core_hardware/testing.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/testing.dart';

/// Hardware simulado. Cada llamada a la factoría crea un escáner nuevo (el
/// bloc libera el anterior al cambiar de modo) y se guarda para inspeccionarlo.
class FakeHardware {
  FakeHardware({
    HardwarePermissionStatus cameraPermission = HardwarePermissionStatus.granted,
    this.nfcStatus = HardwareStatus.available,
  }) : permissions = FakeHardwarePermissions(status: cameraPermission);

  final FakeHardwarePermissions permissions;
  HardwareStatus nfcStatus;
  final List<FakeCameraScanner> cameras = <FakeCameraScanner>[];
  final List<FakeNfcScanner> nfcs = <FakeNfcScanner>[];

  FakeCameraScanner get camera => cameras.last;
  FakeNfcScanner get nfc => nfcs.last;

  CameraIdentifierScanner createCamera() {
    final FakeCameraScanner camera = FakeCameraScanner();
    cameras.add(camera);
    return camera;
  }

  NfcIdentifierScanner createNfc() {
    final FakeNfcScanner nfc = FakeNfcScanner(hardwareStatus: nfcStatus);
    nfcs.add(nfc);
    return nfc;
  }
}

/// Casos de uso reales sobre un repositorio en memoria.
class TestUseCases {
  TestUseCases({this.policy = const ContainmentPolicy()}) : repository = InMemoryHouseholdItemRepository();

  final InMemoryHouseholdItemRepository repository;
  final ContainmentPolicy policy;
  final IdGenerator ids = _Ids();
  final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 21, 14, 30));
  final EventBus eventBus = EventBus();

  CreateItem get createItem => CreateItem(repository, ids, clock, eventBus, policy);
  MoveItem get moveItem => MoveItem(repository, ids, clock, policy);
  DeleteItem get deleteItem => DeleteItem(repository, ids, clock);
  WatchItemTree get watchItemTree => WatchItemTree(repository);
  UpdateItem get updateItem => UpdateItem(repository, ids, clock);
  BindIdentifier get bindIdentifier => BindIdentifier(repository, ids, clock);
  UnbindIdentifier get unbindIdentifier => UnbindIdentifier(repository, ids, clock);
  FindItemByIdentifier get findItemByIdentifier => FindItemByIdentifier(repository);
}

class _Ids implements IdGenerator {
  int _next = 1;

  @override
  String newId() => 'id-${_next++}';
}

/// Monta el plugin inicializado dentro de una app mínima con su dashboard en
/// `/` y sus rutas. El plugin se inicializa la primera vez que hace falta.
class PluginHarness {
  PluginHarness({FakeHardware? hardware, int? maxContainmentDepth}) : hardware = hardware ?? FakeHardware() {
    // Como el adaptador de almacenamiento que elige la app.
    locator
      ..registerSingleton<HouseholdItemRepository>(repository)
      ..registerSingleton<IdGenerator>(_Ids())
      ..registerSingleton<Clock>(FixedClock(DateTime.utc(2026, 10, 21, 14, 30)));
    plugin = ItemTrackerPlugin(
      locator: locator,
      cameraScannerFactory: this.hardware.createCamera,
      nfcScannerFactory: this.hardware.createNfc,
      permissions: this.hardware.permissions,
      localization: localization,
      maxContainmentDepth: maxContainmentDepth,
    );
  }

  final FakeHardware hardware;
  final InMemoryHouseholdItemRepository repository = InMemoryHouseholdItemRepository();
  final ServiceLocator locator = ServiceLocator();
  final LocalizationCoordinator localization = LocalizationCoordinator();
  late final ItemTrackerPlugin plugin;
  late GoRouter router;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _initialized = true;
      await plugin.initialize();
    }
  }

  Future<void> pump(WidgetTester tester, {String initialLocation = '/'}) async {
    await _ensureInitialized();
    router = GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (BuildContext context, _) => Scaffold(body: plugin.buildDashboardTile(context))),
        ...plugin.routes,
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: LocalizationCoordinator.supportedLocales,
        localizationsDelegates: LocalizationCoordinator.localizationsDelegates,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<HouseholdItem> createItem(String name, {String? qr, String? nfc, String? parentId}) async {
    await _ensureInitialized();
    final ItemTrackerDependencies deps = locator.get<ItemTrackerDependencies>();
    final HouseholdItem item = await deps.createItem(
      name: name,
      identifier: qr == null ? null : (rawValue: qr, type: IdentifierType.qr),
      parentId: parentId,
    );
    if (nfc != null) {
      await deps.bindIdentifier(item.id, rawValue: nfc, type: IdentifierType.nfc);
    }
    return item;
  }

  Future<void> dispose() async {
    if (_initialized) {
      await plugin.dispose();
    }
    await locator.reset();
  }
}
