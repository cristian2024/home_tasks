import 'package:core_sync/core_sync.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';

import '../i18n/strings.g.dart';

/// Textos de un conflicto para la bandeja: qué pasó y cómo se llama cada
/// opción.
class ConflictDescription {
  const ConflictDescription({required this.title, required this.message, required this.optionLabels});

  /// Describe [conflict] con los textos de la app. [itemNames] da el nombre de
  /// los objetos de item_tracker; los que falten (p. ej. ya borrados) se
  /// nombran de forma genérica.
  factory ConflictDescription.of(SyncConflict conflict, Map<String, String> itemNames) {
    final AppTranslations$app$sync$conflicts$es t = appStrings.app.sync.conflicts;
    String name(String id) => itemNames[id] ?? t.unknownItem;
    final String first = name(conflict.entityIds.first);
    switch (conflict.kind) {
      case ItemTrackerResolver.containerDeleted:
        final String container = name(conflict.entityIds.last);
        return ConflictDescription(
          title: t.containerDeletedTitle,
          message: t.containerDeletedMessage(container: container, item: first),
          optionLabels: <String, String>{
            ItemTrackerResolver.keepOption: t.containerDeletedKeep(item: first),
            ItemTrackerResolver.deleteOption: t.containerDeletedDelete(item: first),
          },
        );
      case ItemTrackerResolver.moveReverted:
        return ConflictDescription(
          title: t.moveRevertedTitle,
          message: t.moveRevertedMessage(item: first),
          optionLabels: <String, String>{ItemTrackerResolver.confirmOption: t.moveRevertedConfirm},
        );
      case ItemTrackerResolver.identifierBoundTwice:
        return ConflictDescription(
          title: t.identifierTwiceTitle,
          message: t.identifierTwiceMessage(value: conflict.options.first.details['rawValue'] ?? ''),
          optionLabels: <String, String>{
            for (final ConflictOption option in conflict.options)
              option.id: t.identifierTwiceKeep(item: name(option.details['itemId'] ?? '')),
          },
        );
      case ShoppingListResolver.doublePurchase:
        final String product = conflict.options.first.details['name'] ?? '';
        return ConflictDescription(
          title: t.doublePurchaseTitle,
          message: t.doublePurchaseMessage(name: product),
          optionLabels: <String, String>{
            ShoppingListResolver.oneOption: t.doublePurchaseOne,
            ShoppingListResolver.twoOption: t.doublePurchaseTwo,
          },
        );
    }
    return ConflictDescription(title: t.unknownTitle, message: t.unknownMessage, optionLabels: const <String, String>{});
  }

  final String title;
  final String message;
  final Map<String, String> optionLabels;

  /// Texto de la opción [optionId]; si no se conoce, uno genérico.
  String labelOf(String optionId) => optionLabels[optionId] ?? appStrings.app.sync.conflicts.unknownOption(option: optionId);
}
