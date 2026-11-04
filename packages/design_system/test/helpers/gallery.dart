import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

Widget host(Widget child, {ThemeData? theme, double textScale = 1}) => MaterialApp(
      theme: theme ?? AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    );

Widget gallery() => ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        const AppSectionHeader('Sección'),
        AppButton(label: 'Guardar', onPressed: () {}),
        AppButton(label: 'Secundario', icon: Icons.add, variant: AppButtonVariant.secondary, onPressed: () {}),
        AppButton(label: 'Borde', icon: Icons.save_alt, variant: AppButtonVariant.outline, onPressed: () {}),
        AppButton(label: 'Texto', variant: AppButtonVariant.text, onPressed: () {}),
        AppIconButton(icon: Icons.delete, tooltip: 'Eliminar', onPressed: () {}),
        AppIconButton(icon: Icons.add, tooltip: 'Añadir', variant: AppIconButtonVariant.filled, onPressed: () {}),
        const AppTextField(label: 'Nombre'),
        AppCard(semanticLabel: 'Caja A', onTap: () {}, child: const Text('Caja A')),
        SizedBox(
          height: 240,
          child: AppShortcutGrid(
            children: <Widget>[
              AppShortcutTile(icon: Icons.qr_code_scanner, label: 'Objetos', onTap: () {}),
              AppShortcutTile(label: 'Falló', error: true, tooltip: 'No se pudo iniciar', onTap: () {}),
              AppShortcutTile(icon: Icons.add, label: 'Añadir', onTap: () {}),
            ],
          ),
        ),
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
            AppSettingsTile(icon: Icons.logout, title: 'Salir del hogar', destructive: true, onTap: () {}),
            const AppSettingsTile(
              icon: Icons.import_export,
              title: 'Exportar / importar datos',
              subtitle: 'Próximamente',
              enabled: false,
            ),
          ],
        ),
        AppFilterChips<String>(
          label: 'Categorías',
          options: const <AppChoice<String>>[
            AppChoice<String>(value: 'food', label: 'Comida'),
            AppChoice<String>(value: 'home', label: 'Hogar', icon: Icons.home_outlined),
          ],
          selected: const <String>{'food'},
          onChanged: (Set<String> _) {},
        ),
        AppCheckTile(
          title: 'Huevos',
          subtitle: '2 docenas',
          value: false,
          checkboxLabel: 'Marcar como comprado',
          onChanged: (bool _) {},
          onTap: () {},
          badges: const <Widget>[
            AppBadge(label: 'Inmediata', tone: AppBadgeTone.critical, icon: Icons.priority_high),
            AppBadge(label: 'Toca pronto', tone: AppBadgeTone.warning),
            AppBadge(label: 'Comida'),
            AppBadge(label: 'Nuevo', tone: AppBadgeTone.brand),
            AppBadge(label: 'Activo', tone: AppBadgeTone.success),
          ],
        ),
        AppCheckTile(title: 'Pan', value: true, checkboxLabel: 'Marcar como comprado', onChanged: (bool _) {}),
        AppModuleCard(
          icon: Icons.shopping_cart_outlined,
          title: 'Lista de compras',
          summary: '5 cosas por comprar',
          badges: const <Widget>[AppBadge(label: '2 urgentes', tone: AppBadgeTone.critical)],
          onTap: () {},
        ),
        AppModuleCard(
          icon: Icons.qr_code_scanner,
          title: 'Seguimiento de Objetos',
          summary: '12 objetos registrados',
          actions: <Widget>[
            AppButton(label: 'Escanear', icon: Icons.qr_code_scanner, onPressed: () {}),
            AppButton(label: 'Ver objetos', variant: AppButtonVariant.secondary, onPressed: () {}),
          ],
        ),
        AppSyncStatusCard(
          tone: AppSyncTone.idle,
          title: 'Sincronizado hace 5 min',
          details: const <String>['2 dispositivos a la vista'],
          actionLabel: 'Sincronizar ahora',
          onAction: () {},
        ),
        const AppSyncStatusCard(tone: AppSyncTone.error, title: 'No se pudo sincronizar', message: 'Revisa la WiFi.'),
        AppConflictCard<String>(
          title: 'Etiqueta en dos objetos',
          message: 'La etiqueta NFC se asoció a la vez a dos objetos.',
          options: const <AppConflictOption<String>>[
            AppConflictOption<String>(value: 'a', label: 'Caja A', description: 'La etiqueta queda en «Caja A».'),
            AppConflictOption<String>(value: 'b', label: 'Caja B'),
          ],
          applied: 'a',
          appliedLabel: 'Aplicada ahora',
          onSelected: (String _) {},
          keepLabel: 'Dejarlo así',
          onKeep: () {},
        ),
      ],
    );
