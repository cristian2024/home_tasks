/// Adaptador Isar de la lista de compras. Quien compone la app solo elige
/// [ShoppingListIsar]; el plugin pide `ShoppingListRepository` al
/// `ServiceLocator` sin saber que detrás hay Isar.
library;

export 'src/shopping_list_isar.dart';
