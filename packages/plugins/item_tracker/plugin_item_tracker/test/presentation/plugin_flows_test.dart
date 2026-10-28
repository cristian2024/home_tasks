import 'package:core_hardware/core_hardware.dart';
import 'package:core_hardware/testing.dart';
import 'package:design_system/design_system.dart';
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
    testWidgets('expone su contrato y registra/libera sus dependencias en su scope', (WidgetTester tester) async {
      await harness.pump(tester);
      final ItemTrackerPlugin plugin = harness.plugin;

      expect(plugin.id, 'item_tracker');
      expect(harness.localization.translate(plugin.nameKey), 'Seguimiento de Objetos');
      expect(harness.localization.translate(plugin.descriptionKey), startsWith('Identifica'));
      expect(await plugin.isAvailable(), isTrue);
      expect(harness.locator.hasScope('item_tracker'), isTrue);
      expect(harness.locator.isRegistered<ItemTrackerDependencies>(), isTrue);
      expect(
        harness.locator.get<ItemTrackerDependencies>().containmentPolicy,
        const ContainmentPolicy(maxDepth: ItemTrackerPlugin.configuredMaxDepth),
      );

      await plugin.dispose();
      expect(harness.locator.hasScope('item_tracker'), isFalse);
      expect(harness.locator.isRegistered<ItemTrackerDependencies>(), isFalse);
      await plugin.initialize(); // Para el tearDown.
    });

    testWidgets('el dashboard muestra el número de objetos y abre el listado', (WidgetTester tester) async {
      await harness.createItem('Caja A');
      await harness.pump(tester);

      expect(find.text('1 objeto registrado'), findsOneWidget);

      await tester.tap(find.text('Ver objetos'));
      await tester.pumpAndSettle();
      expect(find.text('Caja A'), findsOneWidget);
    });

    testWidgets('cambia de idioma a través del coordinador', (WidgetTester tester) async {
      await harness.pump(tester);

      harness.localization.setLanguage('en');
      await tester.pumpWidget(Container());
      await harness.pump(tester);
      expect(find.text('Scan'), findsOneWidget);

      harness.localization.setLanguage('es');
    });
  });

  testWidgets('AC-03: escanear un QR conocido abre el detalle del objeto', (WidgetTester tester) async {
    await harness.createItem('Caja A', qr: 'QR-123');
    await harness.pump(tester);
    await openScan(tester);

    expect(find.byKey(FakeCameraScanner.previewKey), findsOneWidget);
    harness.hardware.camera.emit('QR-123');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Caja A'), findsOneWidget);
    expect(find.text('QR-123'), findsOneWidget);
  });

  testWidgets('AC-04: un QR desconocido muestra Crear nuevo y Asociar a existente', (WidgetTester tester) async {
    await harness.pump(tester);
    await openScan(tester);

    harness.hardware.camera.emit('UNKNOWN-99');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Identificador no registrado'), findsOneWidget);
    expect(find.textContaining('UNKNOWN-99'), findsOneWidget);
    expect(find.text('Crear nuevo objeto'), findsOneWidget);
    expect(find.text('Asociar a un objeto existente'), findsOneWidget);
  });

  testWidgets('crear desde un código desconocido asocia el código y abre el detalle', (WidgetTester tester) async {
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

  testWidgets('AC-05: QR y NFC asociados a "Cama" llevan al mismo objeto', (WidgetTester tester) async {
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

  testWidgets('AC-06: sin NFC la opción muestra un mensaje accesible sin errores', (WidgetTester tester) async {
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

  testWidgets('el selector Código oculta la cámara y Cámara oculta el campo', (WidgetTester tester) async {
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

  testWidgets('sin permiso de cámara ofrece concederlo o escribir el código', (WidgetTester tester) async {
    harness = PluginHarness(hardware: FakeHardware(cameraPermission: HardwarePermissionStatus.denied));
    harness.hardware.permissions.statusAfterRequest = HardwarePermissionStatus.granted;
    await harness.pump(tester);
    await openScan(tester);

    expect(find.text('Se necesita la cámara'), findsOneWidget);
    await tester.tap(find.text('Conceder permiso'));
    await tester.pumpAndSettle();

    expect(find.byKey(FakeCameraScanner.previewKey), findsOneWidget);
  });

  testWidgets('desde el detalle se edita el objeto y se añade una nota', (WidgetTester tester) async {
    final HouseholdItem item = await harness.createItem('Caja A', qr: 'QR-123');
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
    await tester.scrollUntilVisible(
      find.text('Se editó: nombre, datos adicionales'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Se editó: nombre, datos adicionales'), findsOneWidget);

    await tester.tap(find.text('Añadir nota'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Cambio de Ubicación');
    await tester.tap(find.text('Guardar nota'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Cambio de Ubicación'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Cambio de Ubicación'), findsOneWidget);
    expect(find.text('4 eventos registrados'), findsOneWidget);
  });

  group('añadir identificador desde el objeto', () {
    testWidgets('desde el detalle: la cámara asocia el código y vuelve al detalle', (WidgetTester tester) async {
      final HouseholdItem item = await harness.createItem('Cama', qr: 'QR-BED');
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.detail(item.id));

      await tester.tap(find.text('Añadir identificador'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Añadir identificador'), findsOneWidget);

      harness.hardware.camera.emit('QR-PILLOW');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Cama'), findsOneWidget);
      expect(find.text('Identificador añadido.'), findsOneWidget);
      expect(find.text('QR-PILLOW'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('QR asociado: QR-PILLOW'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('QR asociado: QR-PILLOW'), findsOneWidget);
      expect(harness.hardware.camera.isDisposed, isTrue);
    });

    testWidgets('desde la edición: el código escrito se asocia sin guardar el formulario', (
      WidgetTester tester,
    ) async {
      final HouseholdItem item = await harness.createItem('Cama');
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.edit(item.id));

      await tester.tap(find.text('Añadir identificador'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Código'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Código'), 'TAG-1');
      await tester.tap(find.text('NFC').last); // El primero es el selector de modo.
      await tester.tap(find.text('Asociar'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Editar objeto'), findsOneWidget);
      expect(find.text('Identificador añadido.'), findsOneWidget);
      final PhysicalIdentifier? found = await harness.repository.findIdentifier('TAG-1', IdentifierType.nfc);
      expect(found?.itemId, item.id);
    });

    testWidgets('un código de otro objeto se rechaza y se sigue escaneando', (WidgetTester tester) async {
      await harness.createItem('Mesa', qr: 'QR-TABLE');
      final HouseholdItem item = await harness.createItem('Cama', qr: 'QR-BED');
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.addIdentifier(item.id));

      harness.hardware.camera.emit('QR-TABLE');
      await tester.pumpAndSettle();
      expect(find.text('Este identificador ya está asociado a «Mesa».'), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Añadir identificador'), findsOneWidget);
      expect(harness.hardware.camera.isScanning, isTrue);

      harness.hardware.camera.emit('QR-BED');
      await tester.pumpAndSettle();
      expect(find.text('Este identificador ya está asociado a este objeto.'), findsOneWidget);
    });
  });

  testWidgets('quitar un identificador pide confirmación y lo deja libre para otro objeto', (
    WidgetTester tester,
  ) async {
    final HouseholdItem item = await harness.createItem('Cama', qr: 'QR-BED');
    await harness.pump(tester, initialLocation: ItemTrackerRoutes.detail(item.id));

    await tester.tap(find.byTooltip('Quitar QR QR-BED'));
    await tester.pumpAndSettle();
    expect(find.text('¿Quitar el identificador?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('QR-BED'), findsOneWidget);

    await tester.tap(find.byTooltip('Quitar QR QR-BED'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    expect(find.text('Identificador quitado.'), findsOneWidget);
    expect(find.text('Sin identificadores asociados.'), findsOneWidget);
    expect(find.text('QR quitado: QR-BED'), findsOneWidget);

    final HouseholdItem other = await harness.createItem('Mesa', qr: 'QR-BED');
    expect((await harness.repository.findIdentifier('QR-BED', IdentifierType.qr))?.itemId, other.id);
  });

  group('contenedores', () {
    Finder scrollable() => find.byType(Scrollable).first;

    testWidgets('"Añadir objeto aquí" crea el objeto dentro y aparece en el contenido', (WidgetTester tester) async {
      final HouseholdItem furniture = await harness.createItem('Mueble');
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.detail(furniture.id));
      expect(find.text('No está dentro de ningún objeto.'), findsOneWidget);
      expect(find.text('No contiene ningún objeto.'), findsOneWidget);
      expect(find.text('Sacar del contenedor'), findsNothing);

      await tester.tap(find.text('Añadir objeto aquí'));
      await tester.pumpAndSettle();
      expect(find.text('Se creará dentro de: Mueble'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Organizador');
      await tester.scrollUntilVisible(find.text('Guardar'), 200, scrollable: scrollable());
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Mueble'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Organizador'), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, 'Organizador'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Organizador'), findsOneWidget);
      // La ruta lleva de vuelta al contenedor.
      await tester.tap(find.byTooltip('Abrir «Mueble»'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Mueble'), findsOneWidget);
    });

    testWidgets('"Mover a…" excluye el contenido, marca el contenedor actual y mueve el objeto', (
      WidgetTester tester,
    ) async {
      final HouseholdItem furniture = await harness.createItem('Mueble');
      final HouseholdItem organizer = await harness.createItem('Organizador', parentId: furniture.id);
      await harness.createItem('Cajón', parentId: organizer.id);
      await harness.createItem('Caja');
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.detail(organizer.id));

      await tester.tap(find.text('Mover a…'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Mover «Organizador»'), findsOneWidget);
      expect(find.text('Cajón'), findsNothing);
      expect(find.text('Ya está aquí'), findsOneWidget);

      await tester.tap(find.text('Mueble')); // Desactivado: no hace nada.
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Mover «Organizador»'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Buscar contenedor por nombre'), 'caj');
      await tester.pumpAndSettle();
      expect(find.text('Mueble'), findsNothing);
      await tester.tap(find.text('Caja'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Organizador'), findsOneWidget);
      expect(find.text('Movido a «Caja».'), findsOneWidget);
      expect(find.byTooltip('Abrir «Caja»'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Movido a «Caja»'), 200, scrollable: scrollable());
      expect(find.text('Movido a «Caja»'), findsOneWidget);
    });

    testWidgets('sacar del contenedor pide confirmación', (WidgetTester tester) async {
      final HouseholdItem box = await harness.createItem('Caja');
      final HouseholdItem scissors = await harness.createItem('Tijeras', parentId: box.id);
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.detail(scissors.id));

      await tester.tap(find.text('Sacar del contenedor'));
      await tester.pumpAndSettle();
      expect(find.text('¿Sacar del contenedor?'), findsOneWidget);
      await tester.tap(find.text('Sacar'));
      await tester.pumpAndSettle();

      expect(find.text('Sacado de «Caja».'), findsOneWidget);
      expect(find.text('No está dentro de ningún objeto.'), findsOneWidget);
      expect((await harness.repository.getById(scissors.id))!.parentId, isNull);
    });

    testWidgets('con un límite bajo bloquea los destinos y avisa del contenedor desbordado', (
      WidgetTester tester,
    ) async {
      await harness.dispose();
      harness = PluginHarness(maxContainmentDepth: 2);
      final HouseholdItem furniture = await harness.createItem('Mueble');
      final HouseholdItem organizer = await harness.createItem('Organizador', parentId: furniture.id);
      final HouseholdItem drawer = await harness.createItem('Cajón');
      await harness.createItem('Caja');
      // Quedó en el nivel 3 antes de bajar el límite.
      await harness.repository.moveItem(drawer.copyWith(parentId: () => organizer.id), const <ItemEvent>[]);
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.detail(organizer.id));

      expect(
        find.text('Este objeto está en el nivel 2 y el máximo es 2: lo que contiene supera el límite. Muévelo o sácalo.'),
        findsOneWidget,
      );
      expect(tester.widget<AppButton>(find.widgetWithText(AppButton, 'Añadir objeto aquí')).onPressed, isNull);

      await tester.tap(find.text('Mover a…'));
      await tester.pumpAndSettle();
      // El organizador ocupa 2 niveles: no cabe dentro de la caja.
      expect(find.text('Ya está aquí'), findsOneWidget);
      expect(find.text('Superaría el máximo de 2 niveles'), findsOneWidget);
    });

    testWidgets('la lista muestra la ruta de los objetos que están dentro de otros', (WidgetTester tester) async {
      final HouseholdItem furniture = await harness.createItem('Mueble');
      final HouseholdItem organizer = await harness.createItem('Organizador', parentId: furniture.id);
      await harness.createItem('Cajón', parentId: organizer.id);
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.items);

      expect(find.text('Mueble › Organizador'), findsOneWidget);
      expect(find.text('Mueble'), findsWidgets);
      await tester.enterText(find.widgetWithText(TextField, 'Buscar por nombre'), 'caj');
      await tester.pumpAndSettle();
      expect(find.text('Cajón'), findsOneWidget);
      expect(find.text('Mueble › Organizador'), findsOneWidget);
    });

    testWidgets('el detalle y "Mover a…" cumplen las guías de accesibilidad', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final HouseholdItem box = await harness.createItem('Caja');
      final HouseholdItem scissors = await harness.createItem('Tijeras', parentId: box.id);
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.detail(scissors.id));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.tap(find.text('Mover a…'));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  });

  testWidgets('un enlace a "no encontrado" sin código redirige a escanear', (WidgetTester tester) async {
    await harness.pump(tester, initialLocation: ItemTrackerRoutes.notFound);

    expect(find.widgetWithText(AppBar, 'Escanear'), findsOneWidget);
  });

  testWidgets('la pantalla de escaneo cumple las guías de accesibilidad', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
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
