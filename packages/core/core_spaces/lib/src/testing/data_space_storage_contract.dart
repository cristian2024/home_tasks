import 'dart:async';

import 'package:test/test.dart';

import '../data_space_exception.dart';
import '../data_space_storage.dart';

/// Una implementación de [DataSpaceStorage] sobre una carpeta vacía, con lo
/// necesario para preparar sus bases.
class DataSpaceStorageHarness {
  DataSpaceStorageHarness({required this.storage, required this.create, required this.open, required this.close});

  final DataSpaceStorage storage;

  /// Crea la base [databaseName], con algún dato, y la deja cerrada.
  final Future<void> Function(String databaseName) create;

  /// Abre la base [databaseName], que ya existe.
  final Future<void> Function(String databaseName) open;

  /// Cierra la base [databaseName].
  final Future<void> Function(String databaseName) close;
}

typedef DataSpaceStorageFactory = FutureOr<DataSpaceStorageHarness> Function();

/// Tests de contrato de [DataSpaceStorage]. Toda implementación debe
/// pasarlos.
void dataSpaceStorageContract(String implementation, {required DataSpaceStorageFactory create}) {
  group('DataSpaceStorage ($implementation)', () {
    test('databaseNames devuelve las bases que existen', () async {
      final DataSpaceStorageHarness harness = await create();
      expect(await harness.storage.databaseNames(), isEmpty);

      await harness.create('space_a');
      await harness.create('space_b');

      expect(await harness.storage.databaseNames(), <String>{'space_a', 'space_b'});
    });

    test('delete borra una base sin tocar las demás', () async {
      final DataSpaceStorageHarness harness = await create();
      await harness.create('space_a');
      await harness.create('space_b');

      await harness.storage.delete('space_a');

      expect(await harness.storage.databaseNames(), <String>{'space_b'});
    });

    test('delete de una base que no existe no falla', () async {
      final DataSpaceStorageHarness harness = await create();

      await expectLater(harness.storage.delete('space_nadie'), completes);
    });

    test('delete de una base abierta lanza sin borrarla, y cerrada la borra', () async {
      final DataSpaceStorageHarness harness = await create();
      await harness.create('space_a');
      await harness.open('space_a');

      await expectLater(harness.storage.delete('space_a'), throwsA(isA<DataSpaceInUseException>()));
      expect(await harness.storage.databaseNames(), <String>{'space_a'});

      await harness.close('space_a');
      await harness.storage.delete('space_a');
      expect(await harness.storage.databaseNames(), isEmpty);
    });
  });
}
