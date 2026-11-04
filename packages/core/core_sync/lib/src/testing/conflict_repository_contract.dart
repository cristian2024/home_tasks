import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import '../contracts/conflict_repository.dart';
import '../model/sync_conflict.dart';

/// Crea un repositorio vacío para un test.
typedef ConflictRepositoryFactory = FutureOr<ConflictRepository> Function();

/// Tests de contrato de [ConflictRepository]. Toda implementación debe
/// pasarlos.
void conflictRepositoryContract(String implementation, {required ConflictRepositoryFactory create}) {
  group('ConflictRepository ($implementation)', () {
    late ConflictRepository repository;

    SyncConflict conflict(String id, {int day = 1}) => SyncConflict(
          id: id,
          collection: 'item_tracker.identifiers',
          kind: 'identifierBoundTwice',
          entityIds: <String>['item-1', 'item-2'],
          options: <ConflictOption>[
            ConflictOption('keep-item-1', details: <String, String>{'name': 'Caja'}),
            ConflictOption('keep-item-2'),
          ],
          provisionalOptionId: 'keep-item-1',
          detectedAt: DateTime.utc(2026, 10, day, 18),
        );

    setUp(() async => repository = await create());

    test('empieza vacío', () async {
      expect(await repository.get('c-1'), isNull);
      expect(await repository.openConflicts(), isEmpty);
    });

    test('guarda un conflicto tal cual y lo reemplaza por id', () async {
      await repository.save(conflict('c-1'));
      expect(await repository.get('c-1'), conflict('c-1'));

      await repository.save(conflict('c-1').resolve('keep-item-2'));
      expect(await repository.get('c-1'), conflict('c-1').resolve('keep-item-2'));
    });

    test('openConflicts excluye los resueltos y ordena por fecha y id', () async {
      await repository.save(conflict('c-3', day: 2));
      await repository.save(conflict('c-2', day: 1));
      await repository.save(conflict('c-1', day: 2));
      await repository.save(conflict('c-4').resolve('keep-item-1'));

      expect(await repository.openConflicts(), <SyncConflict>[
        conflict('c-2', day: 1),
        conflict('c-1', day: 2),
        conflict('c-3', day: 2),
      ]);
    });

    test('watchOpenConflicts emite al escuchar y en cada cambio', () async {
      final StreamQueue<List<SyncConflict>> open = StreamQueue<List<SyncConflict>>(repository.watchOpenConflicts());

      expect(await open.next, isEmpty);
      await repository.save(conflict('c-1'));
      await expectLater(open, emitsThrough(<SyncConflict>[conflict('c-1')]));
      await repository.save(conflict('c-1').resolve('keep-item-1'));
      await expectLater(open, emitsThrough(isEmpty));
      await open.cancel();
    });
  });
}
