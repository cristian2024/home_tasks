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
    final ItemTrackerTranslations$itemTracker$es t = itemTrackerStrings.itemTracker;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const ExcludeSemantics(child: Icon(Icons.qr_code_scanner, size: AppSizes.iconLarge)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(header: true, child: Text(t.title, style: textTheme.titleMedium)),
                    StreamBuilder<List<HouseholdItem>>(
                      stream: watchItems(),
                      builder: (BuildContext context, AsyncSnapshot<List<HouseholdItem>> snapshot) => Text(
                        snapshot.hasData ? t.dashboard.itemsCount(n: snapshot.data!.length) : t.description,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              AppButton(
                label: t.dashboard.scan,
                icon: Icons.qr_code_scanner,
                onPressed: () => context.push<void>(ItemTrackerRoutes.scan),
              ),
              AppButton(
                label: t.dashboard.items,
                icon: Icons.inventory_2_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push<void>(ItemTrackerRoutes.items),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
