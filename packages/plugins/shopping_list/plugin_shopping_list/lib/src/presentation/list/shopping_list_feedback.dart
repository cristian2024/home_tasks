import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/use_cases/purchase_use_cases.dart';
import '../../i18n/strings.g.dart';
import '../common/shopping_list_l10n.dart';
import 'shopping_list_cubit.dart';

/// Cuánto se ofrece deshacer.
const Duration shoppingUndoDuration = Duration(seconds: 5);

/// Anuncia [message] a los lectores de pantalla sin mover el foco.
void announce(BuildContext context, String message) =>
    unawaited(SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context)));

/// Muestra [snackBar] en lugar del que hubiera, para que no se queden en cola.
void showShoppingSnackBar(BuildContext context, SnackBar snackBar) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(snackBar);

/// Los avisos que comparten la lista, los comprados y lo que espera: errores
/// y «Deshacer» de compras, borrados y vueltas a pendiente. Se llama con cada
/// cambio de estado.
void showShoppingFeedback(BuildContext context, ShoppingListState previous, ShoppingListState current) {
  final ShoppingListTranslations$shoppingList$list$es listStrings = shoppingListStrings.shoppingList.list;
  final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
  final Object? error = current.error;
  if (error != null && error != previous.error) {
    cubit.clearError();
    showShoppingSnackBar(context, SnackBar(content: Text(errorMessage(error))));
    return;
  }
  SnackBar undoSnackBar(String message, VoidCallback undo) => SnackBar(
        content: Text(message),
        // Con acción, un SnackBar no se cierra solo salvo que se indique.
        action: SnackBarAction(label: listStrings.undo, onPressed: undo),
        duration: shoppingUndoDuration,
        persist: false,
      );
  final ShoppingPurchaseReceipt? purchase = current.lastPurchase;
  if (purchase != null && purchase != previous.lastPurchase) {
    showShoppingSnackBar(
      context,
      undoSnackBar(listStrings.purchasedSnack(name: purchase.previous.name), cubit.undoLastPurchase),
    );
    return;
  }
  final ShoppingDeletion? deletion = current.lastDeletion;
  if (deletion != null && deletion != previous.lastDeletion) {
    final String name = deletion.item.name;
    showShoppingSnackBar(
      context,
      undoSnackBar(
        deletion.showSwipeTip ? listStrings.deletedTipSnack(name: name) : listStrings.deletedSnack(name: name),
        cubit.undoLastDeletion,
      ),
    );
    return;
  }
  final ShoppingReopening? reopening = current.lastReopening;
  if (reopening != null && reopening != previous.lastReopening) {
    showShoppingSnackBar(
      context,
      undoSnackBar(listStrings.pendingAgain(name: reopening.previous.name), cubit.undoLastReopening),
    );
  }
}
