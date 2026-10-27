import 'package:core_contracts/core_contracts.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/settings/app_settings.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

import 'helpers/app_harness.dart';

void main() {
  late AppHarness harness;

  tearDown(() => harness.dispose());

  Future<void> openSettings(WidgetTester tester, {String tooltip = 'Configuración'}) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  Future<void> openCatalog(WidgetTester tester, {String settings = 'Configuración', String modules = 'Módulos'}) async {
    await openSettings(tester, tooltip: settings);
    await tester.tap(find.widgetWithText(ListTile, modules));
    await tester.pumpAndSettle();
  }

  ThemeMode themeMode(WidgetTester tester) => tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

  group('dashboard', () {
    testWidgets('muestra las tarjetas de los plugins activos en su orden', (WidgetTester tester) async {
      harness = AppHarness(extraPlugins: <FakeHomePlugin>[FakeHomePlugin('notas')]);
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

    testWidgets('un plugin que falla muestra una tarjeta de error sin bloquear a los demás', (
      WidgetTester tester,
    ) async {
      final FakeHomePlugin failing = FakeHomePlugin('notas', failOnInitialize: true);
      harness = AppHarness(extraPlugins: <FakeHomePlugin>[failing]);
      await harness.pump(tester);

      expect(find.text('No se pudo iniciar «Módulo notas».'), findsOneWidget);
      expect(find.text('Seguimiento de Objetos'), findsOneWidget);

      failing.failOnInitialize = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Tarjeta notas'), findsOneWidget);
    });

    testWidgets('sin plugins activos ofrece abrir el catálogo', (WidgetTester tester) async {
      harness = AppHarness();
      await harness.plugins.load();
      await harness.plugins.setEnabled(ItemTrackerPlugin.pluginId, enabled: false);
      await harness.pump(tester);

      expect(find.text('No hay módulos activos'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Módulos'));
      await tester.pumpAndSettle();
      expect(find.text('Activa o desactiva los módulos. Al desactivar uno, sus datos se conservan.'), findsOneWidget);
    });

    testWidgets('las tarjetas abren las rutas de su plugin', (WidgetTester tester) async {
      harness = AppHarness();
      await harness.pump(tester);

      await tester.tap(find.text('Escanear'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Escanear'), findsOneWidget);
    });
  });

  group('accesos rápidos', () {
    Future<void> toggleLayout(WidgetTester tester, String tooltip) async {
      await tester.tap(find.byTooltip(tooltip));
      await tester.pumpAndSettle();
    }

    List<String> shortcutLabels(WidgetTester tester) => <String>[
          for (final AppShortcutTile tile in tester.widgetList<AppShortcutTile>(find.byType(AppShortcutTile)))
            tile.label,
        ];

    Future<List<UserPluginPreference>> savedPreferences() async =>
        (await harness.preferences.getAll()).toList()
          ..sort((UserPluginPreference a, UserPluginPreference b) => a.pluginId.compareTo(b.pluginId));

    testWidgets('alternar entre lista y grilla no cambia los plugins seleccionados ni su orden', (
      WidgetTester tester,
    ) async {
      harness = AppHarness(
        extraPlugins: <FakeHomePlugin>[FakeHomePlugin('notas'), FakeHomePlugin('fotos'), FakeHomePlugin('oculto')],
      );
      await harness.plugins.load();
      await harness.plugins.setEnabled('oculto', enabled: false);
      await harness.plugins.moveDashboardTile(0, 2); // item_tracker pasa al final.
      await harness.pump(tester);

      final List<String> dashboard = <String>[for (final PluginState tile in harness.plugins.dashboard) tile.plugin.id];
      final List<UserPluginPreference> preferences = await savedPreferences();
      expect(dashboard, <String>['notas', 'fotos', ItemTrackerPlugin.pluginId]);

      await toggleLayout(tester, 'Ver como accesos rápidos');
      expect(shortcutLabels(tester), <String>['Módulo notas', 'Módulo fotos', 'Seguimiento de Objetos', 'Añadir']);
      expect(find.text('Tarjeta notas'), findsNothing);
      expect(harness.settingsRepository.saved.homeLayout, HomeLayout.grid);

      await toggleLayout(tester, 'Ver como lista');
      expect(find.byType(AppShortcutTile), findsNothing);
      expect(
        tester.getTopLeft(find.text('Tarjeta notas')).dy,
        lessThan(tester.getTopLeft(find.text('Tarjeta fotos')).dy),
      );
      expect(harness.settingsRepository.saved.homeLayout, HomeLayout.list);

      expect(<String>[for (final PluginState tile in harness.plugins.dashboard) tile.plugin.id], dashboard);
      expect(await savedPreferences(), preferences);
    });

    testWidgets('la vista elegida se recuerda al reabrir la app', (WidgetTester tester) async {
      harness = AppHarness();
      await harness.pump(tester);
      await toggleLayout(tester, 'Ver como accesos rápidos');
      final AppSettings saved = harness.settingsRepository.saved;
      await tester.pumpWidget(const SizedBox());
      await harness.dispose();

      harness = AppHarness(savedSettings: saved);
      await harness.pump(tester);

      expect(shortcutLabels(tester), <String>['Seguimiento de Objetos', 'Añadir']);
      expect(find.byTooltip('Ver como lista'), findsOneWidget);
    });

    testWidgets('sin plugins activos solo muestra «Añadir», que abre el catálogo, junto al menú superior', (
      WidgetTester tester,
    ) async {
      harness = AppHarness(savedSettings: const AppSettings(homeLayout: HomeLayout.grid));
      await harness.plugins.load();
      await harness.plugins.setEnabled(ItemTrackerPlugin.pluginId, enabled: false);
      await harness.pump(tester);

      expect(shortcutLabels(tester), <String>['Añadir']);
      expect(find.byTooltip('Configuración'), findsOneWidget);
      expect(find.byTooltip('Ver como lista'), findsOneWidget);

      await tester.tap(find.text('Añadir'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Módulos'), findsOneWidget);
    });

    testWidgets('un título largo se corta en dos líneas', (WidgetTester tester) async {
      const String id = 'inventario_de_herramientas_del_garaje_y_del_jardín';
      harness = AppHarness(
        extraPlugins: <FakeHomePlugin>[FakeHomePlugin(id)],
        savedSettings: const AppSettings(homeLayout: HomeLayout.grid),
      );
      await harness.pump(tester);

      expect(tester.takeException(), isNull);
      expect(tester.renderObject<RenderParagraph>(find.text('Módulo $id')).didExceedMaxLines, isTrue);
    });

    testWidgets('tocar un plugin abre su tarjeta en una hoja con todas sus acciones', (WidgetTester tester) async {
      harness = AppHarness(savedSettings: const AppSettings(homeLayout: HomeLayout.grid));
      await harness.pump(tester);

      await tester.tap(find.text('Seguimiento de Objetos'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Escanear'), findsOneWidget);

      await tester.tap(find.text('Ver objetos'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Objetos'), findsOneWidget);
    });

    testWidgets('un plugin que falló se ve con error y al tocarlo reintenta', (WidgetTester tester) async {
      final FakeHomePlugin failing = FakeHomePlugin('notas', failOnInitialize: true);
      harness = AppHarness(
        extraPlugins: <FakeHomePlugin>[failing],
        savedSettings: const AppSettings(homeLayout: HomeLayout.grid),
      );
      await harness.pump(tester);

      AppShortcutTile notes() => tester.widget<AppShortcutTile>(find.widgetWithText(AppShortcutTile, 'Módulo notas'));
      expect(notes().error, isTrue);
      expect(notes().tooltip, 'No se pudo iniciar «Módulo notas».');

      failing.failOnInitialize = false;
      await tester.tap(find.text('Módulo notas'));
      await tester.pumpAndSettle();
      expect(notes().error, isFalse);
      expect(failing.initializeCalls, 2);
    });

    for (final (String name, AppThemePreference theme) in <(String, AppThemePreference)>[
      ('claro', AppThemePreference.light),
      ('oscuro', AppThemePreference.dark),
    ]) {
      testWidgets('tema $name: la grilla cumple las guías de accesibilidad', (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        harness = AppHarness(
          extraPlugins: <FakeHomePlugin>[FakeHomePlugin('notas')],
          savedSettings: AppSettings(theme: theme, homeLayout: HomeLayout.grid),
        );
        await harness.pump(tester);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    }
  });

  group('catálogo', () {
    testWidgets('AC-02 (UI): desactivar un plugin lo quita del inicio y libera sus recursos', (
      WidgetTester tester,
    ) async {
      final FakeHomePlugin notes = FakeHomePlugin('notas');
      harness = AppHarness(extraPlugins: <FakeHomePlugin>[notes]);
      await harness.pump(tester);
      await openCatalog(tester);

      expect(find.text('Seguimiento de Objetos'), findsOneWidget);
      expect(find.text('Módulo notas'), findsOneWidget);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Módulo notas'));
      await tester.pumpAndSettle();
      expect(notes.disposeCalls, 1);
      expect(find.textContaining('Desactivado'), findsOneWidget);

      // Catálogo → configuración → inicio.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Tarjeta notas'), findsNothing);
      expect(find.text('Seguimiento de Objetos'), findsOneWidget);
      expect((await harness.preferences.getAll()).single.isEnabled, isFalse);
    });

    testWidgets('un plugin no disponible no se puede activar', (WidgetTester tester) async {
      harness = AppHarness(extraPlugins: <FakeHomePlugin>[FakeHomePlugin('notas', available: false)]);
      await harness.pump(tester);
      await openCatalog(tester);

      final SwitchListTile tile = tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Módulo notas'));
      expect(tile.onChanged, isNull);
      expect(find.textContaining('No disponible en este dispositivo.'), findsOneWidget);
    });

    testWidgets('muestra los nombres traducidos al cambiar de idioma', (WidgetTester tester) async {
      harness = AppHarness();
      await harness.pump(tester);

      harness.localization.setLanguage('en');
      await tester.pumpAndSettle();
      await openCatalog(tester, settings: 'Settings', modules: 'Modules');

      expect(find.widgetWithText(AppBar, 'Modules'), findsOneWidget);
      expect(find.text('Item Tracker'), findsOneWidget);
    });

    testWidgets('sigue el cambio de idioma del sistema con la app abierta', (WidgetTester tester) async {
      harness = AppHarness();
      await harness.pump(tester);
      expect(find.text('Utilidades del Hogar'), findsOneWidget);

      tester.platformDispatcher.localesTestValue = const <Locale>[Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpAndSettle();

      expect(find.text('Home Utilities'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });
  });

  group('configuración', () {
    testWidgets('el engranaje abre la configuración y el tema cambia y se guarda', (WidgetTester tester) async {
      harness = AppHarness();
      await harness.pump(tester);
      expect(themeMode(tester), ThemeMode.system);

      await openSettings(tester);
      expect(find.widgetWithText(AppBar, 'Configuración'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Oscuro'));
      await tester.pumpAndSettle();

      expect(themeMode(tester), ThemeMode.dark);
      expect(harness.settingsRepository.saved.theme, AppThemePreference.dark);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Claro'));
      await tester.pumpAndSettle();
      expect(themeMode(tester), ThemeMode.light);
    });

    testWidgets('arranca con el tema guardado', (WidgetTester tester) async {
      harness = AppHarness(savedSettings: const AppSettings(theme: AppThemePreference.dark));
      await harness.pump(tester);

      expect(themeMode(tester), ThemeMode.dark);
    });

    testWidgets('un idioma fijado ignora los cambios del sistema hasta volver a "Sistema"', (WidgetTester tester) async {
      harness = AppHarness();
      await harness.pump(tester);
      await openSettings(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'English'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
      expect(harness.settingsRepository.saved.languageCode, 'en');

      tester.platformDispatcher.localesTestValue = const <Locale>[Locale('es', 'CO')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'System').last); // El primero es el del tema.
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Configuración'), findsOneWidget);
      expect(harness.settingsRepository.saved.languageCode, isNull);
    });

    testWidgets('abre el catálogo y la exportación aún no está disponible', (WidgetTester tester) async {
      harness = AppHarness();
      await harness.pump(tester);
      await openSettings(tester);

      final ListTile export = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Exportar / importar datos'));
      expect(export.enabled, isFalse);
      expect(find.text('Próximamente'), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, 'Módulos'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Módulos'), findsOneWidget);
    });

    for (final (String name, AppThemePreference theme) in <(String, AppThemePreference)>[
      ('claro', AppThemePreference.light),
      ('oscuro', AppThemePreference.dark),
    ]) {
      testWidgets('tema $name: la configuración cumple las guías de accesibilidad', (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        harness = AppHarness(savedSettings: AppSettings(theme: theme));
        await harness.pump(tester);
        await openSettings(tester);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    }
  });

  group('guard de rutas (§12.3)', () {
    testWidgets('un deep link a un plugin desactivado redirige a inicio con un aviso', (WidgetTester tester) async {
      harness = AppHarness();
      await harness.plugins.load();
      await harness.plugins.setEnabled(ItemTrackerPlugin.pluginId, enabled: false);

      await harness.pump(tester, initialLocation: ItemTrackerRoutes.scan);

      expect(find.widgetWithText(AppBar, 'Escanear'), findsNothing);
      expect(find.text('No hay módulos activos'), findsOneWidget);
      expect(find.text('Ese módulo está desactivado. Actívalo en el catálogo para usarlo.'), findsOneWidget);
    });

    testWidgets('un deep link a un plugin activo se abre normalmente', (WidgetTester tester) async {
      harness = AppHarness();
      await harness.pump(tester, initialLocation: ItemTrackerRoutes.scan);

      expect(find.widgetWithText(AppBar, 'Escanear'), findsOneWidget);
    });

    testWidgets('las rutas de un plugin que falló también se bloquean', (WidgetTester tester) async {
      harness = AppHarness(extraPlugins: <FakeHomePlugin>[FakeHomePlugin('notas', failOnInitialize: true)]);
      await harness.pump(tester, initialLocation: '/notas');

      expect(find.text('Pantalla notas'), findsNothing);
      expect(find.text('Ese módulo no está disponible en este momento.'), findsOneWidget);
    });
  });

  testWidgets('inicio y catálogo cumplen las guías de accesibilidad', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    harness = AppHarness(extraPlugins: <FakeHomePlugin>[FakeHomePlugin('notas')]);
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
