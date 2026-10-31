import 'dart:io';

import 'package:core_spaces/core_spaces.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

/// [DataSpaceStorage] sobre los archivos de Isar: cada espacio es una base
/// `<databaseName>.isar` en [directory], la misma carpeta que usa
/// `IsarStorage(name: space.databaseName)`.
class IsarSpaceStorage implements DataSpaceStorage {
  IsarSpaceStorage({required this.directory});

  /// En la carpeta de documentos de la app, la de `IsarStorage` por defecto.
  static Future<IsarSpaceStorage> documents() async =>
      IsarSpaceStorage(directory: (await getApplicationDocumentsDirectory()).path);

  static const String _extension = '.isar';

  /// Carpeta de las bases.
  final String directory;

  @override
  Future<Set<String>> databaseNames() async {
    final Directory folder = Directory(directory);
    if (!folder.existsSync()) {
      return <String>{};
    }
    return <String>{
      for (final FileSystemEntity entity in folder.listSync())
        if (entity is File && entity.path.endsWith(_extension))
          entity.uri.pathSegments.last.substring(0, entity.uri.pathSegments.last.length - _extension.length),
    };
  }

  @override
  Future<void> delete(String databaseName) async {
    if (Isar.getInstance(databaseName)?.isOpen ?? false) {
      throw DataSpaceInUseException(databaseName);
    }
    for (final String path in <String>[
      '$directory/$databaseName$_extension',
      '$directory/$databaseName$_extension.lock',
    ]) {
      final File file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }
}
