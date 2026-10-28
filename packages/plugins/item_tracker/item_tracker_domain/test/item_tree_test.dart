import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:test/test.dart';

import 'helpers/domain_fixtures.dart';

void main() {
  // Mueble › Organizador › (Cajón 2, cajón 1) y Tijeras suelta.
  final ItemTree tree = ItemTree(<HouseholdItem>[
    item(id: 'furniture', name: 'Mueble'),
    item(id: 'organizer', name: 'Organizador', parentId: 'furniture'),
    item(id: 'drawer2', name: 'Cajón 2', parentId: 'organizer'),
    item(id: 'drawer1', name: 'cajón 1', parentId: 'organizer'),
    item(id: 'scissors', name: 'Tijeras'),
  ]);

  group('ItemTree', () {
    test('ruta, nivel y contenido ordenado por nombre', () {
      expect(tree.pathOf('drawer1').map((HouseholdItem i) => i.id), <String>['furniture', 'organizer']);
      expect(tree.pathOf('furniture'), isEmpty);
      expect(tree.depthOf('drawer1'), 3);
      expect(tree.depthOf('scissors'), 1);
      expect(tree.childrenOf('organizer').map((HouseholdItem i) => i.id), <String>['drawer1', 'drawer2']);
      expect(tree.childrenOf('scissors'), isEmpty);
      expect(tree['organizer']?.name, 'Organizador');
      expect(tree['missing'], isNull);
      expect(
        tree.items.map((HouseholdItem i) => i.id),
        <String>['furniture', 'organizer', 'drawer2', 'drawer1', 'scissors'],
      );
    });

    test('altura del subárbol y pertenencia', () {
      expect(tree.heightOf('furniture'), 3);
      expect(tree.heightOf('drawer1'), 1);
      expect(tree.isInside('drawer2', ancestorId: 'furniture'), isTrue);
      expect(tree.isInside('furniture', ancestorId: 'drawer2'), isFalse);
      expect(tree.isInside('scissors', ancestorId: 'furniture'), isFalse);
    });

    test('tolera contenedores inexistentes y ciclos sin colgarse', () {
      final ItemTree broken = ItemTree(<HouseholdItem>[
        item(id: 'orphan', parentId: 'deleted'),
        item(id: 'a', parentId: 'b'),
        item(id: 'b', parentId: 'a'),
      ]);

      expect(broken.depthOf('orphan'), 1);
      expect(broken.pathOf('a').map((HouseholdItem i) => i.id), <String>['b']);
      expect(broken.heightOf('a'), 2);
    });
  });

  group('ContainmentPolicy', () {
    test('admite un subárbol solo si cabe completo', () {
      const ContainmentPolicy policy = ContainmentPolicy(maxDepth: 5);

      expect(policy.allows(parentDepth: 1, subtreeHeight: 4), isTrue);
      expect(policy.allows(parentDepth: 2, subtreeHeight: 4), isFalse);
      expect(const ContainmentPolicy().maxDepth, ContainmentPolicy.defaultMaxDepth);
    });

    test('un valor configurado menor que 1 usa el valor por defecto', () {
      expect(ContainmentPolicy.fromConfiguredDepth(3), const ContainmentPolicy(maxDepth: 3));
      expect(ContainmentPolicy.fromConfiguredDepth(0).maxDepth, ContainmentPolicy.defaultMaxDepth);
    });

    test('si se baja el máximo señala los contenedores que contienen de más', () {
      const ContainmentPolicy policy = ContainmentPolicy(maxDepth: 2);

      expect(policy.isOverflowing(tree, 'organizer'), isTrue); // Nivel 2 con cajones dentro.
      expect(policy.isOverflowing(tree, 'furniture'), isFalse);
      expect(policy.isOverflowing(tree, 'drawer1'), isFalse); // Nivel 3, pero vacío.
      expect(const ContainmentPolicy().isOverflowing(tree, 'organizer'), isFalse);
    });
  });
}
