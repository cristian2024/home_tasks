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
