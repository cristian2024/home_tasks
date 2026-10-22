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
      children: [
        const AppSectionHeader('Sección'),
        AppButton(label: 'Guardar', onPressed: () {}),
        AppButton(label: 'Secundario', icon: Icons.add, variant: AppButtonVariant.secondary, onPressed: () {}),
        AppButton(label: 'Texto', variant: AppButtonVariant.text, onPressed: () {}),
        AppIconButton(icon: Icons.delete, tooltip: 'Eliminar', onPressed: () {}),
        AppIconButton(icon: Icons.add, tooltip: 'Añadir', variant: AppIconButtonVariant.filled, onPressed: () {}),
        const AppTextField(label: 'Nombre'),
        AppCard(semanticLabel: 'Caja A', onTap: () {}, child: const Text('Caja A')),
      ],
    );

void main() {
  test('AppColors.error es opaco', () {
    expect(AppColors.error.a, 1.0);
  });

  for (final (name, theme) in [('claro', AppTheme.light), ('oscuro', AppTheme.dark)]) {
    testWidgets('tema $name: cumple las guías de accesibilidad', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(gallery(), theme: theme));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }

  testWidgets('AppIconButton expone el tooltip a los lectores de pantalla', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(AppIconButton(icon: Icons.delete, tooltip: 'Eliminar', onPressed: () {})));

    expect(
      tester.getSemantics(find.byType(IconButton)),
      isSemantics(tooltip: 'Eliminar', isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('AppButton con isLoading se desactiva y conserva la etiqueta', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(AppButton(label: 'Guardar', isLoading: true, onPressed: () => taps++)));

    await tester.tap(find.text('Guardar'));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppStatusView no desborda con el texto al 200 %', (tester) async {
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

  testWidgets('showAppConfirmDialog devuelve true al confirmar y false al cancelar', (tester) async {
    final results = <bool>[];
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => AppButton(
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

    expect(results, [true, false]);
  });
}
