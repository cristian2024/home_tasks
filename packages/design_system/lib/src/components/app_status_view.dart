import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

/// Estado vacío, de error o informativo a pantalla completa. Hace scroll para
/// no desbordarse con el texto al 200 %.
class AppStatusView extends StatelessWidget {
  const AppStatusView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExcludeSemantics(child: Icon(icon, size: AppSizes.iconLarge)),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(message!, style: textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (action != null) ...<Widget>[const SizedBox(height: AppSpacing.lg), action!],
          ],
        ),
      ),
    );
  }
}
