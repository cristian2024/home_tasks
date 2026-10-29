import 'package:equatable/equatable.dart';

/// Una vez que se compró un item. El historial permite deshacer una compra y,
/// más adelante, calcular cada cuánto se compra de verdad.
class ShoppingPurchase extends Equatable {
  const ShoppingPurchase({required this.id, required this.itemId, required this.purchasedAt});

  final String id; // UUID v4
  final String itemId;
  final DateTime purchasedAt; // UTC

  @override
  List<Object?> get props => <Object?>[id, itemId, purchasedAt];
}
