import 'package:flutter/material.dart';

import 'app_section_header.dart';

/// Grupo de ajustes con título: los [children] (normalmente
/// [AppSettingsTile] o [AppChoiceSelector]) van dentro de una tarjeta,
/// separados por líneas.
class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title),
        Card(
          clipBehavior: Clip.antiAlias,
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
