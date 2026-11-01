import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../i18n/strings.g.dart';
import '../navigation/app_router.dart';
import 'app_settings.dart';
import 'app_settings_controller.dart';

/// Configuración de la app: tema, idioma, acceso al catálogo de módulos, a
/// los espacios de datos (con [showSpaces]), a la sincronización (con
/// [showSync]) y, más adelante, exportar e importar los datos.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.showSync = false, this.showSpaces = false});

  /// Si se compuso la sincronización.
  final bool showSync;

  /// Si la app tiene espacios de datos.
  final bool showSpaces;

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$settings$es t = appStrings.app.settings;
    final AppSettingsController controller = context.read<AppSettingsController>();
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocBuilder<AppSettingsController, AppSettings>(
        builder: (BuildContext context, AppSettings settings) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            AppSettingsSection(
              title: t.appearance,
              children: <Widget>[
                AppChoiceSelector<AppThemePreference>(
                  label: t.theme,
                  icon: Icons.palette_outlined,
                  options: <AppChoice<AppThemePreference>>[
                    AppChoice<AppThemePreference>(
                      value: AppThemePreference.system,
                      label: t.themeSystem,
                      icon: Icons.brightness_auto_outlined,
                    ),
                    AppChoice<AppThemePreference>(
                      value: AppThemePreference.light,
                      label: t.themeLight,
                      icon: Icons.light_mode_outlined,
                    ),
                    AppChoice<AppThemePreference>(
                      value: AppThemePreference.dark,
                      label: t.themeDark,
                      icon: Icons.dark_mode_outlined,
                    ),
                  ],
                  selected: settings.theme,
                  onChanged: controller.setTheme,
                ),
              ],
            ),
            AppSettingsSection(
              title: t.languageSection,
              children: <Widget>[
                AppChoiceSelector<String?>(
                  label: t.language,
                  icon: Icons.language,
                  options: <AppChoice<String?>>[
                    AppChoice<String?>(value: null, label: t.languageSystem),
                    // Cada idioma con su propio nombre, para encontrarlo aunque
                    // la app esté en otro.
                    AppChoice<String?>(value: 'es', label: appStrings.app.languages.es),
                    AppChoice<String?>(value: 'en', label: appStrings.app.languages.en),
                  ],
                  selected: settings.languageCode,
                  onChanged: controller.setLanguage,
                ),
              ],
            ),
            AppSettingsSection(
              title: t.modulesSection,
              children: <Widget>[
                AppSettingsTile(
                  icon: Icons.extension_outlined,
                  title: t.modules,
                  subtitle: t.modulesDescription,
                  onTap: () => context.push(AppRoutes.catalog),
                ),
              ],
            ),
            if (showSpaces)
              AppSettingsSection(
                title: appStrings.app.spaces.section,
                children: <Widget>[
                  AppSettingsTile(
                    icon: Icons.workspaces_outlined,
                    title: appStrings.app.spaces.tile,
                    subtitle: appStrings.app.spaces.createDescription,
                    onTap: () => context.push(AppRoutes.spaces),
                  ),
                ],
              ),
            if (showSync)
              AppSettingsSection(
                title: appStrings.app.sync.section,
                children: <Widget>[
                  AppSettingsTile(
                    icon: Icons.sync,
                    title: appStrings.app.sync.tile,
                    subtitle: appStrings.app.sync.tileDescription,
                    onTap: () => context.push(AppRoutes.sync),
                  ),
                ],
              ),
            AppSettingsSection(
              title: t.dataSection,
              children: <Widget>[
                AppSettingsTile(
                  icon: Icons.import_export,
                  title: t.exportImport,
                  subtitle: t.comingSoon,
                  enabled: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
