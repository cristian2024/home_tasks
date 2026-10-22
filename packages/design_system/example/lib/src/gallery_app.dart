import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Galería del sistema de diseño. Permite cambiar tema, idioma y escala de
/// texto para revisar los componentes en todas las combinaciones del §14.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  final _localization = LocalizationCoordinator.instance;
  ThemeMode _themeMode = ThemeMode.light;
  double _textScale = 1;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _localization.languageCode,
      builder: (context, languageCode, _) => MaterialApp(
        title: 'design_system',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        locale: Locale(languageCode),
        supportedLocales: LocalizationCoordinator.supportedLocales,
        localizationsDelegates: LocalizationCoordinator.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_textScale)),
          child: child!,
        ),
        home: _GalleryPage(
          isDark: _themeMode == ThemeMode.dark,
          languageCode: languageCode,
          textScale: _textScale,
          onDarkChanged: (dark) => setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light),
          onLanguageChanged: _localization.setLanguage,
          onTextScaleChanged: (scale) => setState(() => _textScale = scale),
        ),
      ),
    );
  }
}

class _GalleryPage extends StatelessWidget {
  const _GalleryPage({
    required this.isDark,
    required this.languageCode,
    required this.textScale,
    required this.onDarkChanged,
    required this.onLanguageChanged,
    required this.onTextScaleChanged,
  });

  final bool isDark;
  final String languageCode;
  final double textScale;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<double> onTextScaleChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('design_system')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const AppSectionHeader('Ajustes de la galería'),
          SwitchListTile(title: const Text('Tema oscuro'), value: isDark, onChanged: onDarkChanged),
          ListTile(
            title: const Text('Idioma'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'es', label: Text('ES')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {languageCode},
              onSelectionChanged: (selection) => onLanguageChanged(selection.single),
            ),
          ),
          ListTile(title: Text('Escala de texto: ${(textScale * 100).round()} %')),
          Slider(
            value: textScale,
            min: 1,
            max: 2,
            divisions: 4,
            label: '${(textScale * 100).round()} %',
            onChanged: onTextScaleChanged,
          ),
          const Divider(),
          const AppSectionHeader('Colores'),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Swatch('primary', AppColors.primary),
              _Swatch('primaryDark', AppColors.primaryDark),
              _Swatch('secondary', AppColors.secondary),
              _Swatch('error', AppColors.error),
              _Swatch('surfaceDark', AppColors.surfaceDark),
              _Swatch('backgroundDark', AppColors.backgroundDark),
            ],
          ),
          const AppSectionHeader('Espaciados'),
          for (final (name, value) in const [
            ('xs', AppSpacing.xs),
            ('sm', AppSpacing.sm),
            ('md', AppSpacing.md),
            ('lg', AppSpacing.lg),
            ('xl', AppSpacing.xl),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(width: 48, child: Text(name)),
                  Container(width: value * 4, height: AppSpacing.sm, color: AppColors.primary),
                ],
              ),
            ),
          const AppSectionHeader('Botones'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(label: commonStrings.common.save, onPressed: () {}),
              AppButton(
                label: commonStrings.common.retry,
                icon: Icons.refresh,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(label: commonStrings.common.cancel, variant: AppButtonVariant.text, onPressed: () {}),
              AppButton(label: commonStrings.common.save, isLoading: true, onPressed: () {}),
              AppButton(label: commonStrings.common.save, onPressed: null),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              AppIconButton(icon: Icons.edit, tooltip: 'Editar', onPressed: () {}),
              AppIconButton(icon: Icons.add, tooltip: 'Añadir', variant: AppIconButtonVariant.filled, onPressed: () {}),
              AppIconButton(
                icon: Icons.qr_code_scanner,
                tooltip: 'Escanear',
                variant: AppIconButtonVariant.tonal,
                onPressed: () {},
              ),
            ],
          ),
          const AppSectionHeader('Campos de texto'),
          const AppTextField(label: 'Nombre', hint: 'Caja de almacenamiento'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Código', errorText: commonStrings.common.requiredField),
          const AppSectionHeader('Tarjetas'),
          AppCard(
            semanticLabel: 'Caja de Almacenamiento Ropa Invierno',
            onTap: () {},
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.inventory_2),
              title: Text('Caja de Almacenamiento Ropa Invierno'),
              subtitle: Text('Estante superior del armario principal'),
            ),
          ),
          const AppSectionHeader('Diálogos'),
          Builder(
            builder: (context) => AppButton(
              label: 'Mostrar confirmación',
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                final confirmed = await showAppConfirmDialog(
                  context,
                  title: '¿Eliminar objeto?',
                  message: 'Esta acción no se puede deshacer.',
                  destructive: true,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(confirmed ? 'Confirmado' : 'Cancelado')),
                  );
                }
              },
            ),
          ),
          const AppSectionHeader('Estados'),
          SizedBox(
            height: 320,
            child: AppCard(
              child: AppStatusView(
                icon: Icons.search_off,
                title: 'Identificador no registrado',
                message: 'Este código no está asociado a ningún objeto.',
                action: AppButton(label: commonStrings.common.retry, onPressed: () {}),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(height: 96, child: AppCard(child: AppLoadingView())),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.small),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        Text(name, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
