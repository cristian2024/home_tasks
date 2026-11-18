import 'dart:ui' show Tristate;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/gallery.dart';

/// Pinta el anillo de foco: el `CustomPaint` de [AppFocusRing] tiene un
/// `foregroundPainter`.
bool ringVisible(WidgetTester tester, Finder ring) => tester
    .widgetList<CustomPaint>(find.descendant(of: ring, matching: find.byType(CustomPaint)))
    .any((CustomPaint paint) => paint.foregroundPainter != null);

/// Usa el resaltado del teclado mientras dura el test.
void useKeyboardHighlight() {
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
  addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
}

const List<AppChoice<String>> categories = <AppChoice<String>>[
  AppChoice<String>(value: 'food', label: 'Comida'),
  AppChoice<String>(value: 'cleaning', label: 'Limpieza'),
  AppChoice<String>(value: 'bath', label: 'Baño'),
  AppChoice<String>(value: 'pets', label: 'Mascotas'),
  AppChoice<String>(value: 'home', label: 'Casa'),
  AppChoice<String>(value: 'other', label: 'Otros'),
];

void main() {
  group('tokens', () {
    test('el texto terciario en claro es neutral550', () {
      expect(AppColors.neutral550, const Color(0xFF6E6A82));
      expect(AppThemeColors.light.textTertiary, AppColors.neutral550);
      expect(AppThemeColors.dark.textTertiary, AppColors.neutral450);
    });

    test('los bordes de las etiquetas de urgencia igualan el fondo en claro y lo separan en oscuro', () {
      expect(AppThemeColors.light.borderBadgeDanger, AppThemeColors.light.bgDangerSubtle);
      expect(AppThemeColors.light.borderBadgeWarning, AppThemeColors.light.bgWarningSubtle);
      expect(AppThemeColors.dark.borderBadgeDanger, AppColors.red400);
      expect(AppThemeColors.dark.borderBadgeWarning, AppColors.amber400);
    });

    test('copyWith y lerp conservan los bordes nuevos', () {
      final AppThemeColors copy = AppThemeColors.light.copyWith(borderBadgeDanger: AppColors.red700);
      expect(copy.borderBadgeDanger, AppColors.red700);
      expect(copy.borderBadgeWarning, AppThemeColors.light.borderBadgeWarning);
      final AppThemeColors lerped = AppThemeColors.light.lerp(AppThemeColors.dark, 1);
      expect(lerped.borderBadgeDanger, AppThemeColors.dark.borderBadgeDanger);
      expect(lerped.borderBadgeWarning, AppThemeColors.dark.borderBadgeWarning);
    });
  });

  group('AppBadge', () {
    BoxDecoration decorationOf(WidgetTester tester) => tester
        .widget<DecoratedBox>(find.descendant(of: find.byType(AppBadge), matching: find.byType(DecoratedBox)))
        .decoration as BoxDecoration;

    testWidgets('crítica y de aviso llevan borde; la neutra no', (WidgetTester tester) async {
      await tester.pumpWidget(host(const AppBadge(label: 'Inmediata', tone: AppBadgeTone.critical), theme: AppTheme.dark));
      expect((decorationOf(tester).border! as Border).top.color, AppThemeColors.dark.borderBadgeDanger);

      await tester.pumpWidget(host(const AppBadge(label: 'Pronto', tone: AppBadgeTone.warning), theme: AppTheme.dark));
      expect((decorationOf(tester).border! as Border).top.color, AppThemeColors.dark.borderBadgeWarning);

      await tester.pumpWidget(host(const AppBadge(label: 'Comida'), theme: AppTheme.dark));
      expect(decorationOf(tester).border, isNull);
    });

    testWidgets('el borde no cambia el tamaño de la etiqueta', (WidgetTester tester) async {
      await tester.pumpWidget(host(const Center(child: AppBadge(label: 'Comida'))));
      final Size plain = tester.getSize(find.byType(AppBadge));
      await tester.pumpWidget(host(const Center(child: AppBadge(label: 'Comida', tone: AppBadgeTone.critical))));
      expect(tester.getSize(find.byType(AppBadge)), plain);
    });
  });

  testWidgets('el segmento elegido lleva borde de marca de 2', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        AppChoiceSelector<String>(
          label: 'Agrupar por',
          options: const <AppChoice<String>>[
            AppChoice<String>(value: 'category', label: 'Categoría'),
            AppChoice<String>(value: 'urgency', label: 'Urgencia'),
          ],
          selected: 'category',
          onChanged: (String _) {},
        ),
      ),
    );

    Border? borderOf(String label) {
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.ancestor(of: find.text(label), matching: find.byType(DecoratedBox)).first,
      );
      return (box.decoration as BoxDecoration).border as Border?;
    }

    final Border selected = borderOf('Categoría')!;
    expect(selected.top.color, AppThemeColors.light.borderBrand);
    expect(selected.top.width, AppSizes.strokeThick);
    expect(borderOf('Urgencia'), isNull);
  });

  group('AppFocusRing', () {
    testWidgets('marca el botón con el foco del teclado y no con el dedo', (WidgetTester tester) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(Center(child: AppButton(label: 'Guardar', onPressed: () {}))),
      );
      final Finder ring = find.byType(AppFocusRing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringVisible(tester, ring), isTrue);

      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      await tester.pump();
      expect(ringVisible(tester, ring), isFalse);
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    });

    testWidgets('icon button, chip, segmento y fila de ajustes lo muestran con el foco', (WidgetTester tester) async {
      useKeyboardHighlight();
      await tester.pumpWidget(
        host(
          Column(
            children: <Widget>[
              AppIconButton(icon: AppIcons.pencil, tooltip: 'Editar', onPressed: () {}),
              AppFilterChips<String>(
                label: 'Categorías',
                options: categories.take(1).toList(),
                selected: const <String>{},
                onChanged: (Set<String> _) {},
              ),
              AppChoiceSelector<String>(
                label: 'Tema',
                options: const <AppChoice<String>>[AppChoice<String>(value: 'light', label: 'Claro')],
                selected: 'light',
                onChanged: (String _) {},
              ),
              AppSettingsTile(icon: AppIcons.layoutGrid, title: 'Módulos', onTap: () {}),
            ],
          ),
        ),
      );

      for (final Type type in <Type>[AppIconButton, AppFilterChips<String>, AppChoiceSegment, AppSettingsTile]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final Finder ring = find.descendant(of: find.byType(type), matching: find.byType(AppFocusRing));
        expect(ringVisible(tester, ring), isTrue, reason: '$type');
      }
    });
  });

  group('AppCheckTile con acción', () {
    Widget tile({
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
      bool highlighted = false,
    }) =>
        AppCheckTile(
          title: 'Leche',
          subtitle: '2 litros',
          value: false,
          checkboxLabel: 'Marcar «Leche» como comprado',
          onChanged: (bool _) {},
          onTap: onTap ?? () {},
          action: AppTileAction(icon: AppIcons.pencil, tooltip: 'Editar «Leche»', onPressed: onEdit ?? () {}),
          semanticLabel: 'Leche, 2 litros. Editar',
          semanticActions: <CustomSemanticsAction, VoidCallback>{
            const CustomSemanticsAction(label: 'Borrar «Leche»'): onDelete ?? () {},
          },
          highlighted: highlighted,
        );

    testWidgets('el lápiz llama a su acción y el resto de la fila a onTap', (WidgetTester tester) async {
      int taps = 0;
      int edits = 0;
      await tester.pumpWidget(host(tile(onTap: () => taps++, onEdit: () => edits++)));

      await tester.tap(find.byTooltip('Editar «Leche»'));
      await tester.tap(find.text('Leche'));
      expect(edits, 1);
      expect(taps, 1);
      final Icon pencil = tester.widget<Icon>(find.byIcon(AppIcons.pencil));
      expect(pencil.size, AppSizes.iconCompact);
      expect(tester.getSize(find.byType(AppIconButton)), const Size.square(AppSizes.minTouchTarget));
    });

    testWidgets('la casilla queda centrada con el lápiz', (WidgetTester tester) async {
      await tester.pumpWidget(host(tile()));

      expect(tester.getCenter(find.byType(Checkbox)).dy, tester.getCenter(find.byType(AppIconButton)).dy);
    });

    testWidgets('se lee como un botón con la casilla y el lápiz dentro, y ofrece borrar', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int deletes = 0;
      await tester.pumpWidget(host(tile(onDelete: () => deletes++)));

      final SemanticsNode row = tester.getSemantics(find.bySemanticsLabel('Leche, 2 litros. Editar'));
      final SemanticsData data = row.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.customAction), isTrue);
      expect(find.bySemanticsLabel('Leche'), findsNothing);
      expect(find.bySemanticsLabel('Marcar «Leche» como comprado'), findsOneWidget);
      final SemanticsNode pencil = tester.getSemantics(find.byType(IconButton));
      expect(pencil.getSemanticsData().tooltip, 'Editar «Leche»');
      expect(pencil.id, isNot(row.id));

      final int actionId = CustomSemanticsAction.getIdentifier(const CustomSemanticsAction(label: 'Borrar «Leche»'));
      final SemanticsOwner owner = tester.renderObject(find.byType(AppCheckTile)).owner!.semanticsOwner!;
      owner.performAction(row.id, SemanticsAction.customAction, actionId);
      expect(deletes, 1);
      semantics.dispose();
    });

    testWidgets('resaltada, tiene el fondo de marca', (WidgetTester tester) async {
      await tester.pumpWidget(host(tile(highlighted: true)));
      await tester.pumpAndSettle();

      final AnimatedContainer container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect((container.decoration as BoxDecoration?)?.color, AppThemeColors.light.bgBrandSubtle);
    });

    testWidgets('con el foco del teclado en la fila, el anillo va en la fila y no en el lápiz', (WidgetTester tester) async {
      useKeyboardHighlight();
      await tester.pumpWidget(host(tile()));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final Finder rowRing = find.byType(AppFocusRing).first;
      final Finder pencilRing = find.descendant(of: find.byType(AppIconButton), matching: find.byType(AppFocusRing));
      expect(ringVisible(tester, rowRing), isTrue);
      expect(ringVisible(tester, pencilRing), isFalse);
    });

    testWidgets('cumple las guías con el texto al 200 %', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(tile(), textScale: 2));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AppIconButton)), const Size.square(AppSizes.minTouchTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  });

  group('AppFilterChips con maxVisible', () {
    Widget chips(Set<String> selected, {ValueChanged<Set<String>>? onChanged}) => AppFilterChips<String>(
          label: 'Categorías',
          options: categories,
          selected: selected,
          maxVisible: 4,
          moreLabel: (int hidden) => '$hidden más',
          onChanged: onChanged ?? (Set<String> _) {},
        );

    testWidgets('muestra las primeras y despliega el resto', (WidgetTester tester) async {
      await tester.pumpWidget(host(chips(const <String>{})));

      expect(find.text('Mascotas'), findsOneWidget);
      expect(find.text('Casa'), findsNothing);
      await tester.tap(find.text('2 más'));
      await tester.pump();
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Otros'), findsOneWidget);
      expect(find.text('2 más'), findsNothing);
    });

    testWidgets('si una oculta está elegida, las muestra todas', (WidgetTester tester) async {
      await tester.pumpWidget(host(chips(const <String>{'other'})));

      expect(find.text('Otros'), findsOneWidget);
      expect(find.text('2 más'), findsNothing);
    });

    testWidgets('«N más» se anuncia como botón plegado', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(chips(const <String>{})));

      final SemanticsData data = tester.getSemantics(find.text('2 más')).getSemanticsData();
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);
      semantics.dispose();
    });
  });

  group('AppSwipeToDelete', () {
    Widget row(VoidCallback onDelete) => AppSwipeToDelete(
          label: 'Borrar',
          onDelete: onDelete,
          child: const SizedBox(height: 56, child: Center(child: Text('Leche'))),
        );

    testWidgets('al soltar con la zona entera a la vista, borra', (WidgetTester tester) async {
      int deletes = 0;
      await tester.pumpWidget(host(row(() => deletes++)));

      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Leche')));
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(const Offset(-AppSwipeToDelete.revealWidth - 10, 0));
      await tester.pump();
      expect(find.text('Borrar'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(deletes, 1);
    });

    testWidgets('con menos, la fila vuelve a su sitio', (WidgetTester tester) async {
      int deletes = 0;
      await tester.pumpWidget(host(row(() => deletes++)));
      final Offset start = tester.getTopLeft(find.text('Leche'));

      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Leche')));
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(deletes, 0);
      expect(tester.getTopLeft(find.text('Leche')), start);
      expect(find.text('Borrar'), findsNothing);
    });

    testWidgets('la zona de borrar no se anuncia', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(row(() {})));

      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Leche')));
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      expect(find.bySemanticsLabel('Borrar'), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      semantics.dispose();
    });
  });

  group('AppComposeBar', () {
    Future<TextEditingController> pumpBar(
      WidgetTester tester, {
      List<String>? submitted,
      List<String>? chosen,
      String? errorText,
      String selected = 'food',
      double textScale = 1,
    }) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.bottomCenter,
            child: AppComposeBar<String>(
              label: 'Nombre del ítem nuevo',
              hint: 'Ej.: Leche',
              controller: controller,
              submitTooltip: 'Añadir',
              closeTooltip: 'Cerrar el campo',
              onClose: () {},
              onSubmitted: (String text) {
                submitted?.add(text);
                controller.clear();
              },
              errorText: errorText,
              destinationLabel: 'Se añadirá a',
              destinations: categories.take(3).toList(),
              selectedDestination: selected,
              destinationSemanticLabel: 'Categoría del ítem nuevo: Comida. Cambiar',
              onDestinationChanged: (String value) => chosen?.add(value),
            ),
          ),
          textScale: textScale,
        ),
      );
      await tester.pump();
      return controller;
    }

    bool fieldFocused(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus;

    testWidgets('pide el foco, envía con Intro y con el botón, y lo conserva', (WidgetTester tester) async {
      final List<String> submitted = <String>[];
      await pumpBar(tester, submitted: submitted);
      expect(fieldFocused(tester), isTrue);

      await tester.enterText(find.byType(TextField), 'Pan');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Leche');
      await tester.tap(find.byTooltip('Añadir'));
      await tester.pump();

      expect(submitted, <String>['Pan', 'Leche']);
      expect(fieldFocused(tester), isTrue);
    });

    testWidgets('el chip muestra el destino y despliega las opciones sin quitar el foco', (WidgetTester tester) async {
      final List<String> chosen = <String>[];
      await pumpBar(tester, chosen: chosen);

      expect(find.text('Se añadirá a'), findsOneWidget);
      expect(find.text('Comida'), findsOneWidget);
      expect(find.text('Limpieza'), findsNothing);
      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      expect(find.byIcon(AppIcons.chevronUp), findsOneWidget);
      expect(find.text('Limpieza'), findsOneWidget);
      expect(fieldFocused(tester), isTrue);

      await tester.tap(find.text('Limpieza'));
      await tester.pump();
      expect(chosen, <String>['cleaning']);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(fieldFocused(tester), isTrue);
    });

    testWidgets('el chip se lee con su etiqueta y su estado', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpBar(tester);

      final SemanticsData data =
          tester.getSemantics(find.bySemanticsLabel('Categoría del ítem nuevo: Comida. Cambiar')).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);
      semantics.dispose();
    });

    testWidgets('con error, lo muestra en lugar del destino', (WidgetTester tester) async {
      await pumpBar(tester, errorText: 'Escribe un nombre para añadir el ítem.');

      expect(find.text('Escribe un nombre para añadir el ítem.'), findsOneWidget);
      expect(find.text('Se añadirá a'), findsNothing);
    });

    testWidgets('cumple las guías y no desborda con el texto al 200 %', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpBar(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  });

  group('AppPinnedPanel', () {
    testWidgets('mide lo que su contenido cuando cabe', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[AppPinnedPanel(child: SizedBox(height: 100)), Expanded(child: SizedBox())],
          ),
        ),
      );

      expect(tester.getSize(find.byType(AppPinnedPanel)).height, lessThan(200));
    });

    testWidgets('como mucho la mitad de la pantalla, con el pie siempre a la vista', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppPinnedPanel(
                footer: AppButton(label: 'Listo · 7', onPressed: () {}),
                child: const SizedBox(height: 2000),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );

      final double screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(tester.getSize(find.byType(AppPinnedPanel)).height, lessThanOrEqualTo(screen / 2));
      expect(find.text('Listo · 7').hitTestable(), findsOneWidget);
      expect(find.byType(Scrollbar), findsOneWidget);
    });
  });
}
