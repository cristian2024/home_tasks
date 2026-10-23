import 'package:equatable/equatable.dart';

import 'item_tree.dart';

/// Reglas de anidamiento de objetos. Los niveles se cuentan desde 1: un objeto
/// sin contenedor está en el nivel 1.
class ContainmentPolicy extends Equatable {
  const ContainmentPolicy({this.maxDepth = defaultMaxDepth}) : assert(maxDepth >= 1);

  /// Valor configurado, p. ej. con `--dart-define`. Uno menor que 1 se
  /// sustituye por [defaultMaxDepth].
  factory ContainmentPolicy.fromConfiguredDepth(int maxDepth) =>
      ContainmentPolicy(maxDepth: maxDepth < 1 ? defaultMaxDepth : maxDepth);

  static const int defaultMaxDepth = 5;

  final int maxDepth;

  /// Si un objeto cuyo subárbol mide [subtreeHeight] niveles cabe dentro de un
  /// contenedor que está en el nivel [parentDepth].
  bool allows({required int parentDepth, required int subtreeHeight}) => parentDepth + subtreeHeight <= maxDepth;

  /// El contenedor [itemId] contiene objetos por debajo del nivel máximo. Pasa
  /// si se baja [maxDepth] cuando ya había objetos más anidados: no se mueve
  /// nada, solo se señala el contenedor.
  bool isOverflowing(ItemTree tree, String itemId) =>
      tree.depthOf(itemId) >= maxDepth && tree.childrenOf(itemId).isNotEmpty;

  @override
  List<Object?> get props => [maxDepth];
}
