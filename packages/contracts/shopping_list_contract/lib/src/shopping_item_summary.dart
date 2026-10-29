import 'package:equatable/equatable.dart';
import 'package:urgency/urgency.dart';

/// Lo que otros plugins ven de un item de la lista de compras. No es la
/// entidad de la lista: solo lo necesario para mostrarlo o enlazarlo.
class ShoppingItemSummary extends Equatable {
  const ShoppingItemSummary({
    required this.id,
    required this.name,
    required this.urgency,
    this.quantity,
    this.categoryNames = const <String>[],
    this.isOverdue = false,
  });

  final String id;
  final String name;
  final Urgency urgency;

  /// Texto libre, p. ej. «2 docenas».
  final String? quantity;

  /// Nombres de sus categorías, en el idioma actual.
  final List<String> categoryNames;

  /// Un item recurrente que ya pasó su ventana.
  final bool isOverdue;

  @override
  List<Object?> get props => <Object?>[id, name, urgency, quantity, categoryNames, isOverdue];
}
