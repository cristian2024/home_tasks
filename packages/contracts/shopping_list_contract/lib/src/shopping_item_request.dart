import 'package:equatable/equatable.dart';
import 'package:urgency/urgency.dart';

/// Lo que otro plugin pide añadir a la lista de compras.
class ShoppingItemRequest extends Equatable {
  /// Recorta [name] y lanza [ArgumentError] si queda vacío o supera
  /// [maxNameLength] caracteres.
  ShoppingItemRequest({required String name, this.quantity, this.notes, this.urgency = Urgency.normal})
      : name = name.trim() {
    if (this.name.isEmpty || this.name.length > maxNameLength) {
      throw ArgumentError.value(name, 'name', 'Debe tener entre 1 y $maxNameLength caracteres');
    }
  }

  static const int maxNameLength = 120;

  static final RegExp _spaces = RegExp(r'\s+');

  /// Forma de [name] con que se comparan los nombres: sin mayúsculas ni
  /// espacios de sobra.
  static String normalizeName(String name) => name.trim().replaceAll(_spaces, ' ').toLowerCase();

  final String name;
  final String? quantity;
  final String? notes;
  final Urgency urgency;

  @override
  List<Object?> get props => <Object?>[name, quantity, notes, urgency];
}
