import 'package:equatable/equatable.dart';

import '../value_objects/item_metadata.dart';

class HouseholdItem extends Equatable {
  final String id; // UUID v4, inmutable
  final String name;
  final String description;
  final ItemMetadata metadata;
  final DateTime createdAt; // UTC, inmutable
  final DateTime updatedAt; // UTC, se actualiza en cada escritura (LWW futuro)

  const HouseholdItem({
    required this.id,
    required this.name,
    required this.description,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  HouseholdItem copyWith({
    String? name,
    String? description,
    ItemMetadata? metadata,
    DateTime? updatedAt,
  }) {
    return HouseholdItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, description, metadata, createdAt, updatedAt];

  @override
  bool get stringify => true;
}
