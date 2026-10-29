import 'dart:io';

import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/app.dart';
import 'package:home_utility_app/bootstrap.dart';
import 'package:integration_test/integration_test.dart';
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shopping_list_isar/shopping_list_isar.dart';
import 'package:storage_isar/storage_isar.dart';

/// Criterios de aceptación en un dispositivo o emulador, con Isar y el
/// arranque reales:
///
///     cd apps/app && flutter test integration_test
///
/// Usa el modo «Código» del escáner para no depender de la cámara.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;

  setUp(() async {
    final Directory temp = await getTemporaryDirectory();
    directory = Directory('${temp.path}/ac_${DateTime.now().microsecondsSinceEpoch}')..createSync();
  });

  tearDown(() => directory.deleteSync(recursive: true));

  Future<AppEnvironment> start(WidgetTester tester) async {
    final AppEnvironment app = await bootstrapApp(
      adapters: <DependencyModule>[
        IsarStorage(
          directory: directory.path,
          features: const <IsarFeature>[ItemTrackerIsar(), ShoppingListIsar()],
        ),
      ],
      systemLanguageCode: 'es',
      locator: ServiceLocator(),
      localization: LocalizationCoordinator(),
    );
    // Una key por entorno: simula un arranque nuevo de la app.
    await tester.pumpWidget(HomeUtilityApp(key: ObjectKey(app), environment: app));
    await tester.pumpAndSettle();
    return app;
  }

  testWidgets('AC-01, AC-04 y AC-02: registro, código desconocido y desactivación persistente', (
    WidgetTester tester,
  ) async {
    AppEnvironment app = await start(tester);

    // AC-01: el plugin está registrado y su tarjeta aparece en inicio.
    expect(app.registry.getPlugin('item_tracker'), isNotNull);
    expect(find.text('Seguimiento de Objetos'), findsOneWidget);

    // AC-04: un código desconocido ofrece crear o asociar; se crea el objeto.
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'UNKNOWN-99');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('Crear nuevo objeto'), findsOneWidget);
    expect(find.text('Asociar a un objeto existente'), findsOneWidget);

    await tester.tap(find.text('Crear nuevo objeto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Caja A');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Caja A'), findsOneWidget);

    // AC-02: desactivar desde el catálogo…
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Módulos'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Seguimiento de Objetos'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Lista de compras'));
    await tester.pumpAndSettle();

    // …y reiniciar la app.
    await app.dispose();
    app = await start(tester);
    expect(find.text('No hay módulos activos'), findsOneWidget);

    // Los datos siguen ahí: al reactivarlo, el objeto se encuentra por su código.
    await app.plugins.setEnabled('item_tracker', enabled: true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'UNKNOWN-99');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Caja A'), findsOneWidget);

    await app.dispose();
  });
}
