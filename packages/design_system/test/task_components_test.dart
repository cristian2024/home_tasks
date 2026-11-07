import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/gallery.dart';

/// Abre lo que devuelva [open] desde un botón y guarda su resultado.
Widget opener<T>(Future<T> Function(BuildContext context) open, List<T> results, {double textScale = 1}) => host(
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async => results.add(await open(context)),
          child: const Text('abrir'),
        ),
      ),
      textScale: textScale,
    );

void main() {
  group('tokens', () {
    test('la etiqueta neutra tiene fondo propio en claro y en oscuro', () {
      expect(AppThemeColors.light.bgBadgeNeutral, AppColors.neutral100);
      expect(AppThemeColors.dark.bgBadgeNeutral, AppColors.neutral800);
    });

    testWidgets('AppBadge neutro usa bgBadgeNeutral', (WidgetTester tester) async {
      await tester.pumpWidget(host(const AppBadge(label: 'En espera'), theme: AppTheme.dark));

      final BoxDecoration decoration = tester
          .widget<DecoratedBox>(find.descendant(of: find.byType(AppBadge), matching: find.byType(DecoratedBox)))
          .decoration as BoxDecoration;
      expect(decoration.color, AppThemeColors.dark.bgBadgeNeutral);
    });
  });

  testWidgets('AppCheckTile hecha tacha el título con el color secundario', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(AppCheckTile(title: 'Sacar la basura', value: true, checkboxLabel: 'Volver a pendiente', onChanged: (bool _) {})),
    );

    final TextStyle? style = tester.renderObject<RenderParagraph>(find.text('Sacar la basura')).text.style;
    expect(style?.color, AppThemeColors.light.textSecondary);
    expect(style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('AppButton dangerText es texto en color de peligro', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(AppButton(label: 'Borrar tarea', icon: AppIcons.trash, variant: AppButtonVariant.dangerText, onPressed: () {})),
    );

    expect(find.byType(TextButton), findsOneWidget);
    expect(tester.renderObject<RenderParagraph>(find.text('Borrar tarea')).text.style?.color, AppThemeColors.light.textDanger);
  });

  group('AppCard', () {
    testWidgets('pulsable, es un solo control con su etiqueta', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(AppCard(semanticLabel: 'Hechas, 3', onTap: () {}, child: const Text('Hechas · 3'))));

      final SemanticsData data = tester.getSemantics(find.bySemanticsLabel('Hechas, 3')).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isButton, isTrue);
      expect(find.bySemanticsLabel(RegExp('Hechas · 3')), findsNothing, reason: 'la etiqueta sustituye al texto');
      semantics.dispose();
    });

    testWidgets('pulsable y sin etiqueta, se anuncia con sus textos', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(AppCard(onTap: () {}, child: const Text('Hechas · 3'))));

      final SemanticsData data = tester.getSemantics(find.bySemanticsLabel('Hechas · 3')).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isButton, isTrue);
      semantics.dispose();
    });
  });

  testWidgets('AppSectionHeader con acción no parte el título al 200 %', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        AppSectionHeader(
          'Contenido',
          trailing: AppButton(label: 'Añadir objeto aquí', variant: AppButtonVariant.text, onPressed: () {}),
        ),
        textScale: 2,
      ),
    );

    final RenderParagraph title = tester.renderObject<RenderParagraph>(find.text('Contenido'));
    expect(title.size.width, greaterThanOrEqualTo(title.getMinIntrinsicWidth(double.infinity) - 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppFilterChips en varias filas no solapa las áreas táctiles', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppFilterChips<String>(
            label: 'Categorías',
            options: const <AppChoice<String>>[
              AppChoice<String>(value: 'a', label: 'Limpieza'),
              AppChoice<String>(value: 'b', label: 'Cocina'),
              AppChoice<String>(value: 'c', label: 'Jardín'),
              AppChoice<String>(value: 'd', label: 'Pagos'),
              AppChoice<String>(value: 'e', label: 'Reparaciones'),
            ],
            selected: const <String>{'b'},
            onChanged: (Set<String> _) {},
          ),
        ),
      ),
    );

    final List<Rect> targets = <Rect>[
      for (final Element chip in find.byType(AppTouchTarget).evaluate())
        () {
          final RenderBox box = chip.renderObject! as RenderBox;
          final Rect rect = box.localToGlobal(Offset.zero) & box.size;
          return Rect.fromCenter(
            center: rect.center,
            width: rect.width,
            height: rect.height < AppSizes.minTouchTarget ? AppSizes.minTouchTarget : rect.height,
          );
        }(),
    ];
    expect(targets.map((Rect rect) => rect.top).toSet().length, greaterThan(1), reason: 'los chips ocupan varias filas');
    for (int i = 0; i < targets.length; i++) {
      for (int j = i + 1; j < targets.length; j++) {
        expect(targets[i].intersect(targets[j]).isEmpty || targets[i].intersect(targets[j]).height <= 0, isTrue);
      }
    }
  });

  group('showAppActionSheet', () {
    const List<AppSheetAction<String>> actions = <AppSheetAction<String>>[
      AppSheetAction<String>(value: 'categories', label: 'Categorías', icon: AppIcons.tag),
      AppSheetAction<String>(value: 'clear', label: 'Borrar hechas', icon: AppIcons.trash, destructive: true),
    ];

    testWidgets('devuelve la acción elegida y null si se cierra', (WidgetTester tester) async {
      final List<String?> results = <String?>[];
      await tester.pumpWidget(
        opener<String?>((BuildContext context) => showAppActionSheet<String>(context, label: 'Más opciones', actions: actions), results),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(
        tester.renderObject<RenderParagraph>(find.text('Borrar hechas')).text.style?.color,
        AppThemeColors.light.textDanger,
      );
      await tester.tap(find.text('Borrar hechas'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(results, <String?>['clear', null]);
    });

    testWidgets('cumple las guías de accesibilidad', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        opener<String?>((BuildContext context) => showAppActionSheet<String>(context, label: 'Más opciones', actions: actions), <String?>[]),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Más opciones'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  });

  group('AppPickerField', () {
    testWidgets('se anuncia como botón con su etiqueta, su valor y la pista', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int taps = 0;
      await tester.pumpWidget(
        host(
          AppPickerField(
            label: 'Fecha',
            placeholder: 'Sin fecha',
            icon: AppIcons.calendar,
            semanticHint: 'Cambiar',
            onTap: () => taps++,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.descendant(of: find.byType(AppPickerField), matching: find.byType(InkWell))),
        matchesSemantics(
          label: 'Fecha',
          value: 'Sin fecha',
          hint: 'Cambiar',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.text('Sin fecha'));
      expect(taps, 1);
      expect(
        tester.renderObject<RenderParagraph>(find.text('Sin fecha')).text.style?.color,
        AppThemeColors.light.textSecondary,
      );
      semantics.dispose();
    });

    testWidgets('muestra el valor y el error', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          AppPickerField(
            label: 'Fecha',
            placeholder: 'Sin fecha',
            value: 'Mañana',
            icon: AppIcons.calendar,
            errorText: 'Elige una fecha',
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Mañana'), findsOneWidget);
      expect(find.text('Elige una fecha'), findsOneWidget);
      expect(find.byIcon(AppIcons.circleAlert), findsOneWidget, reason: 'el error no depende solo del color');
    });
  });

  group('showAppDateSheet', () {
    const AppDateSheetTexts texts = AppDateSheetTexts(
      title: 'Due date',
      fieldLabel: 'Type the date',
      fieldHint: 'E.g. 11/12/2026',
      invalidDate: "That date doesn't exist.",
      save: 'Save',
      calendar: 'Open calendar',
      remove: 'Remove date',
    );
    final List<AppDateOption> options = <AppDateOption>[
      AppDateOption(label: 'Today', date: DateTime(2026, 11, 7)),
      AppDateOption(label: 'Tomorrow', date: DateTime(2026, 11, 8)),
    ];

    Future<AppDateChoice?> open(BuildContext context) => showAppDateSheet(
          context,
          texts: texts,
          options: options,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );

    testWidgets('un acceso rápido escribe la fecha y se guarda', (WidgetTester tester) async {
      final List<AppDateChoice?> results = <AppDateChoice?>[];
      await tester.pumpWidget(opener<AppDateChoice?>(open, results));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tomorrow'));
      await tester.pump();
      expect(find.text('11/08/2026'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(results.single?.date, DateTime(2026, 11, 8));
    });

    testWidgets('una fecha escrita que no existe muestra el error y no cierra', (WidgetTester tester) async {
      final List<AppDateChoice?> results = <AppDateChoice?>[];
      await tester.pumpWidget(opener<AppDateChoice?>(open, results));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '13/45/2026');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text("That date doesn't exist."), findsOneWidget);
      expect(results, isEmpty);

      await tester.enterText(find.byType(TextField), '11/20/2026');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(results.single?.date, DateTime(2026, 11, 20));
    });

    testWidgets('quitar devuelve una elección sin fecha', (WidgetTester tester) async {
      final List<AppDateChoice?> results = <AppDateChoice?>[];
      await tester.pumpWidget(opener<AppDateChoice?>(open, results));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove date'));
      await tester.pumpAndSettle();

      expect(results.single, isNotNull);
      expect(results.single?.date, isNull);
    });

    testWidgets('el botón del calendario abre el del sistema', (WidgetTester tester) async {
      await tester.pumpWidget(opener<AppDateChoice?>(open, <AppDateChoice?>[]));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open calendar'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('al 200 % no desborda y cumple las guías de accesibilidad', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(opener<AppDateChoice?>(open, <AppDateChoice?>[], textScale: 2));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  });

  testWidgets('AppCheckTile puede leer su línea de datos de otra forma', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        AppCheckTile(
          title: 'Limpiar el horno',
          subtitle: '12 nov',
          subtitleSemantics: 'jueves, 12 de noviembre de 2026',
          value: false,
          checkboxLabel: 'Marcar como hecha',
          onChanged: (bool _) {},
        ),
      ),
    );

    expect(find.text('12 nov'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('jueves, 12 de noviembre')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('AppModuleCard pulsable se anuncia con su título, su resumen y sus etiquetas', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        AppModuleCard(
          icon: AppIcons.listChecks,
          title: 'Lista de tareas',
          summary: '7 por hacer',
          badges: const <Widget>[AppBadge(label: '2 atrasadas')],
          onTap: () {},
        ),
      ),
    );

    final SemanticsData data =
        tester.getSemantics(find.bySemanticsLabel(RegExp('Lista de tareas.*7 por hacer.*2 atrasadas', dotAll: true))).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('AppTextField acepta un FocusNode', (WidgetTester tester) async {
    final FocusNode focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(host(AppTextField(label: 'Título', focusNode: focus)));

    focus.requestFocus();
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField)).focusNode, focus);
    expect(focus.hasFocus, isTrue);
  });
}
