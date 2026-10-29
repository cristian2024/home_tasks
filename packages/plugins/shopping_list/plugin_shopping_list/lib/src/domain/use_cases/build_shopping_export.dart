import 'package:list_export/list_export.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import 'category_use_cases.dart';

/// Textos del export, ya traducidos. Los pone la presentación.
class ShoppingExportTexts {
  const ShoppingExportTexts({
    required this.title,
    required this.uncategorized,
    required this.urgency,
    required this.categoryName,
    this.footer,
  });

  final String title;
  final String uncategorized;
  final String Function(Urgency urgency) urgency;
  final ShoppingCategoryNamer categoryName;
  final String? footer;
}

/// Arma el documento a exportar con lo que hay que comprar de [entries]
/// (lo que espera o ya se compró no sale), agrupado como [grouping].
///
/// Por categoría, un item sale una vez bajo su primera categoría y las demás
/// van entre paréntesis en el detalle. Por urgencia, sus categorías van en el
/// detalle. Lo urgente sale resaltado.
class BuildShoppingExport {
  const BuildShoppingExport();

  ExportDocument call(List<ShoppingListEntry> entries, ShoppingGrouping grouping, ShoppingExportTexts texts) {
    final List<ShoppingListEntry> toBuy = entries.where((ShoppingListEntry entry) => entry.state.isToBuy).toList();
    return ExportDocument(
      title: texts.title,
      footer: texts.footer,
      sections: <ExportSection>[
        for (final ShoppingGroup group in ShoppingListView.group(toBuy, grouping))
          ExportSection(
            heading: switch (group) {
              ShoppingGroup(urgency: final Urgency urgency) => texts.urgency(urgency),
              ShoppingGroup(category: final ShoppingCategory category) => texts.categoryName(category),
              _ => texts.uncategorized,
            },
            entries: <ExportEntry>[
              for (final ShoppingListEntry entry in group.entries) _entry(entry, grouping, texts),
            ],
          ),
      ],
    );
  }

  ExportEntry _entry(ShoppingListEntry entry, ShoppingGrouping grouping, ShoppingExportTexts texts) {
    final List<ShoppingCategory> listed =
        grouping == ShoppingGrouping.category ? entry.categories.skip(1).toList() : entry.categories;
    final String categories = listed.map(texts.categoryName).join(', ');
    final String detail = <String>[
      if (entry.item.quantity.isNotEmpty) entry.item.quantity,
      if (categories.isNotEmpty) '($categories)',
    ].join(' ');
    return ExportEntry(
      text: entry.item.name,
      detail: detail.isEmpty ? null : detail,
      emphasized: entry.item.urgency.isUrgent,
    );
  }
}
