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
    return StreamBuilder<ShoppingListSnapshot>(
      stream: watchList(),
      builder: (BuildContext context, AsyncSnapshot<ShoppingListSnapshot> snapshot) {
        final List<ShoppingListEntry>? toBuy = snapshot.data?.toBuy;
        final int urgent = toBuy?.where((ShoppingListEntry entry) => entry.item.urgency.isUrgent).length ?? 0;
        return AppModuleCard(
          icon: Icons.shopping_cart_outlined,
          title: t.title,
          summary: toBuy == null ? t.description : t.dashboard.toBuyCount(n: toBuy.length),
          badges: <Widget>[
            if (urgent > 0)
              AppBadge(label: t.dashboard.urgentCount(n: urgent), tone: AppBadgeTone.critical, icon: Icons.priority_high),
          ],
          onTap: () => context.push<void>(ShoppingListRoutes.base),
        );
      },
    );
  }
}
