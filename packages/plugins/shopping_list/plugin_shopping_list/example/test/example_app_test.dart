import 'package:core_di/core_di.dart';
import 'package:core_share/core_share.dart';
import 'package:core_share/testing.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:plugin_shopping_list/testing.dart';
import 'package:shopping_list_example/src/example_app.dart';

void main() {
  testWidgets('carga los datos de ejemplo y abre la lista', (WidgetTester tester) async {
    // Como los adaptadores, pero en memoria.
    final ServiceLocator locator = ServiceLocator()
      ..registerSingleton<ShoppingListRepository>(InMemoryShoppingListRepository())
      ..registerSingleton<ShareService>(FakeShareService());
    final LocalizationCoordinator localization = LocalizationCoordinator();
    final ShoppingListPlugin plugin = ShoppingListPlugin(locator: locator, localization: localization);
    await plugin.initialize();
    addTearDown(locator.reset);

    await tester.pumpWidget(ShoppingListExampleApp(plugin: plugin, locator: locator, localization: localization));
    await tester.pumpAndSettle();
    expect(find.text('No hay nada por comprar'), findsOneWidget);

    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pumpAndSettle();
    expect(find.text('Datos de ejemplo cargados: 6 items.'), findsOneWidget);
    expect(find.text('6 cosas por comprar'), findsOneWidget);
    expect(find.text('2 urgentes'), findsOneWidget);

    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pumpAndSettle();
    expect(find.text('Los datos de ejemplo ya estaban cargados.'), findsOneWidget);

    await tester.tap(find.text('Lista de compras'));
    await tester.pumpAndSettle();
    expect(find.text('Papel higiénico'), findsOneWidget);
    expect(find.byTooltip('Exportar'), findsOneWidget);

    await plugin.dispose();
  });
}
