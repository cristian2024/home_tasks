/// Niveles de urgencia comunes para lo pendiente de la casa (compras,
/// tareas). Cada funcionalidad guarda el valor y compone sus textos.
library;

/// Urgencia de algo pendiente, de mayor a menor. El orden natural
/// ([compareTo]) pone primero lo más urgente.
enum Urgency implements Comparable<Urgency> {
  /// Hoy, o ya.
  immediate,

  /// En la próxima ocasión (la próxima compra, esta semana).
  high,

  /// Sin prisa especial. Es el valor por defecto.
  normal,

  /// Cuando se pueda.
  low;

  static const Urgency defaultValue = Urgency.normal;

  /// Lo que debe verse de un vistazo: [immediate] o [high].
  bool get isUrgent => this == Urgency.immediate || this == Urgency.high;

  bool isMoreUrgentThan(Urgency other) => compareTo(other) < 0;

  /// Negativo si este nivel es más urgente que [other].
  @override
  int compareTo(Urgency other) => index.compareTo(other.index);
}
