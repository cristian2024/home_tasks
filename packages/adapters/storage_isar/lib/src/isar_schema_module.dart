import 'package:isar_community/isar.dart';

/// Colecciones Isar que aporta un adaptador (p. ej. el de un plugin).
///
/// Isar exige conocer todos los esquemas al abrir la base de datos, así que
/// quien compone la app pasa a [IsarDatabase.open] los módulos de **todos**
/// los plugins registrados, también los desactivados, para que sus datos
/// sigan intactos.
abstract interface class IsarSchemaModule {
  List<CollectionSchema<dynamic>> get schemas;
}
