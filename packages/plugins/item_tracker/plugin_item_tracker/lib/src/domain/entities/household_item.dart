import 'package:equatable/equatable.dart';

import '../value_objects/item_metadata.dart';

class HouseholdItem extends Equatable {
  final String id; // UUID v4, inmutable
  final String name;
  final String description;
  final ItemMetadata metadata;
  final DateTime createdAt; // UTC, inmutable
  final DateTime updatedAt; // UTC, se actualiza en cada escritura (LWW futuro)

  /// Objeto que lo contiene (p. ej. el organizador de un cajón); `null` si no
  /// está dentro de ningún otro.
  final String? parentId;

  const HouseholdItem({
    required this.id,
    required this.name,
    required this.description,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
  });

  HouseholdItem copyWith({
    String? name,
    String? description,
    ItemMetadata? metadata,
    DateTime? updatedAt,
    String? Function()? parentId,
  }) {
    return HouseholdItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId == null ? this.parentId : parentId(),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name, description, metadata, createdAt, updatedAt, parentId];

  @override
  bool get stringify => true;
}
