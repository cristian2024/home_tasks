/// Para los adaptadores Isar de las funcionalidades (p. ej.
/// `item_tracker_isar`): [IsarFeature] y la API de Isar, reexportada para que
/// todos usen la misma versión. Quien compone la app no lo importa.
library;

export 'package:isar_community/isar.dart';

export 'src/isar_feature.dart';
