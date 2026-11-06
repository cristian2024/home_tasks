import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Acciones fijas al pie de una pantalla, apiladas y a todo el ancho. Se usa
/// debajo del contenido, así sube con el teclado, o como
/// `Scaffold.bottomNavigationBar` si la pantalla no tiene campos.
class AppFooterActions extends StatelessWidget {
  const AppFooterActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.s300, AppSpacing.md, AppSpacing.s0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: children,
          ),
        ),
      );
}
