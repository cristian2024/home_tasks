import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:core_hardware/testing.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/testing.dart';

void main() {
  late ServiceLocator locator;

  setUp(() {
    locator = ServiceLocator()
      ..registerSingleton<HouseholdItemRepository>(InMemoryHouseholdItemRepository());
  });
  tearDown(() => locator.reset());

  ItemTrackerPlugin plugin() => ItemTrackerPlugin(locator: locator, localization: LocalizationCoordinator());

  test('toma del locator el hardware que registran los adaptadores', () async {
    final FakeHardwarePermissions permissions = FakeHardwarePermissions();
    locator
      ..registerFactory<CameraIdentifierScanner>(FakeCameraScanner.new)
      ..registerFactory<NfcIdentifierScanner>(FakeNfcScanner.new)
      ..registerSingleton<HardwarePermissions>(permissions);

    await plugin().initialize();

    final ItemTrackerDependencies dependencies = locator.get<ItemTrackerDependencies>();
    final CameraIdentifierScanner camera = dependencies.cameraScannerFactory();
    expect(camera, isA<FakeCameraScanner>());
    expect(identical(camera, dependencies.cameraScannerFactory()), isFalse);
    expect(dependencies.nfcScannerFactory(), isA<FakeNfcScanner>());
    expect(dependencies.permissions, same(permissions));
  });

  test('sin un adaptador de hardware, initialize falla', () async {
    locator
      ..registerFactory<CameraIdentifierScanner>(FakeCameraScanner.new)
      ..registerSingleton<HardwarePermissions>(FakeHardwarePermissions());

    await expectLater(plugin().initialize(), throwsStateError);
  });
}
