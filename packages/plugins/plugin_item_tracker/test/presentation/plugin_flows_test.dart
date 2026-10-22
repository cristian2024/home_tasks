import 'package:core_hardware/core_hardware.dart';
import 'package:core_hardware/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late PluginHarness harness;

  setUp(() => harness = PluginHarness());
  tearDown(() => harness.dispose());

  Future<void> openScan(WidgetTester tester) async {
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
  }

  group('ItemTrackerPlugin', () {
    testWidgets('expone su contrato y registra/libera sus dependencias en su scope', (tester) async {
      await harness.pump(tester);
      final plugin = harness.plugin;

      expect(plugin.id, 'item_tracker');
      expect(harness.localization.translate(plugin.nameKey), 'Seguimiento de Objetos');
      expect(harness.localization.translate(plugin.descriptionKey), startsWith('Identifica'));
      expect(plugin.storageSchemas, itemTrackerSchemas);
      expect(await plugin.isAvailable(), isTrue);
      expect(harness.locator.hasScope('item_tracker'), isTrue);
      expect(harness.locator.isRegistered<ItemTrackerDependencies>(), isTrue);

      await plugin.dispose();
      expect(harness.locator.hasScope('item_tracker'), isFalse);
      expect(harness.locator.isRegistered<ItemTrackerDependencies>(), isFalse);
      await plugin.initialize(); // Para el tearDown.
    });

    testWidgets('el dashboard muestra el número de objetos y abre el listado', (tester) async {
      await harness.createItem('Caja A');
      await harness.pump(tester);

      expect(find.text('1 objeto registrado'), findsOneWidget);

      await tester.tap(find.text('Ver objetos'));
      await tester.pumpAndSettle();
      expect(find.text('Caja A'), findsOneWidget);
    });

    testWidgets('cambia de idioma a través del coordinador', (tester) async {
      await harness.pump(tester);

      harness.localization.setLanguage('en');
      await tester.pumpWidget(Container());
      await harness.pump(tester);
      expect(find.text('Scan'), findsOneWidget);

      harness.localization.setLanguage('es');
    });
  });

  testWidgets('AC-03: escanear un QR conocido abre el detalle del objeto', (tester) async {
    await harness.createItem('Caja A', qr: 'QR-123');
    await harness.pump(tester);
    await openScan(tester);

    expect(find.byKey(FakeCameraScanner.previewKey), findsOneWidget);
    harness.hardware.camera.emit('QR-123');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Caja A'), findsOneWidget);
    expect(find.text('QR-123'), findsOneWidget);
  });

  testWidgets('AC-04: un QR desconocido muestra Crear nuevo y Asociar a existente', (tester) async {
    await harness.pump(tester);
    await openScan(tester);

    harness.hardware.camera.emit('UNKNOWN-99');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Identificador no registrado'), findsOneWidget);
    expect(find.textContaining('UNKNOWN-99'), findsOneWidget);
    expect(find.text('Crear nuevo objeto'), findsOneWidget);
    expect(find.text('Asociar a un objeto existente'), findsOneWidget);
  });

  testWidgets('crear desde un código desconocido asocia el código y abre el detalle', (tester) async {
    await harness.pump(tester);
    await openScan(tester);
    harness.hardware.camera.emit('NEW-1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear nuevo objeto'));
    await tester.pumpAndSettle();
    expect(find.text('Se asociará el QR: NEW-1'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Caja nueva');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Caja nueva'), findsOneWidget);
    expect(find.text('NEW-1'), findsOneWidget);
    expect(find.text('Objeto creado como «Caja nueva»'), findsOneWidget);

    // Al volver, la pantalla de escaneo reanuda la cámara.
    await tester.tap(find.byType(BackButton)); // pageBack() busca el tooltip en inglés.
    await tester.pumpAndSettle();
    expect(harness.hardware.camera.isScanning, isTrue);
  });

  testWidgets('AC-05: QR y NFC asociados a "Cama" llevan al mismo objeto', (tester) async {
    await harness.createItem('Cama', qr: 'QR-BED');
    await harness.createItem('Mesa');
    await harness.pump(tester);
    await openScan(tester);

    await tester.tap(find.text('NFC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leer etiqueta'));
    await tester.pumpAndSettle();
    harness.hardware.nfc.emit('NFC-BED');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asociar a un objeto existente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cama'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Cama'), findsOneWidget);
    expect(find.text('QR-BED'), findsOneWidget);
    expect(find.text('NFC-BED'), findsOneWidget);

    // Leer de nuevo la etiqueta NFC lleva directamente al mismo objeto.
    await tester.tap(find.byType(BackButton)); // pageBack() busca el tooltip en inglés.
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leer etiqueta'));
    await tester.pumpAndSettle();
    harness.hardware.nfc.emit('NFC-BED');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Cama'), findsOneWidget);
  });

  testWidgets('AC-06: sin NFC la opción muestra un mensaje accesible sin errores', (tester) async {
    harness = PluginHarness(hardware: FakeHardware(nfcStatus: HardwareStatus.unsupported));
    await harness.pump(tester);
    await openScan(tester);

    await tester.tap(find.text('NFC'));
    await tester.pumpAndSettle();

    expect(find.text('Este dispositivo no tiene NFC'), findsOneWidget);
    expect(find.text('Leer etiqueta'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Escribir el código'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Código'), findsOneWidget);
  });

  testWidgets('el selector Código oculta la cámara y Cámara oculta el campo', (tester) async {
    await harness.createItem('Caja A', qr: 'QR-123');
    await harness.pump(tester);
    await openScan(tester);

    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();
    expect(find.byKey(FakeCameraScanner.previewKey), findsNothing);
    expect(harness.hardware.cameras.single.isDisposed, isTrue);
    expect(find.widgetWithText(TextField, 'Código'), findsOneWidget);

    await tester.tap(find.text('Cámara'));
    await tester.pumpAndSettle();
    expect(find.byKey(FakeCameraScanner.previewKey), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Código'), findsNothing);

    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('Este campo es obligatorio.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'QR-123');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Caja A'), findsOneWidget);
  });

  testWidgets('sin permiso de cámara ofrece concederlo o escribir el código', (tester) async {
    harness = PluginHarness(hardware: FakeHardware(cameraPermission: HardwarePermissionStatus.denied));
    harness.hardware.permissions.statusAfterRequest = HardwarePermissionStatus.granted;
    await harness.pump(tester);
    await openScan(tester);

    expect(find.text('Se necesita la cámara'), findsOneWidget);
    await tester.tap(find.text('Conceder permiso'));
    await tester.pumpAndSettle();

    expect(find.byKey(FakeCameraScanner.previewKey), findsOneWidget);
  });

  testWidgets('desde el detalle se edita el objeto y se añade una nota', (tester) async {
    final item = await harness.createItem('Caja A', qr: 'QR-123');
    await harness.pump(tester, initialLocation: ItemTrackerRoutes.detail(item.id));

    await tester.tap(find.byTooltip('Editar objeto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Caja grande');
    await tester.tap(find.byTooltip('Añadir dato'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Clave'), 'color_etiqueta');
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), 'Azul');
    // El viewport del test es bajo: el botón queda fuera de la lista visible.
    await tester.scrollUntilVisible(find.text('Guardar'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Caja grande'), findsOneWidget);
    expect(find.text('Azul'), findsOneWidget);
    expect(find.text('Se editó: nombre, datos adicionales'), findsOneWidget);

    await tester.tap(find.text('Añadir nota'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Cambio de Ubicación');
    await tester.tap(find.text('Guardar nota'));
    await tester.pumpAndSettle();

    expect(find.text('Cambio de Ubicación'), findsOneWidget);
    expect(find.text('4 eventos registrados'), findsOneWidget);
  });

  testWidgets('un enlace a "no encontrado" sin código redirige a escanear', (tester) async {
    await harness.pump(tester, initialLocation: ItemTrackerRoutes.notFound);

    expect(find.widgetWithText(AppBar, 'Escanear'), findsOneWidget);
  });

  testWidgets('la pantalla de escaneo cumple las guías de accesibilidad', (tester) async {
    final semantics = tester.ensureSemantics();
    await harness.pump(tester);
    await openScan(tester);
    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
