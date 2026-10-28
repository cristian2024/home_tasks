/// Adaptador de almacenamiento sobre Isar (`isar_community`).
///
/// Quien compone la app solo elige [IsarStorage] y los adaptadores Isar de
/// sus funcionalidades ([IsarFeature]). [IsarStorage] abre la base y registra
/// los contratos en el `ServiceLocator`; la app no ve nada de Isar.
///
/// Los adaptadores Isar de las funcionalidades importan además
/// `package:storage_isar/adapter.dart`.
library;

export 'src/isar_feature.dart' show IsarFeature;
export 'src/isar_storage.dart';
