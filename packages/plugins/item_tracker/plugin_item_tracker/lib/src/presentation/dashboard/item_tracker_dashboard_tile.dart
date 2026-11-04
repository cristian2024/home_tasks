import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../domain/use_cases/item_queries.dart';
import '../../i18n/strings.g.dart';
import '../item_tracker_routes.dart';

/// Tarjeta del plugin en la pantalla de inicio.
class ItemTrackerDashboardTile extends StatelessWidget {
  const ItemTrackerDashboardTile({super.key, required this.watchItems});

  final WatchItems watchItems;

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$es strings = itemTrackerStrings.itemTracker;
    return StreamBuilder<List<HouseholdItem>>(
      stream: watchItems(),
      builder: (BuildContext context, AsyncSnapshot<List<HouseholdItem>> snapshot) {
        final List<HouseholdItem>? items = snapshot.data;
        return AppModuleCard(
          icon: Icons.qr_code_scanner,
          title: strings.title,
          summary: items == null ? strings.description : strings.dashboard.itemsCount(n: items.length),
          actions: <Widget>[
            AppButton(
              label: strings.dashboard.scan,
              icon: Icons.qr_code_scanner,
              onPressed: () => context.push<void>(ItemTrackerRoutes.scan),
            ),
            AppButton(
              label: strings.dashboard.items,
              icon: Icons.inventory_2_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push<void>(ItemTrackerRoutes.items),
            ),
          ],
        );
      },
    );
  }
}
