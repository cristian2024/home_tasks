import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

import 'demo_data.dart';

/// Anfitrión mínimo del plugin: inicio con su tarjeta de dashboard y sus
/// rutas. Recibe el plugin ya inicializado para poder probarlo con fakes.
class ItemTrackerExampleApp extends StatefulWidget {
  const ItemTrackerExampleApp({
    super.key,
    required this.plugin,
    required this.locator,
    required this.localization,
  });

  final ItemTrackerPlugin plugin;
  final ServiceLocator locator;
  final LocalizationCoordinator localization;

  @override
  State<ItemTrackerExampleApp> createState() => _ItemTrackerExampleAppState();
}

class _ItemTrackerExampleAppState extends State<ItemTrackerExampleApp> {
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => _HomePage(
          plugin: widget.plugin,
          localization: widget.localization,
          demoData: DemoData(widget.locator.get<ItemTrackerDependencies>()),
          isDark: _themeMode == ThemeMode.dark,
          onDarkChanged: (dark) => setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light),
        ),
      ),
      ...widget.plugin.routes,
    ],
  );
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.localization.languageCode,
      builder: (context, languageCode, _) => MaterialApp.router(
        title: 'item_tracker',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        locale: Locale(languageCode),
        supportedLocales: LocalizationCoordinator.supportedLocales,
        localizationsDelegates: LocalizationCoordinator.localizationsDelegates,
        routerConfig: _router,
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.plugin,
    required this.localization,
    required this.demoData,
    required this.isDark,
    required this.onDarkChanged,
  });

  final ItemTrackerPlugin plugin;
  final LocalizationCoordinator localization;
  final DemoData demoData;
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  Future<void> _loadDemoData(BuildContext context) async {
    final created = await demoData.load();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              created == 0 ? 'Los datos de ejemplo ya estaban cargados.' : 'Datos de ejemplo cargados: $created objetos.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('item_tracker · ejemplo')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          plugin.buildDashboardTile(context),
          const AppSectionHeader('Ajustes del ejemplo'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Idioma'),
            trailing: ValueListenableBuilder<String>(
              valueListenable: localization.languageCode,
              builder: (context, languageCode, _) => SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'es', label: Text('ES')),
                  ButtonSegment(value: 'en', label: Text('EN')),
                ],
                selected: {languageCode},
                onSelectionChanged: (selection) => localization.setLanguage(selection.single),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tema oscuro'),
            value: isDark,
            onChanged: onDarkChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Cargar datos de ejemplo',
            icon: Icons.dataset,
            variant: AppButtonVariant.secondary,
            onPressed: () => _loadDemoData(context),
          ),
          const AppSectionHeader('Códigos para probar'),
          for (final (code, description) in DemoData.codes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: SelectableText(code),
              subtitle: Text(description),
            ),
        ],
      ),
    );
  }
}
