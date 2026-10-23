import 'package:equatable/equatable.dart';

/// Origen de un [ItemEvent]. Los técnicos los genera el sistema; [note] lo
/// escribe el usuario.
enum ItemEventKind {
  /// Técnico. `title`: nombre del objeto al crearse. `description`: vacío.
  created,

  /// Técnico. `title`: vacío. `description`: campos cambiados separados por
  /// comas (`name`, `description`, `metadata`).
  updated,

  /// Técnico. `title`: `IdentifierType.name`. `description`: el `rawValue`.
  identifierBound,

  /// Técnico. `title`: `IdentifierType.name`. `description`: el `rawValue`.
  identifierUnbound,

  /// Técnico, en el objeto movido. `title`: nombre del contenedor nuevo.
  /// `description`: su ID. Ambos vacíos si ya no está en ningún contenedor.
  moved,

  /// Técnico, en el contenedor. `title`: nombre del objeto que entró.
  /// `description`: su ID.
  childAdded,

  /// Técnico, en el contenedor. `title`: nombre del objeto que salió.
  /// `description`: su ID.
  childRemoved,

  /// Funcional, escrito por el usuario. `title` y `description` son texto libre.
  note,
}

/// Entrada del historial de un objeto.
///
/// Los eventos técnicos guardan datos, no texto traducido: la presentación
/// compone el mensaje localizado a partir de [kind], [title] y [description].
class ItemEvent extends Equatable {
  final String id; // UUID v4
  final String itemId; // Foreign Key hacia HouseholdItem.id
  final ItemEventKind kind;
  final String title;
  final String description;
  final DateTime timestamp; // Siempre UTC

  const ItemEvent({
    required this.id,
    required this.itemId,
    required this.kind,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  bool get isTechnical => kind != ItemEventKind.note;

  @override
  List<Object?> get props => [id, itemId, kind, title, description, timestamp];

  @override
  bool get stringify => true;
}
