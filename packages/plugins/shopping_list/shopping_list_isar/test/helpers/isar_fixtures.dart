import 'dart:io';

import 'package:core_di/core_di.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:shopping_list_isar/shopping_list_isar.dart';
import 'package:storage_isar/storage_isar.dart';

/// La lista de compras sobre Isar tal como la compone una app: [IsarStorage]
/// con [ShoppingListIsar], en un locator propio y un directorio temporal.
/// [close] cierra la base y borra el directorio.
class TestStorage {
  TestStorage._(this.services, this._directory);

  final ServiceLocator services;
  final Directory _directory;

  ShoppingListRepository get repository => services.get<ShoppingListRepository>();

  static Future<TestStorage> open() async {
    final Directory directory = Directory.systemTemp.createTempSync('shopping_list_isar_test');
    final ServiceLocator services = ServiceLocator();
    await IsarStorage(directory: directory.path, features: const <IsarFeature>[ShoppingListIsar()]).register(services);
    return TestStorage._(services, directory);
  }

  Future<void> close() async {
    await services.reset();
    _directory.deleteSync(recursive: true);
  }
}
