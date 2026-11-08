import 'dart:async';
import 'dart:math';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/gallery.dart';

void main() {
  test('los tokens conservan los valores de Figma', () {
    expect(AppColors.alphaViolet16, const Color(0x291E0E45));
    expect(AppSpacing.s300, 12);
    expect(AppSpacing.md, AppSpacing.s400);
    expect(AppRadii.full, 999);
    expect(AppSizes.iconCompact, 20);
    expect(AppLayout.breakpointDesktop, 1024);
    expect(AppElevation.dark3.single.color, AppColors.alphaBlack60);
    expect(AppElevation.light2.single.spreadRadius, -2);

    expect(AppTypography.webDisplay.fontSize, 56);
    expect(AppTypography.webDisplay.height! * 56, closeTo(64, 0.001));
    expect(AppTypography.webDisplay.letterSpacing, closeTo(-1.12, 0.001));
    expect(AppTypography.mobileLabelS.fontWeight, FontWeight.w500);
  });

  group('botones', () {
    testWidgets('secundario es relleno de marca y outline solo lleva borde', (WidgetTester tester) async {
      for (final (ThemeData theme, AppThemeColors colors) in <(ThemeData, AppThemeColors)>[
        (AppTheme.light, AppThemeColors.light),
        (AppTheme.dark, AppThemeColors.dark),
      ]) {
        await tester.pumpWidget(
          host(
            Column(
              children: <Widget>[
                AppButton(label: 'Secundario', variant: AppButtonVariant.secondary, onPressed: () {}),
                AppButton(label: 'Borde', variant: AppButtonVariant.outline, onPressed: () {}),
              ],
            ),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        final Material filled = tester.widget<Material>(
          find.descendant(of: find.byType(FilledButton), matching: find.byType(Material)),
        );
        expect(filled.color, colors.actionSecondaryDefault);
        expect(filled.textStyle?.color, colors.textOnBrandSubtle);
        expect(find.byType(OutlinedButton), findsOneWidget);
        final Material outlined = tester.widget<Material>(
          find.descendant(of: find.byType(OutlinedButton), matching: find.byType(Material)),
        );
        expect((outlined.shape! as OutlinedBorder).side.color, colors.borderStrong);
        expect(outlined.textStyle?.color, colors.textPrimary);
      }
    });
  });

  group('AppBadge', () {
    for (final (AppBadgeTone tone, Color background, Color foreground) in <(AppBadgeTone, Color, Color)>[
      (AppBadgeTone.critical, AppThemeColors.light.bgDangerSubtle, AppThemeColors.light.textDanger),
      (AppBadgeTone.warning, AppThemeColors.light.bgWarningSubtle, AppThemeColors.light.textWarning),
      (AppBadgeTone.brand, AppThemeColors.light.bgBrandSubtle, AppThemeColors.light.textBrand),
      (AppBadgeTone.success, AppThemeColors.light.bgSuccessSubtle, AppThemeColors.light.textSuccess),
    ]) {
      testWidgets('el tono ${tone.name} usa sus colores y es una píldora', (WidgetTester tester) async {
        await tester.pumpWidget(host(AppBadge(label: 'Etiqueta', tone: tone)));

        final BoxDecoration decoration = tester
            .widget<DecoratedBox>(find.descendant(of: find.byType(AppBadge), matching: find.byType(DecoratedBox)))
            .decoration as BoxDecoration;
        expect(decoration.color, background);
        expect(decoration.borderRadius, BorderRadius.circular(AppRadii.full));
        expect(tester.renderObject<RenderParagraph>(find.text('Etiqueta')).text.style?.color, foreground);
      });
    }
  });

  group('AppModuleCard', () {
    testWidgets('con onTap es un botón que se anuncia con su título', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int taps = 0;
      await tester.pumpWidget(
        host(
          AppModuleCard(
            icon: AppIcons.shoppingCart,
            title: 'Lista de compras',
            summary: '5 cosas por comprar',
            badges: const <Widget>[AppBadge(label: '2 urgentes')],
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('5 cosas por comprar'));

      expect(taps, 1);
      expect(find.text('2 urgentes'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Lista de compras')), findsWidgets);
      semantics.dispose();
    });

    testWidgets('reparte el ancho entre sus acciones', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AppModuleCard(
            icon: AppIcons.scanLine,
            title: 'Objetos',
            actions: <Widget>[
              AppButton(label: 'A', onPressed: () {}),
              AppButton(label: 'Más largo', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(tester.getSize(find.byType(Expanded).last).width, tester.getSize(find.byType(Expanded).at(1)).width);
      expect(
        tester.getSize(find.widgetWithText(AppButton, 'A')).width,
        tester.getSize(find.widgetWithText(AppButton, 'Más largo')).width,
      );
    });

    testWidgets('sin resumen ni acciones muestra solo el título', (WidgetTester tester) async {
      await tester.pumpWidget(host(const AppModuleCard(icon: AppIcons.layoutGrid, title: 'Módulo')));

      expect(find.byType(Wrap), findsNothing);
      expect(find.byType(AppButton), findsNothing);
    });
  });

  testWidgets('el SnackBar usa la superficie elevada y un borde', (WidgetTester tester) async {
    await tester.pumpWidget(host(Builder(
      builder: (BuildContext context) => TextButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado'))),
        child: const Text('Mostrar'),
      ),
    )));
    await tester.tap(find.text('Mostrar'));
    await tester.pump();

    final Material material = tester.widget<Material>(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first,
    );
    expect(material.color, AppThemeColors.light.bgSurfaceRaised);
    expect((material.shape! as RoundedRectangleBorder).side.color, AppThemeColors.light.borderDefault);
    expect(AppTheme.light.snackBarTheme.behavior, SnackBarBehavior.floating);
  });

  group('AppThemeColors', () {
    testWidgets('el tema expone los colores semánticos de claro y de oscuro', (WidgetTester tester) async {
      late AppThemeColors colors;
      await tester.pumpWidget(host(Builder(builder: (BuildContext context) {
        colors = AppThemeColors.of(context);
        return const SizedBox();
      }), theme: AppTheme.dark));

      expect(colors, AppThemeColors.dark);
      expect(colors.bgCanvas, AppTheme.dark.scaffoldBackgroundColor);
      expect(AppTheme.light.extension<AppThemeColors>(), AppThemeColors.light);
    });

    testWidgets('un componente funciona en un tema sin esos colores', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(AppSettingsTile(icon: AppIcons.slidersVertical, title: 'Módulos', onTap: () {}), theme: ThemeData.dark()),
      );

      expect(tester.takeException(), isNull);
      expect(tester.widget<Icon>(find.byIcon(AppIcons.chevronRight)).color, AppThemeColors.dark.textTertiary);
    });

    test('copyWith cambia solo lo indicado', () {
      final AppThemeColors changed = AppThemeColors.light.copyWith(textInfo: AppColors.red700);

      expect(changed.textInfo, AppColors.red700);
      expect(changed.bgCanvas, AppThemeColors.light.bgCanvas);
    });

    test('lerp interpola entre temas y sin otro tema se queda igual', () {
      expect(AppThemeColors.light.lerp(AppThemeColors.dark, 1).bgCanvas, AppThemeColors.dark.bgCanvas);
      expect(AppThemeColors.light.lerp(null, 0.5), AppThemeColors.light);
    });
  });

  test('los temas usan el morado del sistema de diseño', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.violet700);
    expect(AppTheme.dark.colorScheme.primary, AppColors.violet400);
  });

  for (final (String name, ColorScheme scheme, AppThemeColors colors) in <(String, ColorScheme, AppThemeColors)>[
    ('claro', AppTheme.light.colorScheme, AppThemeColors.light),
    ('oscuro', AppTheme.dark.colorScheme, AppThemeColors.dark),
  ]) {
    test('tema $name: los colores son opacos y los textos tienen contraste de 4,5:1', () {
      final List<(Color, Color)> pairs = <(Color, Color)>[
        (scheme.onPrimary, scheme.primary),
        (scheme.onPrimaryContainer, scheme.primaryContainer),
        (scheme.onSecondaryContainer, scheme.secondaryContainer),
        (scheme.onTertiaryContainer, scheme.tertiaryContainer),
        (scheme.onError, scheme.error),
        (scheme.onErrorContainer, scheme.errorContainer),
        (scheme.onSurface, scheme.surface),
        (scheme.onSurfaceVariant, scheme.surface),
        (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
        (colors.textOnBrandSubtle, colors.actionSecondaryDefault),
        (colors.textBrand, colors.bgBrandSubtle),
        (colors.textSuccess, colors.bgSuccessSubtle),
        (colors.textDanger, colors.bgDangerSubtle),
        (colors.textWarning, colors.bgWarningSubtle),
        (colors.textSecondary, colors.bgBrandSubtle),
      ];
      for (final (Color foreground, Color background) in pairs) {
        expect(foreground.a, 1.0);
        expect(background.a, 1.0);
        final double lighter = max(foreground.computeLuminance(), background.computeLuminance());
        final double darker = min(foreground.computeLuminance(), background.computeLuminance());
        expect((lighter + 0.05) / (darker + 0.05), greaterThanOrEqualTo(4.5));
      }
    });
  }

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
              AppBadge(label: 'Inmediata', tone: AppBadgeTone.critical, icon: AppIcons.exclamation),
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
      await tester.pumpWidget(host(AppShortcutTile(icon: AppIcons.box, label: 'Objetos', onTap: () => taps++)));

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

    test('AppShortcutGrid pone tantas columnas como quepan, y al menos dos', () {
      expect(AppShortcutGrid.columnsFor(100), 2);
      expect(AppShortcutGrid.columnsFor(288), 2);
      expect(AppShortcutGrid.columnsFor(358), 3);
      expect(AppShortcutGrid.columnsFor(600), 5);
      expect(AppShortcutGrid.columnsFor(968), 8);
    });

    for (final (double width, int columns) in <(double, int)>[(390, 3), (1000, 8)]) {
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
      expect(tester.widget<AppChoiceSegment>(find.widgetWithText(AppChoiceSegment, 'Español')).selected, isTrue);
      expect(tester.widget<AppChoiceSegment>(find.widgetWithText(AppChoiceSegment, 'English')).selected, isFalse);
    });

    testWidgets('AppChoiceSelector sin onChanged queda desactivado', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(const AppChoiceSelector<String>(label: 'Idioma', options: languages, selected: 'es', onChanged: null)),
      );

      expect(tester.widget<AppChoiceSegment>(find.widgetWithText(AppChoiceSegment, 'English')).onTap, isNull);
    });

    testWidgets('AppChoiceSelector pone las opciones en fila si caben y, si no, las apila', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const List<AppChoice<String>> short = <AppChoice<String>>[
        AppChoice<String>(value: 'a', label: 'A'),
        AppChoice<String>(value: 'b', label: 'B'),
      ];

      Widget selector({required double textScale}) => host(
            AppChoiceSelector<String>(label: 'Letra', options: short, selected: 'a', onChanged: (String _) {}),
            textScale: textScale,
          );
      await tester.pumpWidget(selector(textScale: 1));
      double top(String label) => tester.getTopLeft(find.widgetWithText(AppChoiceSegment, label)).dy;
      expect(top('A'), top('B'));

      await tester.pumpWidget(
        host(
          AppChoiceSelector<String>(
            label: 'Modo',
            options: const <AppChoice<String>>[
              AppChoice<String>(value: 'a', label: 'Una opción con una etiqueta muy larga'),
              AppChoice<String>(value: 'b', label: 'B'),
            ],
            selected: 'a',
            onChanged: (String _) {},
          ),
        ),
      );
      expect(top('B'), greaterThan(top('Una opción con una etiqueta muy larga')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppChoiceSelector quita la marca antes de apilar las opciones', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          AppChoiceSelector<String>(
            label: 'Urgencia',
            padding: EdgeInsets.zero,
            options: const <AppChoice<String>>[
              AppChoice<String>(value: 'a', label: 'Aaaa'),
              AppChoice<String>(value: 'b', label: 'Bbbb'),
            ],
            selected: 'a',
            onChanged: (String _) {},
          ),
          textScale: 2.3,
        ),
      );

      double top(String label) => tester.getTopLeft(find.widgetWithText(AppChoiceSegment, label)).dy;
      expect(top('Aaaa'), top('Bbbb'));
      expect(find.byIcon(AppIcons.check), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppChoiceSelector respeta su margen', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AppChoiceSelector<String>(
            label: 'Idioma',
            padding: EdgeInsets.zero,
            options: languages,
            selected: 'es',
            onChanged: (String _) {},
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('Idioma')).dx, 0);
    });

    testWidgets('AppChoiceSelector anuncia la opción elegida como seleccionada', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(AppChoiceSelector<String>(label: 'Idioma', options: languages, selected: 'es', onChanged: (String _) {})),
      );

      expect(
        tester.getSemantics(find.widgetWithText(AppChoiceSegment, 'Español')),
        matchesSemantics(
          label: 'Español',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('AppSettingsTile tiene tono de peligro y de desactivado', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          Column(
            children: <Widget>[
              AppSettingsTile(icon: AppIcons.logOut, title: 'Salir', destructive: true, onTap: () {}),
              const AppSettingsTile(icon: AppIcons.arrowUpDown, title: 'Exportar', subtitle: 'Pronto', enabled: false),
              AppSettingsTile(icon: AppIcons.slidersVertical, title: 'Módulos', onTap: () {}),
            ],
          ),
        ),
      );
      Color? textColor(String text) => tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

      expect(textColor('Salir'), AppThemeColors.light.textDanger);
      expect(textColor('Exportar'), AppThemeColors.light.textDisabled);
      expect(textColor('Pronto'), AppThemeColors.light.textSecondary, reason: 'la explicación sigue legible');
      expect(tester.widget<Icon>(find.byIcon(AppIcons.arrowUpDown)).color ?? IconTheme.of(tester.element(find.byIcon(AppIcons.arrowUpDown))).color,
          AppThemeColors.light.textDisabled);
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget, reason: 'solo la fila normal lleva flecha');
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
              AppSettingsTile(icon: AppIcons.layoutGrid, title: 'Módulos', onTap: () => taps++),
              AppSettingsTile(
                icon: AppIcons.arrowUpDown,
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
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
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

  testWidgets('showAppChoiceDialog devuelve la opción elegida y null al cancelar', (WidgetTester tester) async {
    final List<String?> results = <String?>[];
    await tester.pumpWidget(
      host(
        Builder(
          builder: (BuildContext context) => AppButton(
            label: 'Abrir',
            onPressed: () async => results.add(
              await showAppChoiceDialog<String>(
                context,
                title: 'T',
                message: 'M',
                options: const <AppDialogOption<String>>[
                  AppDialogOption<String>(value: 'a', label: 'Opción A'),
                  AppDialogOption<String>(value: 'b', label: 'Opción B', destructive: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, 'Opción B'), findsOneWidget, reason: 'la destructiva va con borde');
    expect(find.widgetWithText(FilledButton, 'Opción A'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Opción A')).dy,
      lessThan(tester.getTopLeft(find.text('Opción B')).dy),
      reason: 'las opciones van apiladas',
    );
    await tester.tap(find.text('Opción B'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opción A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(results, <String?>['b', 'a', null]);
  });

  group('AppSyncStatusCard', () {
    testWidgets('muestra título, detalles y mensaje, y la acción responde', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        host(AppSyncStatusCard(
          tone: AppSyncTone.error,
          title: 'No se pudo sincronizar',
          details: const <String>['3 cambios pendientes', 'Ningún dispositivo a la vista'],
          message: 'Revisa la WiFi.',
          actionLabel: 'Sincronizar ahora',
          onAction: () => taps++,
        )),
      );

      expect(find.text('3 cambios pendientes'), findsOneWidget);
      expect(find.text('Ningún dispositivo a la vista'), findsOneWidget);
      expect(find.text('Revisa la WiFi.'), findsOneWidget);
      expect(find.byIcon(AppIcons.refreshCwOff), findsOneWidget);

      await tester.tap(find.text('Sincronizar ahora'));
      expect(taps, 1);
    });

    testWidgets('el título se anuncia al cambiar', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(const AppSyncStatusCard(tone: AppSyncTone.off, title: 'Sin hogar')));

      expect(find.byIcon(AppIcons.house), findsOneWidget);
      expect(tester.getSemantics(find.text('Sin hogar')), isSemantics(label: 'Sin hogar', isLiveRegion: true));
      expect(find.byType(AppButton), findsNothing);
      semantics.dispose();
    });

    testWidgets('sincronizando, la acción muestra un indicador y no responde', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        host(AppSyncStatusCard(
          tone: AppSyncTone.syncing,
          title: 'Sincronizando…',
          actionLabel: 'Sincronizar ahora',
          onAction: () => taps++,
        )),
      );

      await tester.tap(find.text('Sincronizar ahora'));
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AppConflictCard', () {
    Widget conflict({required ValueChanged<String> onSelected, VoidCallback? onKeep, bool busy = false}) => AppConflictCard<String>(
          title: 'Etiqueta en dos objetos',
          message: 'La etiqueta NFC se asoció a la vez a dos objetos.',
          options: const <AppConflictOption<String>>[
            AppConflictOption<String>(value: 'a', label: 'Caja A', description: 'La etiqueta queda en «Caja A».'),
            AppConflictOption<String>(value: 'b', label: 'Caja B'),
          ],
          applied: 'a',
          appliedLabel: 'Aplicada ahora',
          onSelected: onSelected,
          keepLabel: 'Dejarlo así',
          onKeep: onKeep,
          busy: busy,
        );

    testWidgets('marca la opción aplicada y avisa de la elegida', (WidgetTester tester) async {
      final List<String> selected = <String>[];
      int keeps = 0;
      await tester.pumpWidget(host(conflict(onSelected: selected.add, onKeep: () => keeps++)));

      expect(find.text('Aplicada ahora'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Caja A'), findsNothing, reason: 'la aplicada no es un botón más');
      expect(
        find.descendant(of: find.widgetWithText(InkWell, 'Caja A'), matching: find.text('Aplicada ahora')),
        findsOneWidget,
      );
      expect(
        tester.widget<AppBadge>(find.widgetWithText(AppBadge, 'Aplicada ahora')).tone,
        AppBadgeTone.brand,
      );
      expect(find.text('La etiqueta queda en «Caja A».'), findsOneWidget);

      await tester.tap(find.text('Caja B'));
      await tester.tap(find.text('Dejarlo así'));

      expect(selected, <String>['b']);
      expect(keeps, 1);
    });

    testWidgets('con busy, las opciones y la confirmación no responden', (WidgetTester tester) async {
      final List<String> selected = <String>[];
      int keeps = 0;
      await tester.pumpWidget(host(conflict(onSelected: selected.add, onKeep: () => keeps++, busy: true)));

      await tester.tap(find.text('Caja B'));
      await tester.tap(find.text('Dejarlo así'));

      expect(selected, isEmpty);
      expect(keeps, 0);
    });

    testWidgets('sin keepLabel no hay botón de confirmar', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(AppConflictCard<int>(
          title: '¿Fueron dos compras?',
          message: 'Dos dispositivos compraron «Leche» a la vez.',
          options: const <AppConflictOption<int>>[
            AppConflictOption<int>(value: 1, label: 'Una compra'),
            AppConflictOption<int>(value: 2, label: 'Dos compras'),
          ],
          applied: 1,
          appliedLabel: 'Aplicada ahora',
          onSelected: (int _) {},
        )),
      );

      expect(find.widgetWithText(AppButton, 'Dejarlo así'), findsNothing);
    });

    testWidgets('las tarjetas de sincronización no desbordan con el texto al 200 %', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          ListView(
            children: <Widget>[
              AppSyncStatusCard(
                tone: AppSyncTone.error,
                title: 'No se pudo sincronizar con el otro dispositivo',
                details: const <String>['12 cambios pendientes de enviar'],
                message: 'El otro dispositivo no conoce la clave del hogar.',
                actionLabel: 'Sincronizar ahora',
                onAction: () {},
              ),
              conflict(onSelected: (String _) {}, onKeep: () {}),
            ],
          ),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('área táctil', () {
    testWidgets('AppButton mide lo que su tamaño y responde en un área de 48', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        host(Center(child: AppButton(label: 'Medio', size: AppButtonSize.medium, onPressed: () => taps++))),
      );

      final Rect button = tester.getRect(find.byType(FilledButton));
      expect(button.height, AppSizes.controlMedium);

      await tester.tapAt(button.topCenter - const Offset(0, 3));
      await tester.tapAt(button.bottomCenter + const Offset(0, 3));
      expect(taps, 2);
      await tester.tapAt(button.topCenter - const Offset(0, 6));
      expect(taps, 2, reason: 'fuera de los 48 no cuenta');
    });

    for (final (AppButtonSize? size, AppButtonVariant variant, double height) in <(AppButtonSize?, AppButtonVariant, double)>[
      (null, AppButtonVariant.primary, AppSizes.controlLarge),
      (null, AppButtonVariant.text, AppSizes.controlCompact),
      (AppButtonSize.small, AppButtonVariant.outline, AppSizes.controlCompact),
      (AppButtonSize.medium, AppButtonVariant.danger, AppSizes.controlMedium),
      (AppButtonSize.medium, AppButtonVariant.dangerOutline, AppSizes.controlMedium),
    ]) {
      testWidgets('AppButton $variant de tamaño $size mide $height y cumple las guías', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(
          host(Center(child: AppButton(label: 'Acción', size: size, variant: variant, icon: AppIcons.plus, onPressed: () {}))),
        );

        expect(tester.getSize(find.byType(AppTouchTarget)).height, height);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        handle.dispose();
      });
    }

    testWidgets('AppFilterChips y AppChoiceSelector cumplen las guías', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              spacing: AppSpacing.md,
              children: <Widget>[
                AppFilterChips<String>(
                  label: 'Filtro',
                  options: const <AppChoice<String>>[AppChoice<String>(value: 'a', label: 'Una opción')],
                  selected: const <String>{},
                  onChanged: (Set<String> _) {},
                ),
                AppChoiceSelector<String>(
                  label: 'Tema',
                  options: const <AppChoice<String>>[
                    AppChoice<String>(value: 'a', label: 'Claro'),
                    AppChoice<String>(value: 'b', label: 'Oscuro'),
                  ],
                  selected: 'a',
                  onChanged: (String _) {},
                ),
              ],
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  testWidgets('AppChoiceSelector sin etiqueta visible la anuncia y puede partir el texto', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(240, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    await tester.pumpWidget(
      host(
        AppChoiceSelector<String>(
          label: 'Tipo',
          showLabel: false,
          wrapLabels: true,
          padding: EdgeInsets.zero,
          options: const <AppChoice<String>>[
            AppChoice<String>(value: 'a', label: 'Una etiqueta bastante larga'),
            AppChoice<String>(value: 'b', label: 'Otra'),
          ],
          selected: 'a',
          onChanged: (String _) {},
        ),
      ),
    );

    expect(find.text('Tipo'), findsNothing);
    expect(find.bySemanticsLabel('Tipo'), findsWidgets);
    expect(tester.getTopLeft(find.text('Otra')).dx, greaterThan(tester.getTopLeft(find.text('Una etiqueta bastante larga')).dx));
    expect(top('Otra'), lessThan(tester.getBottomLeft(find.text('Una etiqueta bastante larga')).dy));
    handle.dispose();
  });

  group('AppTextField', () {
    testWidgets('muestra la etiqueta fuera del campo y la lee como su nombre', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const AppTextField(label: 'Nombre', hint: 'Ej.: Leche', prefixIcon: AppIcons.search)));

      expect(
        tester.getBottomLeft(find.text('Nombre')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(TextField)).dy),
      );
      expect(tester.getSize(find.byType(TextField)).height, AppSizes.controlLarge);
      expect(find.byIcon(AppIcons.search), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Nombre')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('muestra el contador solo cerca del límite', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(AppTextField(label: 'Nombre', controller: controller, maxLength: 10)));

      controller.text = '1234567';
      await tester.pump();
      expect(find.text('7/10'), findsNothing);

      controller.text = '12345678';
      await tester.pump();
      expect(find.text('8/10'), findsOneWidget);
    });

    testWidgets('con varias líneas empieza con dos', (WidgetTester tester) async {
      await tester.pumpWidget(host(const AppTextField(label: 'Notas', maxLines: 4)));

      expect(tester.widget<TextField>(find.byType(TextField)).minLines, AppTextField.multilineMinLines);
      expect(tester.getSize(find.byType(TextField)).height, 80);
    });

    testWidgets('con minLines 1 mide como uno de una línea y crece al escribir', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(const AppTextField(label: 'Nombre')));
      final double singleLine = tester.getSize(find.byType(TextField)).height;
      await tester.pumpWidget(host(AppTextField(label: 'Título', controller: controller, maxLines: null, minLines: 1)));

      expect(tester.getSize(find.byType(TextField)).height, singleLine);
      controller.text = 'Una línea\ny otra';
      await tester.pump();
      expect(tester.getSize(find.byType(TextField)).height, greaterThan(singleLine));
    });

    testWidgets('el contador usa el texto que se le pasa', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(text: '12345678');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          AppTextField(
            label: 'Nombre',
            controller: controller,
            maxLength: 10,
            counterText: (int current, int max) => '$current de $max',
          ),
        ),
      );

      expect(find.text('8 de 10'), findsOneWidget);
    });
  });

  group('AppTopBar', () {
    testWidgets('sin flecha, el título empieza en el margen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const Scaffold(appBar: AppTopBar(title: Text('Inicio')))),
      );

      expect(tester.getTopLeft(find.text('Inicio')).dx, AppSpacing.md);
      expect(tester.getSize(find.byType(AppBar)).height, AppSizes.topBarHeight);
    });

    testWidgets('con flecha, el título va justo después de ella', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const Scaffold()));
      unawaited(
        tester.state<NavigatorState>(find.byType(Navigator)).push(
              MaterialPageRoute<void>(builder: (_) => const Scaffold(appBar: AppTopBar(title: Text('Detalle')))),
            ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.getTopLeft(find.text('Detalle')).dx, AppSizes.minTouchTarget);
    });
  });

  testWidgets('showAppBottomSheet mide lo que su contenido', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showAppBottomSheet<void>(
              context,
              builder: (BuildContext context) => const SizedBox(key: Key('contenido'), height: 100),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(BottomSheet)).height, lessThan(200));
    expect(find.byKey(const Key('contenido')), findsOneWidget);
  });

  testWidgets('AppFooterActions, AppNote y AppCameraFrame muestran su contenido', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        Column(
          children: <Widget>[
            const AppNote(icon: AppIcons.link, text: 'Se asociará el QR'),
            const SizedBox(height: 100, child: AppCameraFrame(child: Text('Vista previa'))),
            AppFooterActions(children: <Widget>[AppButton(label: 'Guardar', onPressed: () {})]),
          ],
        ),
      ),
    );

    expect(find.text('Se asociará el QR'), findsOneWidget);
    expect(find.text('Vista previa'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  test('AppIcons apunta a la fuente incluida en el paquete', () {
    expect(AppIcons.plus.fontFamily, 'Lucide');
    expect(AppIcons.plus.fontPackage, 'design_system');
  });

  testWidgets('la flecha atrás del tema es la de AppIcons', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const Scaffold(body: BackButton())));

    expect(find.byIcon(AppIcons.arrowLeft), findsOneWidget);
  });
}
