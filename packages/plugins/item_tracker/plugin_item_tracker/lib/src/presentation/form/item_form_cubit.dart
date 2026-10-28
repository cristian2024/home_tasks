import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../domain/use_cases/create_item.dart';
import '../../domain/use_cases/item_queries.dart';
import '../../domain/use_cases/update_item.dart';

enum MetadataValueType { text, number, boolean }

/// Fila del editor de metadatos. [id] es local y estable para la UI.
class MetadataEntry extends Equatable {
  const MetadataEntry({
    required this.id,
    this.key = '',
    this.type = MetadataValueType.text,
    this.text = '',
    this.flag = false,
  });

  final int id;
  final String key;
  final MetadataValueType type;
  final String text;
  final bool flag;

  MetadataEntry copyWith({String? key, MetadataValueType? type, String? text, bool? flag}) => MetadataEntry(
        id: id,
        key: key ?? this.key,
        type: type ?? this.type,
        text: text ?? this.text,
        flag: flag ?? this.flag,
      );

  @override
  List<Object?> get props => <Object?>[id, key, type, text, flag];
}

enum ItemFormStatus { loading, editing, submitting, saved }

/// Error asociado a un campo o a una fila de metadatos.
sealed class ItemFormError extends Equatable {
  const ItemFormError();
}

final class ItemFormValidationError extends ItemFormError {
  const ItemFormValidationError(this.error, {this.entryId});

  final ItemValidationException error;

  /// Fila de metadatos afectada, si se pudo identificar.
  final int? entryId;

  @override
  List<Object?> get props => <Object?>[error.field, error.reason, error.detail, entryId];
}

/// Clave repetida en dos filas.
final class ItemFormDuplicatedKey extends ItemFormError {
  const ItemFormDuplicatedKey(this.key, this.entryId);

  final String key;
  final int entryId;

  @override
  List<Object?> get props => <Object?>[key, entryId];
}

/// Número que no se puede interpretar.
final class ItemFormInvalidNumber extends ItemFormError {
  const ItemFormInvalidNumber(this.entryId);

  final int entryId;

  @override
  List<Object?> get props => <Object?>[entryId];
}

/// Error no ligado a un campo (identificador ya asociado, objeto borrado…).
final class ItemFormGeneralError extends ItemFormError {
  const ItemFormGeneralError(this.error);

  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}

class ItemFormState extends Equatable {
  const ItemFormState({
    required this.status,
    this.name = '',
    this.description = '',
    this.entries = const <MetadataEntry>[],
    this.initialIdentifier,
    this.parentId,
    this.parentPath = const <HouseholdItem>[],
    this.error,
    this.savedItemId,
  });

  final ItemFormStatus status;

  /// Valores iniciales (al editar, los del objeto cargado).
  final String name;
  final String description;
  final List<MetadataEntry> entries;

  /// Identificador que se asociará al crear (desde "Crear nuevo objeto").
  final ({String rawValue, IdentifierType type})? initialIdentifier;

  /// Contenedor en el que se creará el objeto ("Añadir objeto aquí") y su
  /// ruta completa, incluido él mismo, cuando ya se ha cargado.
  final String? parentId;
  final List<HouseholdItem> parentPath;
  final ItemFormError? error;
  final String? savedItemId;

