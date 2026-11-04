import 'package:core_events/core_events.dart';
import 'package:core_utils/core_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:shopping_list_contract/shopping_list_contract.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

/// Lo necesario para deshacer una compra.
class ShoppingPurchaseReceipt extends Equatable {
  const ShoppingPurchaseReceipt({required this.previous, required this.purchaseId});

  /// El item como estaba antes de comprarlo.
  final ShoppingItem previous;
  final String purchaseId;

  @override
  List<Object?> get props => <Object?>[previous, purchaseId];
}

/// Marca un item como comprado: guarda la compra en el historial y la fecha
/// en el item. Uno normal pasa a comprado; uno recurrente sigue pendiente y
/// espera a su siguiente ventana. Publica [ShoppingItemPurchased].
class MarkShoppingItemPurchased {
  const MarkShoppingItemPurchased(this._repository, this._ids, this._clock, this._eventBus);

  final ShoppingListRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;
  final EventBus _eventBus;

  /// Devuelve `null` (sin escribir nada) si el item ya estaba comprado.
  Future<ShoppingPurchaseReceipt?> call(String itemId) async {
    final ShoppingItem item = await _repository.getItem(itemId) ?? (throw ShoppingItemNotFoundException(itemId));
    if (item.status == ShoppingItemStatus.purchased) {
      return null;
    }
    final DateTime now = _clock.nowUtc();
    final ShoppingPurchase purchase = ShoppingPurchase(id: _ids.newId(), itemId: itemId, purchasedAt: now);
    await _repository.recordPurchase(
      item.copyWith(
        status: item.isRecurring ? ShoppingItemStatus.pending : ShoppingItemStatus.purchased,
        lastPurchasedAt: () => now,
        updatedAt: now,
      ),
      purchase,
    );
    _eventBus.publish(ShoppingItemPurchased(itemId: itemId, itemName: item.name, purchasedAt: now));
    return ShoppingPurchaseReceipt(previous: item, purchaseId: purchase.id);
  }
}

/// Deshace una compra: el item vuelve a como estaba y la compra sale del
/// historial.
class UndoShoppingPurchase {
  const UndoShoppingPurchase(this._repository, this._clock);

  final ShoppingListRepository _repository;
  final Clock _clock;

  Future<void> call(ShoppingPurchaseReceipt receipt) {
    final DateTime now = _clock.nowUtc();
    return _repository.undoPurchase(receipt.previous.copyWith(updatedAt: now), receipt.purchaseId, deletedAt: now);
  }
}

/// Vuelve a poner pendiente un item comprado. El historial no cambia.
class MarkShoppingItemPending {
  const MarkShoppingItemPending(this._repository, this._clock);

  final ShoppingListRepository _repository;
  final Clock _clock;

  Future<void> call(String itemId, {Urgency? urgency}) async {
    final ShoppingItem item = await _repository.getItem(itemId) ?? (throw ShoppingItemNotFoundException(itemId));
    if (item.status == ShoppingItemStatus.pending && (urgency == null || urgency == item.urgency)) {
      return;
    }
    await _repository.saveItem(
      item.copyWith(status: ShoppingItemStatus.pending, urgency: urgency, updatedAt: _clock.nowUtc()),
    );
  }
}

/// Borra los items comprados (los recurrentes nunca lo están). Devuelve
/// cuántos borró.
class ClearPurchasedShoppingItems {
  const ClearPurchasedShoppingItems(this._repository, [this._clock = const SystemClock()]);

  final ShoppingListRepository _repository;
  final Clock _clock;

  Future<int> call() async {
    final List<String> ids = <String>[
      for (final ShoppingItem item in await _repository.getItems())
        if (item.status == ShoppingItemStatus.purchased) item.id,
    ];
    if (ids.isNotEmpty) {
      await _repository.deleteItems(ids, deletedAt: _clock.nowUtc());
    }
    return ids.length;
  }
}
