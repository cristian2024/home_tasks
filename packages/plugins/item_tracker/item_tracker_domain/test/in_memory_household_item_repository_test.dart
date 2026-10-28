import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:item_tracker_domain/testing.dart';
import 'package:test/test.dart';

void main() {
  householdItemRepositoryContract(
    'en memoria',
    create: InMemoryHouseholdItemRepository.new,
    dispose: (HouseholdItemRepository repository) => (repository as InMemoryHouseholdItemRepository).close(),
  );

  test('guarda los identificadores quitados con el momento en que se quitaron', () async {
    final InMemoryHouseholdItemRepository repository = InMemoryHouseholdItemRepository();
    addTearDown(repository.close);
    final DateTime t0 = DateTime.utc(2026, 10, 21);
    final PhysicalIdentifier identifier =
        PhysicalIdentifier(id: 'i1', rawValue: 'QR-1', type: IdentifierType.qr, itemId: 'item-1', boundAt: t0);
    await repository.bindIdentifier(
      identifier,
      ItemEvent(id: 'e1', itemId: 'item-1', kind: ItemEventKind.identifierBound, title: '', description: '', timestamp: t0),
    );

    final DateTime deletedAt = t0.add(const Duration(hours: 1));
    await repository.unbindIdentifier(
      'i1',
      deletedAt: deletedAt,
      event: ItemEvent(
        id: 'e2',
        itemId: 'item-1',
        kind: ItemEventKind.identifierUnbound,
        title: '',
        description: '',
        timestamp: deletedAt,
      ),
    );

    expect(repository.deletedIdentifiers.single, (identifier: identifier, deletedAt: deletedAt));
  });
}
