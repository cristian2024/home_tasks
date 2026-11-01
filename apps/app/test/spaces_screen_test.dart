import 'package:core_sync/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/i18n/strings.g.dart';
import 'package:home_utility_app/spaces/bring_data_dialog.dart';
import 'package:home_utility_app/spaces/space_switcher.dart';
import 'package:home_utility_app/spaces/spaces_cubit.dart';
import 'package:home_utility_app/spaces/spaces_screen.dart';
import 'package:storage_isar/adapter.dart' show Isar;

import 'helpers/space_phone.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('el diálogo devuelve llevar, empezar vacío o nada', (WidgetTester tester) async {
    final List<bool?> answers = <bool?>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async => answers.add(await showBringDataDialog(context, spaceName: 'Casa')),
          child: const Text('abrir'),
        ),
      ),
    ));
    final AppTranslations$app$spaces$es t = appStrings.app.spaces;

    for (final String button in <String>[t.bringConfirm, t.startEmpty, t.cancel]) {
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text(t.bringTitle(name: 'Casa')), findsOneWidget);
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
    }

    expect(answers, <bool?>[true, false, null]);
  });

  testWidgets('la pantalla lista los espacios, marca el abierto y solo deja borrar los demás', (WidgetTester tester) async {
    final SpacePhone ana = SpacePhone('ana', network: InMemorySyncNetwork());
    late SpacesCubit cubit;
    await tester.runAsync(() async {
      final SpaceSwitcher switcher = await ana.start();
      await switcher.createSpace(name: 'Oficina');
      cubit = SpacesCubit(switcher);
    });
    final AppTranslations$app$spaces$es t = appStrings.app.spaces;

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<SpacesCubit>.value(value: cubit, child: const SpacesScreen()),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(find.text('Mi espacio'), findsOneWidget);
    expect(find.text('Oficina'), findsOneWidget);
    expect(find.text('${t.local} · ${t.active}'), findsOneWidget);
    expect(find.byTooltip(t.delete(name: 'Oficina')), findsOneWidget);
    expect(find.byTooltip(t.delete(name: 'Mi espacio')), findsNothing);

    await tester.tap(find.byTooltip(t.delete(name: 'Oficina')));
    await tester.pumpAndSettle();
    expect(find.text(t.deleteTitle(name: 'Oficina')), findsOneWidget);
    await tester.tap(find.text(t.cancel));
    await tester.pumpAndSettle();

    // Crear pide el nombre antes; al cancelar no se crea nada.
    await tester.tap(find.text(t.create));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, t.createTitle), findsOneWidget);
    expect(find.widgetWithText(TextField, t.newSpaceName(n: 3)), findsOneWidget);
    await tester.tap(find.text(t.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(cubit.state.spaces, hasLength(2));

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await cubit.close();
      await ana.dispose();
    });
  });
}
