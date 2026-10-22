import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

import 'helpers/app_harness.dart';

void main() {
  late AppHarness harness;

  tearDown(() => harness.dispose());

  Future<void> openCatalog(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Módulos'));
    await tester.pumpAndSettle();
  }

  group('dashboard', () {
    testWidgets('muestra las tarjetas de los plugins activos en su orden', (tester) async {
      harness = AppHarness(extraPlugins: [FakeHomePlugin('notas')]);
      await harness.pump(tester);

      expect(find.text('Utilidades del Hogar'), findsOneWidget);
      expect(find.text('Seguimiento de Objetos'), findsOneWidget);
      expect(find.text('Tarjeta notas'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Seguimiento de Objetos')).dy,
        lessThan(tester.getTopLeft(find.text('Tarjeta notas')).dy),
      );

      await harness.plugins.moveDashboardTile(1, 0);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Tarjeta notas')).dy,
        lessThan(tester.getTopLeft(find.text('Seguimiento de Objetos')).dy),
      );
    });

    testWidgets('un plugin que falla muestra una tarjeta de error sin bloquear a los demás', (tester) async {
      final failing = FakeHomePlugin('notas', failOnInitialize: true);
      harness = AppHarness(extraPlugins: [failing]);
      await harness.pump(tester);

      expect(find.text('No se pudo iniciar «Módulo notas».'), findsOneWidget);
      expect(find.text('Seguimiento de Objetos'), findsOneWidget);

      failing.failOnInitialize = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Tarjeta notas'), findsOneWidget);
    });

    testWidgets('sin plugins activos ofrece abrir el catálogo', (tester) async {
      harness = AppHarness();
      await harness.plugins.load();
      await harness.plugins.setEnabled(ItemTrackerPlugin.pluginId, enabled: false);
      await harness.pump(tester);

      expect(find.text('No hay módulos activos'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Módulos'));
      await tester.pumpAndSettle();
      expect(find.text('Activa o desactiva los módulos. Al desactivar uno, sus datos se conservan.'), findsOneWidget);
    });

    testWidgets('las tarjetas abren las rutas de su plugin', (tester) async {
      harness = AppHarness();
      await harness.pump(tester);

      await tester.tap(find.text('Escanear'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Escanear'), findsOneWidget);
    });
  });

  group('catálogo', () {
    testWidgets('AC-02 (UI): desactivar un plugin lo quita del inicio y libera sus recursos', (tester) async {
      final notes = FakeHomePlugin('notas');
      harness = AppHarness(extraPlugins: [notes]);
      await harness.pump(tester);
      await openCatalog(tester);

      expect(find.text('Seguimiento de Objetos'), findsOneWidget);
      expect(find.text('Módulo notas'), findsOneWidget);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Módulo notas'));
      await tester.pumpAndSettle();
      expect(notes.disposeCalls, 1);
      expect(find.textContaining('Desactivado'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Tarjeta notas'), findsNothing);
      expect(find.text('Seguimiento de Objetos'), findsOneWidget);
      expect((await harness.preferences.getAll()).single.isEnabled, isFalse);
    });

    testWidgets('un plugin no disponible no se puede activar', (tester) async {
      harness = AppHarness(extraPlugins: [FakeHomePlugin('notas', available: false)]);
      await harness.pump(tester);
      await openCatalog(tester);

      final tile = tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Módulo notas'));
      expect(tile.onChanged, isNull);
      expect(find.textContaining('No disponible en este dispositivo.'), findsOneWidget);
    });

    testWidgets('muestra los nombres traducidos al cambiar de idioma', (tester) async {
      harness = AppHarness();
      await harness.pump(tester);

      harness.localization.setLanguage('en');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Modules'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Modules'), findsOneWidget);
      expect(find.text('Item Tracker'), findsOneWidget);
    });

    testWidgets('sigue el cambio de idioma del sistema con la app abierta', (tester) async {
      harness = AppHarness();
      await harness.pump(tester);
      expect(find.text('Utilidades del Hogar'), findsOneWidget);

      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpAndSettle();

      expect(find.text('Home Utilities'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });
  });

  group('guard de rutas (§12.3)', () {
    testWidgets('un deep link a un plugin desactivado redirige a inicio con un aviso', (tester) async {
      harness = AppHarness();
      await harness.plugins.load();
      await harness.plugins.setEnabled(ItemTrackerPlugin.pluginId, enabled: false);

      await harness.pump(tester, initialLocation: ItemTrackerRoutes.scan);

      expect(find.widgetWithText(AppBar, 'Escanear'), findsNothing);
      expect(find.text('No hay módulos activos'), findsOneWidget);
      expect(find.text('Ese módulo está desactivado. Actívalo en el catálogo para usarlo.'), findsOneWidget);
    });

    testWidgets('un deep link a un plugin activo se abre normalmente', (tester) async {
      harness = AppHarness();
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.scan);

      expect(find.widgetWithText(AppBar, 'Escanear'), findsOneWidget);
    });

    testWidgets('las rutas de un plugin que falló también se bloquean', (tester) async {
      harness = AppHarness(extraPlugins: [FakeHomePlugin('notas', failOnInitialize: true)]);
      await harness.pump(tester, initialLocation: '/notas');

      expect(find.text('Pantalla notas'), findsNothing);
      expect(find.text('Ese módulo no está disponible en este momento.'), findsOneWidget);
    });
  });

  testWidgets('inicio y catálogo cumplen las guías de accesibilidad', (tester) async {
    final semantics = tester.ensureSemantics();
    harness = AppHarness(extraPlugins: [FakeHomePlugin('notas')]);
    await harness.pump(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await openCatalog(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
