import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';

import 'demo_data.dart';

/// Anfitrión mínimo del plugin: inicio con su tarjeta de dashboard y sus
/// rutas. Recibe el plugin ya inicializado para poder probarlo con fakes.
class ShoppingListExampleApp extends StatefulWidget {
  const ShoppingListExampleApp({
    super.key,
    required this.plugin,
    required this.locator,
    required this.localization,
  });

  final ShoppingListPlugin plugin;
  final ServiceLocator locator;
  final LocalizationCoordinator localization;

  @override
  State<ShoppingListExampleApp> createState() => _ShoppingListExampleAppState();
}

class _ShoppingListExampleAppState extends State<ShoppingListExampleApp> {
  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, _) => LanguageRebuilder(
          child: _HomePage(
            plugin: widget.plugin,
            localization: widget.localization,
            demoData: DemoData(
              widget.locator.get<ShoppingListDependencies>(),
              widget.locator.get<ShoppingListRepository>(),
            ),
            isDark: _themeMode == ThemeMode.dark,
            onDarkChanged: (bool dark) => setState(
              () => _themeMode = dark ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
        ),
      ),
      // Mismo envoltorio que `withLanguageRebuild` de apps/app.
      for (final RouteBase route in widget.plugin.routes)
        if (route is GoRoute && route.builder != null)
          GoRoute(
            path: route.path,
            redirect: route.redirect,
            builder: (BuildContext context, GoRouterState state) =>
                LanguageRebuilder(child: route.builder!(context, state)),
          )
        else
          route,
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
    return LanguageScope(
      languageCode: widget.localization.languageCode,
      child: ValueListenableBuilder<String>(
        valueListenable: widget.localization.languageCode,
        builder: (BuildContext context, String languageCode, _) => MaterialApp.router(
          title: 'shopping_list',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeMode,
          locale: Locale(languageCode),
          supportedLocales: LocalizationCoordinator.supportedLocales,
          localizationsDelegates: LocalizationCoordinator.localizationsDelegates,
          routerConfig: _router,
        ),
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

  final ShoppingListPlugin plugin;
  final LocalizationCoordinator localization;
  final DemoData demoData;
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  Future<void> _loadDemoData(BuildContext context) async {
    final int created = await demoData.load();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              created == 0
                  ? 'Los datos de ejemplo ya estaban cargados.'
                  : 'Datos de ejemplo cargados: $created items.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('shopping_list · ejemplo')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          plugin.buildDashboardTile(context),
          const AppSectionHeader('Ajustes del ejemplo'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Idioma'),
            trailing: ValueListenableBuilder<String>(
              valueListenable: localization.languageCode,
              builder: (BuildContext context, String languageCode, _) => SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'es', label: Text('ES')),
                  ButtonSegment<String>(value: 'en', label: Text('EN')),
                ],
                selected: <String>{languageCode},
                onSelectionChanged: (Set<String> selection) => localization.setLanguage(selection.single),
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
        ],
      ),
    );
  }
}
