import 'package:core_di/core_di.dart';
import 'package:core_hardware/testing.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:item_tracker_example/src/example_app.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/testing.dart';

void main() {
  testWidgets('carga los datos de ejemplo y abre «Caja A» al escanear QR-123', (WidgetTester tester) async {
    final FakeCameraScanner camera = FakeCameraScanner();
    final ServiceLocator locator = ServiceLocator();
    final LocalizationCoordinator localization = LocalizationCoordinator();
    final ItemTrackerPlugin plugin = ItemTrackerPlugin(
      locator: locator,
      cameraScannerFactory: () => camera,
      nfcScannerFactory: FakeNfcScanner.new,
      permissions: FakeHardwarePermissions(),
      repositoryFactory: (_) => InMemoryHouseholdItemRepository(),
      localization: localization,
    );
    await plugin.initialize();
    addTearDown(locator.reset);

    await tester.pumpWidget(ItemTrackerExampleApp(plugin: plugin, locator: locator, localization: localization));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay objetos registrados'), findsOneWidget);

    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pumpAndSettle();
    expect(find.text('3 objetos registrados'), findsOneWidget);

    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pumpAndSettle();
    expect(find.text('Los datos de ejemplo ya estaban cargados.'), findsOneWidget);

    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    camera.emit('QR-123');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Caja A'), findsOneWidget);

    localization.setLanguage('en');
    await tester.pumpAndSettle();
    expect(find.text('Identifiers'), findsOneWidget);
    localization.setLanguage('es');
  });
}
