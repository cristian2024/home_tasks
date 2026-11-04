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
    final AppTranslations$app$settings$es settingsStrings = appStrings.app.settings;
    final AppSettingsController controller = context.read<AppSettingsController>();
    final AppTranslations$app$languages$es languages = appStrings.app.languages;
    final AppTranslations$app$spaces$es spacesStrings = appStrings.app.spaces;
    final AppTranslations$app$sync$es syncStrings = appStrings.app.sync;
    return Scaffold(
      appBar: AppBar(title: Text(settingsStrings.title)),
      body: BlocBuilder<AppSettingsController, AppSettings>(
        builder: (BuildContext context, AppSettings settings) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            AppSectionHeader(settingsStrings.appearance),
            AppChoiceSelector<AppThemePreference>(
              label: settingsStrings.theme,
              padding: EdgeInsets.zero,
              options: <AppChoice<AppThemePreference>>[
                AppChoice<AppThemePreference>(value: AppThemePreference.system, label: settingsStrings.themeSystem),
                AppChoice<AppThemePreference>(value: AppThemePreference.light, label: settingsStrings.themeLight),
                AppChoice<AppThemePreference>(value: AppThemePreference.dark, label: settingsStrings.themeDark),
              ],
              selected: settings.theme,
              onChanged: controller.setTheme,
            ),
            AppSectionHeader(settingsStrings.languageSection),
            AppChoiceSelector<String?>(
              label: settingsStrings.language,
              padding: EdgeInsets.zero,
              options: <AppChoice<String?>>[
                AppChoice<String?>(value: null, label: settingsStrings.languageSystem),
                // Cada idioma con su propio nombre, para encontrarlo aunque
                // la app esté en otro.
                AppChoice<String?>(value: 'es', label: languages.es),
                AppChoice<String?>(value: 'en', label: languages.en),
              ],
              selected: settings.languageCode,
              onChanged: controller.setLanguage,
            ),
            AppSettingsSection(
              title: settingsStrings.modulesSection,
              children: <Widget>[
                AppSettingsTile(
                  icon: Icons.extension_outlined,
                  title: settingsStrings.modules,
                  subtitle: settingsStrings.modulesDescription,
                  onTap: () => context.push(AppRoutes.catalog),
                ),
              ],
            ),
            if (showSpaces)
              AppSettingsSection(
                title: spacesStrings.section,
                children: <Widget>[
                  AppSettingsTile(
                    icon: Icons.workspaces_outlined,
                    title: spacesStrings.tile,
                    subtitle: spacesStrings.createDescription,
                    onTap: () => context.push(AppRoutes.spaces),
                  ),
                ],
              ),
            if (showSync)
              AppSettingsSection(
                title: syncStrings.section,
                children: <Widget>[
                  AppSettingsTile(
                    icon: Icons.sync,
                    title: syncStrings.tile,
                    subtitle: syncStrings.tileDescription,
                    onTap: () => context.push(AppRoutes.sync),
                  ),
                ],
              ),
            AppSettingsSection(
              title: settingsStrings.dataSection,
              children: <Widget>[
                AppSettingsTile(
                  icon: Icons.import_export,
                  title: settingsStrings.exportImport,
                  subtitle: settingsStrings.comingSoon,
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
