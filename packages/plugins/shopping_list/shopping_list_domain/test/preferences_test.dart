import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:shopping_list_domain/testing.dart';

void main() {
  shoppingListPreferencesContract(() async => InMemoryShoppingListPreferences());
}
