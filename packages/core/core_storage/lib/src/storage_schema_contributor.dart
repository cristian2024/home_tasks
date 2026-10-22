import 'package:isar_community/isar.dart';

/// Lo implementa todo plugin que persiste colecciones propias en Isar.
///
/// Isar exige conocer todos los esquemas al abrir la base de datos, por lo que
/// la app reúne los esquemas de **todos** los plugins registrados (también los
/// desactivados, para que sus datos sigan intactos) antes de llamar a
/// [LocalDatabase.open].
abstract interface class StorageSchemaContributor {
  List<CollectionSchema<dynamic>> get storageSchemas;
}