  ItemFormState copyWith({
    ItemFormStatus? status,
    String? name,
    String? description,
    List<MetadataEntry>? entries,
    List<HouseholdItem>? parentPath,
    ItemFormError? Function()? error,
    String? savedItemId,
  }) {
    return ItemFormState(
      status: status ?? this.status,
      name: name ?? this.name,
      description: description ?? this.description,
      entries: entries ?? this.entries,
      initialIdentifier: initialIdentifier,
      parentId: parentId,
      parentPath: parentPath ?? this.parentPath,
      error: error == null ? this.error : error(),
      savedItemId: savedItemId ?? this.savedItemId,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[status, name, description, entries, initialIdentifier, parentId, parentPath, error, savedItemId];
}

/// Formulario de creación y edición de objetos (Cubit, §11.1).
class ItemFormCubit extends Cubit<ItemFormState> {
  /// Formulario de creación, opcionalmente con el identificador escaneado o
  /// dentro de un contenedor ([parentId], cuya ruta se lee de [watchItemTree]).
  ItemFormCubit.create({
    required CreateItem createItem,
    ({String rawValue, IdentifierType type})? identifier,
    String? parentId,
    WatchItemTree? watchItemTree,
  })  : _createItem = createItem,
        _updateItem = null,
        _itemId = null,
        super(ItemFormState(status: ItemFormStatus.editing, initialIdentifier: identifier, parentId: parentId)) {
    if (parentId != null && watchItemTree != null) {
      _loadParentPath(parentId, watchItemTree);
    }
  }

  /// Formulario de edición: carga el objeto con [getItem].
  ItemFormCubit.edit(
    String itemId, {
    required GetItem getItem,
    required UpdateItem updateItem,
  })  : _createItem = null,
        _updateItem = updateItem,
        _itemId = itemId,
        super(const ItemFormState(status: ItemFormStatus.loading)) {
    _load(getItem);
  }

  final CreateItem? _createItem;
  final UpdateItem? _updateItem;
  final String? _itemId;
  int _nextEntryId = 0;

  bool get isEditing => _itemId != null;

  /// Objeto que se edita; `null` al crear.
  String? get itemId => _itemId;

  /// Si el contenedor ya no existe, la ruta queda vacía y el error llega al
  /// guardar.
  Future<void> _loadParentPath(String parentId, WatchItemTree watchItemTree) async {
    final ItemTree tree = await watchItemTree().first;
    final HouseholdItem? parent = tree[parentId];
    if (parent != null && !isClosed) {
      emit(state.copyWith(parentPath: <HouseholdItem>[...tree.pathOf(parentId), parent]));
    }
  }

  Future<void> _load(GetItem getItem) async {
    try {
      final HouseholdItem item = await getItem(_itemId!);
      emit(
        state.copyWith(
          status: ItemFormStatus.editing,
          name: item.name,
          description: item.description,
          entries: <MetadataEntry>[
            for (final MapEntry<String, Object>(:String key, :Object value) in item.metadata.values.entries)
              MetadataEntry(
                id: _nextEntryId++,
                key: key,
                type: switch (value) {
                  bool() => MetadataValueType.boolean,
                  num() => MetadataValueType.number,
                  _ => MetadataValueType.text,
                },
                text: value is bool ? '' : '$value',
                flag: value is bool && value,
              ),
          ],
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: ItemFormStatus.editing, error: () => ItemFormGeneralError(error)));
    }
  }

  void addEntry() =>
      emit(state.copyWith(entries: <MetadataEntry>[...state.entries, MetadataEntry(id: _nextEntryId++)]));

  void removeEntry(int entryId) =>
      emit(state.copyWith(entries: state.entries.where((MetadataEntry entry) => entry.id != entryId).toList()));

  void updateEntry(MetadataEntry entry) => emit(
        state.copyWith(
          entries: <MetadataEntry>[for (final MetadataEntry e in state.entries) e.id == entry.id ? entry : e],
        ),
      );

  Future<void> submit({required String name, required String description}) async {
    if (state.status != ItemFormStatus.editing) {
      return;
    }
    final Map<String, Object?> metadata;
    try {
      metadata = _buildMetadata();
    } on ItemFormError catch (error) {
      emit(state.copyWith(error: () => error));
      return;
    }

    emit(state.copyWith(status: ItemFormStatus.submitting, error: () => null));
    try {
      final String itemId = isEditing
          ? (await _updateItem!(_itemId!, name: name, description: description, metadata: metadata)).id
          : (await _createItem!(
              name: name,
              description: description,
              metadata: metadata,
              identifier: state.initialIdentifier,
              parentId: state.parentId,
            ))
              .id;
      emit(state.copyWith(status: ItemFormStatus.saved, savedItemId: itemId));
    } on ItemValidationException catch (error) {
      final int? entryId = error.field == ValidationField.metadata
          ? state.entries.where((MetadataEntry entry) => entry.key.trim() == error.detail).firstOrNull?.id
          : null;
      emit(state.copyWith(status: ItemFormStatus.editing, error: () => ItemFormValidationError(error, entryId: entryId)));
    } catch (error) {
      emit(state.copyWith(status: ItemFormStatus.editing, error: () => ItemFormGeneralError(error)));
    }
  }

  Map<String, Object?> _buildMetadata() {
    final Map<String, Object?> metadata = <String, Object?>{};
    for (final MetadataEntry entry in state.entries) {
      final String key = entry.key.trim();
      if (key.isEmpty && entry.text.trim().isEmpty && entry.type != MetadataValueType.boolean) {
        continue; // Fila vacía: se ignora.
      }
      if (metadata.containsKey(key)) {
        throw ItemFormDuplicatedKey(key, entry.id);
      }
      metadata[key] = switch (entry.type) {
        MetadataValueType.text => entry.text,
        MetadataValueType.boolean => entry.flag,
        MetadataValueType.number => _parseNumber(entry.text) ?? (throw ItemFormInvalidNumber(entry.id)),
      };
    }
    return metadata;
  }

  /// Acepta coma o punto decimal. Sin decimales devuelve un `int`.
  static num? _parseNumber(String text) {
    final String normalized = text.trim().replaceAll(',', '.');
    return int.tryParse(normalized) ?? double.tryParse(normalized);
  }
}
