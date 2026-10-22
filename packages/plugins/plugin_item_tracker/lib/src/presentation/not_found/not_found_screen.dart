import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/physical_identifier.dart';
import '../../i18n/strings.g.dart';
import '../common/item_tracker_l10n.dart';
import '../item_tracker_routes.dart';

/// Identificador desconocido (AC-04): crear un objeto nuevo o asociarlo a uno
/// existente. Devuelve con `pop` el ID del objeto resultante.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.identifier});

  final ({String rawValue, IdentifierType type}) identifier;

  Future<void> _open(BuildContext context, String path) async {
    final itemId = await context.push<String>(ItemTrackerRoutes.withIdentifier(path, identifier));
    if (itemId != null && context.mounted) {
      context.pop(itemId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = itemTrackerStrings.itemTracker.notFound;
    final type = identifierTypeLabel(identifier.type);
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: AppStatusView(
        icon: Icons.search_off,
        title: t.title,
        message: '${t.message(type: type)}\n\n${identifier.rawValue}',
        action: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: t.create,
              icon: Icons.add,
              expand: true,
              onPressed: () => _open(context, ItemTrackerRoutes.create),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: t.associate,
              icon: Icons.link,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => _open(context, ItemTrackerRoutes.associate),
            ),
          ],
        ),
      ),
    );
  }
}
