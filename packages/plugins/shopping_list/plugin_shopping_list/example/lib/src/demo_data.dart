import 'package:plugin_shopping_list/plugin_shopping_list.dart';

/// Items de ejemplo para recorrer la lista a mano: urgencias, varias
/// categorías y compras que se repiten.
class DemoData {
  const DemoData(this._dependencies, this._repository);

  final ShoppingListDependencies _dependencies;

  /// Para leer lo que ya hay: items y categorías (las por defecto se eligen
  /// por su clave).
  final ShoppingListRepository _repository;

  /// Crea los items que falten (por nombre). Devuelve cuántos creó.
  Future<int> load() async {
    final List<ShoppingCategory> categories = await _repository.getCategories();
    final Set<String> existing = <String>{
      for (final ShoppingItem item in await _repository.getItems()) ShoppingValidator.normalize(item.name),
    };
    List<String> ids(List<String> keys) => <String>[
          for (final ShoppingCategory category in categories)
            if (keys.contains(category.defaultKey)) category.id,
        ];
    int created = 0;
    Future<void> create(
      String name, {
      String quantity = '',
      Urgency urgency = Urgency.normal,
      List<String> categoryKeys = const <String>[],
      Recurrence? recurrence,
    }) async {
      if (existing.contains(ShoppingValidator.normalize(name))) {
        return;
      }
      await _dependencies.createItem(
        name: name,
        quantity: quantity,
        urgency: urgency,
        categoryIds: ids(categoryKeys),
        recurrence: recurrence,
      );
      created++;
    }

    await create(
      'Huevos',
      quantity: '2 docenas',
      categoryKeys: <String>['food'],
      recurrence: Recurrence.between(8, 15),
    );
    await create('Papel higiénico', urgency: Urgency.immediate, categoryKeys: <String>['hygiene', 'home']);
    await create('Leche', quantity: '6 l', urgency: Urgency.high, categoryKeys: <String>['food']);
    await create('Lejía', categoryKeys: <String>['cleaning']);
    await create('Ibuprofeno', urgency: Urgency.low, categoryKeys: <String>['pharmacy']);
    await create('Pilas AA');
    return created;
  }
}
