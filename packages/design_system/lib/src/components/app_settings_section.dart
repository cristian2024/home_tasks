import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import 'app_section_header.dart';

/// Grupo de ajustes con título: los [children] (normalmente
/// [AppSettingsTile] o [AppChoiceSelector]) van dentro de una tarjeta,
/// separados por líneas.
class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({super.key, this.title, required this.children});

  /// Sin título, solo la tarjeta.
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title case final String title?) AppSectionHeader(title),
        Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: Column(
            children: <Widget>[
              for (final (int index, Widget child) in children.indexed) ...<Widget>[
                if (index > 0) const Divider(height: 1),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
