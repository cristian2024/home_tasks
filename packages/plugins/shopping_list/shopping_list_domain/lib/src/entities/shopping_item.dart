import 'package:equatable/equatable.dart';
import 'package:recurrence/recurrence.dart';
import 'package:urgency/urgency.dart';

/// Estado guardado de un item.
enum ShoppingItemStatus { pending, purchased }

/// Estado que se muestra, derivado del guardado, la recurrencia y la hora
/// ([ShoppingItem.stateAt]).
enum ShoppingItemState {
  /// Un item recurrente que pasó su ventana sin comprarse.
  overdue,

  /// Hay que comprarlo: un item normal pendiente o uno recurrente cuya
  /// ventana está abierta.
  pending,

  /// Un item recurrente que todavía no toca.
  waiting,

  /// Un item normal ya comprado.
  purchased;

  /// Si está en lo que hay que comprar ahora ([overdue] o [pending]).
  bool get isToBuy => this == ShoppingItemState.overdue || this == ShoppingItemState.pending;
}

class ShoppingItem extends Equatable {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.urgency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.quantity = '',
    this.categoryIds = const <String>[],
    this.recurrence,
    this.lastPurchasedAt,
  });

  final String id; // UUID v4, inmutable
  final String name;

  /// Texto libre; vacío si no hay.
  final String notes;

  /// Texto libre, p. ej. «2 docenas»; vacío si no hay.
  final String quantity;
  final Urgency urgency;
  final ShoppingItemStatus status;

  /// IDs de sus categorías, sin repetir. Cuál va primero lo decide el orden
  /// de las categorías, no esta lista.
  final List<String> categoryIds;

  /// `null` si no se repite.
  final Recurrence? recurrence;

  /// Última compra (UTC); `null` si nunca se compró.
  final DateTime? lastPurchasedAt;

  final DateTime createdAt; // UTC, inmutable
  final DateTime updatedAt; // UTC, se actualiza en cada escritura (LWW futuro)

  bool get isRecurring => recurrence != null;

  /// Estado que se muestra en [now].
  ShoppingItemState stateAt(DateTime now) {
    final Recurrence? recurrence = this.recurrence;
    if (status == ShoppingItemStatus.purchased) {
      return ShoppingItemState.purchased;
    }
    if (recurrence == null) {
      return ShoppingItemState.pending;
    }
    return switch (recurrence.statusAt(now, lastDone: lastPurchasedAt)) {
      RecurrenceStatus.waiting => ShoppingItemState.waiting,
      RecurrenceStatus.due => ShoppingItemState.pending,
      RecurrenceStatus.overdue => ShoppingItemState.overdue,
    };
  }

  ShoppingItem copyWith({
    String? name,
    String? notes,
    String? quantity,
    Urgency? urgency,
    ShoppingItemStatus? status,
    List<String>? categoryIds,
    Recurrence? Function()? recurrence,
    DateTime? Function()? lastPurchasedAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      quantity: quantity ?? this.quantity,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      categoryIds: categoryIds ?? this.categoryIds,
      recurrence: recurrence == null ? this.recurrence : recurrence(),
      lastPurchasedAt: lastPurchasedAt == null ? this.lastPurchasedAt : lastPurchasedAt(),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        notes,
        quantity,
        urgency,
        status,
        categoryIds,
        recurrence,
        lastPurchasedAt,
        createdAt,
        updatedAt,
      ];

  @override
  bool get stringify => true;
}
