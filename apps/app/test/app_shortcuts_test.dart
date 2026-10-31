import 'package:core_app_shortcuts/core_app_shortcuts.dart';
import 'package:core_app_shortcuts/testing.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/i18n/strings.g.dart' as app_i18n;
import 'package:home_utility_app/shortcuts/app_shortcut_defaults.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';

import 'helpers/app_harness.dart';

/// Plugin falso con pantalla principal.
class _EntryPlugin extends FakeHomePlugin implements HomePluginEntryRoute {
  _EntryPlugin(super.id);

  @override
  String get entryRoute => route;
}

void main() {
  late FakeAppShortcutService shortcuts;

  setUp(() => shortcuts = FakeAppShortcutService());
  tearDown(() => shortcuts.dispose());

  AppHarness harness({List<HomePlugin> extraPlugins = const <HomePlugin>[]}) =>
      AppHarness(includeShoppingList: true, extraPlugins: extraPlugins, shortcuts: shortcuts);

  List<String> ids() => shortcuts.shortcuts.map((AppShortcut shortcut) => shortcut.id).toList();

  testWidgets('publica los plugins del inicio con pantalla principal, en su orden', (WidgetTester tester) async {
    final AppHarness app = harness(extraPlugins: <HomePlugin>[FakeHomePlugin('notas'), _EntryPlugin('agenda')]);
    await app.pump(tester);

    final List<String> expected = app.plugins.dashboard
        .map((PluginState state) => state.plugin.id)
        .where((String id) => id == ShoppingListPlugin.pluginId || id == 'agenda')
        .toList();
    expect(ids(), expected);
    expect(
      shortcuts.shortcuts.firstWhere((AppShortcut shortcut) => shortcut.id == ShoppingListPlugin.pluginId),
      AppShortcut(
        id: ShoppingListPlugin.pluginId,
        title: app.localization.translate('shoppingList.title'),
        iconName: AppShortcutDefaults.icons[ShoppingListPlugin.pluginId],
      ),
    );
    await app.dispose();
  });

  testWidgets('publica como mucho maxShortcuts accesos', (WidgetTester tester) async {
    final AppHarness app = harness(extraPlugins: <HomePlugin>[
      for (int i = 0; i < AppShortcutDefaults.maxShortcuts + 1; i++) _EntryPlugin('modulo$i'),
    ]);
    await app.pump(tester);

    expect(shortcuts.shortcuts, hasLength(AppShortcutDefaults.maxShortcuts));
    await app.dispose();
  });

  testWidgets('al desactivar y activar un plugin se vuelven a publicar', (WidgetTester tester) async {
    final AppHarness app = harness(extraPlugins: <HomePlugin>[_EntryPlugin('agenda')]);
    await app.pump(tester);

    await app.plugins.setEnabled(ShoppingListPlugin.pluginId, enabled: false);
    await tester.pump();
    expect(ids(), <String>['agenda']);

    await app.plugins.setEnabled(ShoppingListPlugin.pluginId, enabled: true);
    await tester.pump();
    expect(ids(), contains(ShoppingListPlugin.pluginId));
    await app.dispose();
  });

  testWidgets('al cambiar de idioma se vuelven a publicar con los títulos traducidos', (WidgetTester tester) async {
    final AppHarness app = harness();
    await app.pump(tester);
    final String spanish = shortcuts.shortcuts.single.title;

    app.localization.setLanguage('en');
    await tester.pumpAndSettle();

    expect(shortcuts.shortcuts.single.title, app.localization.translate('shoppingList.title'));
    expect(shortcuts.shortcuts.single.title, isNot(spanish));
    await app.dispose();
  });

  testWidgets('no vuelve a publicar si los accesos no cambian', (WidgetTester tester) async {
    final AppHarness app = harness(extraPlugins: <HomePlugin>[FakeHomePlugin('notas')]);
    await app.pump(tester);
    final int updates = shortcuts.updates;

    await app.plugins.setEnabled('notas', enabled: false);
    await tester.pump();

    expect(shortcuts.updates, updates);
    await app.dispose();
  });

  testWidgets('pulsar un acceso abre la pantalla principal del plugin', (WidgetTester tester) async {
    final AppHarness app = harness(extraPlugins: <HomePlugin>[_EntryPlugin('agenda')]);
    await app.pump(tester);

    shortcuts.simulateSelection('agenda');
    await tester.pumpAndSettle();

    expect(find.text('Pantalla agenda'), findsOneWidget);
    await app.dispose();
  });

  testWidgets('el acceso que abrió la app en frío se abre al montar el router', (WidgetTester tester) async {
    final AppHarness app = harness(extraPlugins: <HomePlugin>[_EntryPlugin('agenda')]);
    shortcuts.simulateSelection('agenda');

    await app.pump(tester);

    expect(find.text('Pantalla agenda'), findsOneWidget);
    await app.dispose();
  });

  testWidgets('el acceso de un plugin desactivado lleva al inicio con un aviso', (WidgetTester tester) async {
    final AppHarness app = harness(extraPlugins: <HomePlugin>[_EntryPlugin('agenda')]);
    await app.pump(tester);
    await app.plugins.setEnabled('agenda', enabled: false);
    await tester.pumpAndSettle();

    shortcuts.simulateSelection('agenda');
    await tester.pumpAndSettle();

    expect(find.text('Pantalla agenda'), findsNothing);
    expect(find.text(app_i18n.appStrings.app.guard.pluginDisabled), findsOneWidget);
    await app.dispose();
  });

  testWidgets('ignora el acceso de un plugin desconocido o sin pantalla principal', (WidgetTester tester) async {
    final AppHarness app = harness(extraPlugins: <HomePlugin>[FakeHomePlugin('notas')]);
    await app.pump(tester);

    shortcuts
      ..simulateSelection('desconocido')
      ..simulateSelection('notas');
    await tester.pumpAndSettle();

    expect(find.text('Pantalla notas'), findsNothing);
    expect(tester.takeException(), isNull);
    await app.dispose();
  });

  testWidgets('tras dispose deja de publicar', (WidgetTester tester) async {
    final AppHarness app = harness();
    await app.pump(tester);
    final int updates = shortcuts.updates;

    app.environment.shortcuts!.dispose();
    app.localization.setLanguage('en');
    await tester.pumpAndSettle();

    expect(shortcuts.updates, updates);
    await app.dispose();
  });
}
