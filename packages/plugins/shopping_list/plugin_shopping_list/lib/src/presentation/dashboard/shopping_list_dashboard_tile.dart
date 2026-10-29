import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../domain/use_cases/list_queries.dart';
import '../../i18n/strings.g.dart';
import '../shopping_list_routes.dart';

/// Tarjeta del plugin en la pantalla de inicio: cuánto hay por comprar y
/// cuánto es urgente. Abre la lista.
class ShoppingListDashboardTile extends StatelessWidget {
  const ShoppingListDashboardTile({super.key, required this.watchList});

  final WatchShoppingList watchList;

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$es t = shoppingListStrings.shoppingList;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return AppCard(
      semanticLabel: t.title,
      onTap: () => context.push<void>(ShoppingListRoutes.base),
      child: Row(
        children: <Widget>[
          const ExcludeSemantics(child: Icon(Icons.shopping_cart_outlined, size: AppSizes.iconLarge)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(t.title, style: textTheme.titleMedium),
                StreamBuilder<ShoppingListSnapshot>(
                  stream: watchList(),
                  builder: (BuildContext context, AsyncSnapshot<ShoppingListSnapshot> snapshot) {
                    final List<ShoppingListEntry>? toBuy = snapshot.data?.toBuy;
                    if (toBuy == null) {
                      return Text(t.description, style: textTheme.bodyMedium);
                    }
                    final int urgent = toBuy.where((ShoppingListEntry entry) => entry.item.urgency.isUrgent).length;
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(t.dashboard.toBuyCount(n: toBuy.length), style: textTheme.bodyMedium),
                        if (urgent > 0)
                          AppBadge(
                            label: t.dashboard.urgentCount(n: urgent),
                            tone: AppBadgeTone.critical,
                            icon: Icons.priority_high,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
