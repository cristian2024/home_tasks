import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {ThemeData? theme, double textScale = 1}) => MaterialApp(
      theme: theme ?? AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    );

Widget gallery() => ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        const AppSectionHeader('Sección'),
        AppButton(label: 'Guardar', onPressed: () {}),
        AppButton(label: 'Secundario', icon: Icons.add, variant: AppButtonVariant.secondary, onPressed: () {}),
        AppButton(label: 'Texto', variant: AppButtonVariant.text, onPressed: () {}),
        AppIconButton(icon: Icons.delete, tooltip: 'Eliminar', onPressed: () {}),
        AppIconButton(icon: Icons.add, tooltip: 'Añadir', variant: AppIconButtonVariant.filled, onPressed: () {}),
        const AppTextField(label: 'Nombre'),
        AppCard(semanticLabel: 'Caja A', onTap: () {}, child: const Text('Caja A')),
        SizedBox(
          height: 240,
          child: AppShortcutGrid(
            children: <Widget>[
              AppShortcutTile(icon: Icons.qr_code_scanner, label: 'Objetos', onTap: () {}),
              AppShortcutTile(label: 'Falló', error: true, tooltip: 'No se pudo iniciar', onTap: () {}),
              AppShortcutTile(icon: Icons.add, label: 'Añadir', onTap: () {}),
            ],
          ),
        ),
        AppSettingsSection(
          title: 'Ajustes',
          children: <Widget>[
            AppChoiceSelector<String>(
              label: 'Tema',
              icon: Icons.palette_outlined,
              options: const <AppChoice<String>>[
                AppChoice<String>(value: 'system', label: 'Sistema'),
                AppChoice<String>(value: 'light', label: 'Claro'),
                AppChoice<String>(value: 'dark', label: 'Oscuro'),
              ],
              selected: 'system',
              onChanged: (String _) {},
            ),
            AppSettingsTile(icon: Icons.extension_outlined, title: 'Módulos', onTap: () {}),
            const AppSettingsTile(
              icon: Icons.import_export,
              title: 'Exportar / importar datos',
              subtitle: 'Próximamente',
              enabled: false,
            ),
          ],
        ),
        AppFilterChips<String>(
          label: 'Categorías',
          options: const <AppChoice<String>>[
            AppChoice<String>(value: 'food', label: 'Comida'),
            AppChoice<String>(value: 'home', label: 'Hogar', icon: Icons.home_outlined),
          ],
          selected: const <String>{'food'},
          onChanged: (Set<String> _) {},
        ),
        AppCheckTile(
          title: 'Huevos',
          subtitle: '2 docenas',
          value: false,
          checkboxLabel: 'Marcar como comprado',
          onChanged: (bool _) {},
          onTap: () {},
          badges: const <Widget>[
            AppBadge(label: 'Inmediata', tone: AppBadgeTone.critical, icon: Icons.priority_high),
            AppBadge(label: 'Toca pronto', tone: AppBadgeTone.warning),
            AppBadge(label: 'Comida'),
          ],
        ),
        AppCheckTile(title: 'Pan', value: true, checkboxLabel: 'Marcar como comprado', onChanged: (bool _) {}),
      ],
    );

