import 'package:core_storage/core_storage.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

part 'isar_item_event.g.dart';

@collection
class IsarItemEvent {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index(composite: <CompositeIndex>[CompositeIndex('timestamp')])
  late String itemId;

  @Enumerated(EnumType.name)
  late ItemEventKind kind;

  late String title;
  late String description;

  late DateTime timestamp;
}
