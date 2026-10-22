import '../entities/household_item.dart';
import '../entities/physical_identifier.dart';
import '../item_validator.dart';
import '../repositories/household_item_repository.dart';

/// Busca el objeto ligado a un identificador escaneado o escrito a mano
/// (AC-03, AC-04, AC-05). Devuelve `null` si el identificador no existe.
class FindItemByIdentifier {
  const FindItemByIdentifier(this._repository);

  final HouseholdItemRepository _repository;

  Future<HouseholdItem?> call({required String rawValue, required IdentifierType type}) async {
    final identifier = await _repository.findIdentifier(ItemValidator.identifierValue(rawValue), type);
    if (identifier == null) {
      return null;
    }
    return _repository.getById(identifier.itemId);
  }
}