void main() {
  test('AppColors.error es opaco', () {
    expect(AppColors.error.a, 1.0);
  });

  for (final (String name, ThemeData theme) in <(String, ThemeData)>[('claro', AppTheme.light), ('oscuro', AppTheme.dark)]) {
    testWidgets('tema $name: cumple las guías de accesibilidad', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(gallery(), theme: theme));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }

  testWidgets('AppIconButton expone el tooltip a los lectores de pantalla', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(AppIconButton(icon: Icons.delete, tooltip: 'Eliminar', onPressed: () {})));

    expect(
      tester.getSemantics(find.byType(IconButton)),
      isSemantics(tooltip: 'Eliminar', isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('AppButton con isLoading se desactiva y conserva la etiqueta', (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(host(AppButton(label: 'Guardar', isLoading: true, onPressed: () => taps++)));

    await tester.tap(find.text('Guardar'));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppStatusView no desborda con el texto al 200 %', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(
        AppStatusView(
          icon: Icons.inbox,
          title: 'Identificador no registrado',
          message: 'Este código no está asociado a ningún objeto. ' * 6,
          action: AppButton(label: 'Crear nuevo objeto', onPressed: () {}),
        ),
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  group('listas', () {
    const List<AppChoice<String>> categories = <AppChoice<String>>[
      AppChoice<String>(value: 'food', label: 'Comida'),
      AppChoice<String>(value: 'home', label: 'Hogar'),
    ];

    testWidgets('AppFilterChips añade y quita opciones de la selección', (WidgetTester tester) async {
      final List<Set<String>> changes = <Set<String>>[];
      await tester.pumpWidget(
        host(AppFilterChips<String>(
          label: 'Categorías',
          options: categories,
          selected: const <String>{'food'},
          onChanged: changes.add,
        )),
      );

      await tester.tap(find.text('Hogar'));
      await tester.tap(find.text('Comida'));

      expect(changes, <Set<String>>[<String>{'food', 'home'}, <String>{}]);
      expect(find.text('Categorías'), findsOneWidget);
    });

    testWidgets('AppFilterChips sin onChanged queda desactivado y puede ocultar la etiqueta', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const AppFilterChips<String>(
          label: 'Categorías',
          options: categories,
          selected: <String>{},
          onChanged: null,
          showLabel: false,
        )),
      );

      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Hogar')).onSelected, isNull);
      expect(find.text('Categorías'), findsNothing);
      expect(find.bySemanticsLabel('Categorías'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('AppCheckTile avisa al tocar la casilla y llama a onTap al tocar la fila', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final List<bool> changes = <bool>[];
      int taps = 0;
      await tester.pumpWidget(
        host(AppCheckTile(
          title: 'Huevos',
          value: false,
          checkboxLabel: 'Marcar como comprado',
          onChanged: changes.add,
          onTap: () => taps++,
        )),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('Huevos'));

      expect(changes, <bool>[true]);
      expect(taps, 1);
      expect(find.bySemanticsLabel('Marcar como comprado'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('AppCheckTile marcada tacha el título; sin onChanged la casilla se desactiva', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(const AppCheckTile(title: 'Pan', value: true, checkboxLabel: 'Marcar', onChanged: null)),
      );

      expect(tester.widget<Text>(find.text('Pan')).style?.decoration, TextDecoration.lineThrough);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    });

    testWidgets('AppCheckTile no desborda con el texto al 200 %', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          AppCheckTile(
            title: 'Detergente para ropa delicada con aroma a lavanda',
            subtitle: '2 botellas grandes',
            value: false,
            checkboxLabel: 'Marcar como comprado',
            onChanged: (bool _) {},
            badges: const <Widget>[
              AppBadge(label: 'Inmediata', tone: AppBadgeTone.critical, icon: Icons.priority_high),
              AppBadge(label: 'Atrasado', tone: AppBadgeTone.warning),
              AppBadge(label: 'Limpieza'),
              AppBadge(label: 'Hogar'),
            ],
          ),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('accesos rápidos', () {
    testWidgets('AppShortcutTile sin icono usa el genérico y corta el título en dos líneas', (WidgetTester tester) async {
      await tester.pumpWidget(host(const AppShortcutTile(label: 'Un título muy largo para un acceso rápido')));

      expect(find.byIcon(AppShortcutTile.fallbackIcon), findsOneWidget);
      final Text title = tester.widget<Text>(find.text('Un título muy largo para un acceso rápido'));
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('AppShortcutTile es un botón con su título para los lectores de pantalla', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int taps = 0;
      await tester.pumpWidget(host(AppShortcutTile(icon: Icons.inventory_2_outlined, label: 'Objetos', onTap: () => taps++)));

      expect(
        tester.getSemantics(find.byType(AppShortcutTile)),
        isSemantics(label: 'Objetos', isButton: true, isEnabled: true, hasEnabledState: true, hasTapAction: true),
      );
      await tester.tap(find.text('Objetos'));
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('AppShortcutTile con tooltip lo muestra al mantener pulsado', (WidgetTester tester) async {
      await tester.pumpWidget(host(AppShortcutTile(label: 'Notas', error: true, tooltip: 'No se pudo iniciar', onTap: () {})));

      await tester.longPress(find.text('Notas'));
      await tester.pump();

      expect(find.text('No se pudo iniciar'), findsOneWidget);
    });

    test('AppShortcutGrid usa 4 columnas en móvil y más en pantallas anchas', () {
      expect(AppShortcutGrid.columnsFor(360), 4);
      expect(AppShortcutGrid.columnsFor(599), 4);
      expect(AppShortcutGrid.columnsFor(600), 4);
      expect(AppShortcutGrid.columnsFor(1000), 7);
    });

    for (final (double width, int columns) in <(double, int)>[(400, 4), (1000, 7)]) {
      testWidgets('AppShortcutGrid a $width px pone $columns casillas por fila', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          host(
            AppShortcutGrid(
              children: <Widget>[
                for (int i = 0; i <= columns; i++) AppShortcutTile(label: 'Acceso $i', onTap: () {}),
              ],
            ),
          ),
        );

        final double firstRow = tester.getTopLeft(find.text('Acceso 0')).dy;
        for (int i = 1; i < columns; i++) {
          expect(tester.getTopLeft(find.text('Acceso $i')).dy, firstRow);
        }
        expect(tester.getTopLeft(find.text('Acceso $columns')).dy, greaterThan(firstRow));
      });
    }

    testWidgets('AppShortcutGrid no desborda con el texto al 200 %', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          AppShortcutGrid(
            children: <Widget>[
              for (int i = 0; i < 9; i++) AppShortcutTile(label: 'Un acceso con título largo $i', onTap: () {}),
            ],
          ),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('ajustes', () {
    const List<AppChoice<String>> languages = <AppChoice<String>>[
      AppChoice<String>(value: 'system', label: 'Idioma del sistema'),
      AppChoice<String>(value: 'es', label: 'Español'),
      AppChoice<String>(value: 'en', label: 'English'),
    ];

    testWidgets('AppChoiceSelector avisa solo al elegir una opción distinta', (WidgetTester tester) async {
      final List<String> changes = <String>[];
      await tester.pumpWidget(
        host(AppChoiceSelector<String>(label: 'Idioma', options: languages, selected: 'es', onChanged: changes.add)),
      );

      await tester.tap(find.text('Español'));
      await tester.tap(find.text('English'));

      expect(changes, <String>['en']);
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Español')).selected, isTrue);
    });

    testWidgets('AppChoiceSelector sin onChanged queda desactivado', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(const AppChoiceSelector<String>(label: 'Idioma', options: languages, selected: 'es', onChanged: null)),
      );

      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'English')).onSelected, isNull);
    });

    testWidgets('AppChoiceSelector no desborda con el texto al 200 %', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          AppChoiceSelector<String>(
            label: 'Idioma',
            icon: Icons.language,
            options: languages,
            selected: 'system',
            onChanged: (String _) {},
          ),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('AppSettingsTile responde al toque y, desactivado, no', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        host(
          AppSettingsSection(
            title: 'Ajustes',
            children: <Widget>[
              AppSettingsTile(icon: Icons.extension_outlined, title: 'Módulos', onTap: () => taps++),
              AppSettingsTile(
                icon: Icons.import_export,
                title: 'Exportar',
                subtitle: 'Próximamente',
                enabled: false,
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Módulos'));
      await tester.tap(find.text('Exportar'));

      expect(taps, 1);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });
  });

  testWidgets('showAppConfirmDialog devuelve true al confirmar y false al cancelar', (WidgetTester tester) async {
    final List<bool> results = <bool>[];
    await tester.pumpWidget(
      host(
        Builder(
          builder: (BuildContext context) => AppButton(
            label: 'Abrir',
            onPressed: () async => results.add(await showAppConfirmDialog(context, title: 'T', message: 'M')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(results, <bool>[true, false]);
  });
}
