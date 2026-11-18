# shopping_list_shared_preferences

Adaptador de `ShoppingListPreferences` (`shopping_list_domain`) con `shared_preferences`. Guarda en el dispositivo:

- la última categoría usada al crear un ítem desde la lista, que el campo de abajo propone la próxima vez;
- si ya se sugirió el gesto de deslizar para borrar, para no repetirlo.

Son del dispositivo: valen para todos los espacios de datos y no se sincronizan. Sin este adaptador, el plugin las guarda en memoria y se pierden al cerrar la app.

## Uso

Quien compone la app solo lo elige:

```dart
adapters: <DependencyModule>[SharedPreferencesShoppingList()]
```

Las claves van bajo `shopping_list.` (`SharedPreferencesShoppingListPreferences(keyPrefix: …)` para cambiarlo).

## Tests

`flutter test`: pasa los tests de contrato de `shoppingListPreferencesContract` (`package:shopping_list_domain/testing.dart`) con `SharedPreferences.setMockInitialValues`.
