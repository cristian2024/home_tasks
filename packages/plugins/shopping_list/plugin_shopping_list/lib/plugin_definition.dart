import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_share/core_share.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shopping_list_contract/shopping_list_contract.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import 'src/domain/use_cases/build_shopping_export.dart';
import 'src/domain/use_cases/category_use_cases.dart';
import 'src/domain/use_cases/item_use_cases.dart';
import 'src/domain/use_cases/list_queries.dart';
import 'src/domain/use_cases/purchase_use_cases.dart';
import 'src/domain/use_cases/shopping_list_api.dart';
import 'src/i18n/strings.g.dart' as i18n;
import 'src/presentation/categories/shopping_categories_cubit.dart';
import 'src/presentation/categories/shopping_categories_screen.dart';
import 'src/presentation/common/shopping_list_l10n.dart';
import 'src/presentation/dashboard/shopping_list_dashboard_tile.dart';
import 'src/presentation/export/shopping_export_sheet.dart';
import 'src/presentation/form/shopping_item_form_cubit.dart';
import 'src/presentation/form/shopping_item_form_screen.dart';
import 'src/presentation/list/shopping_list_cubit.dart';
import 'src/presentation/list/shopping_list_screen.dart';
import 'src/presentation/shopping_list_routes.dart';
import 'src/shopping_list_dependencies.dart';

/// Plugin de lista de compras (spec, reglas de la lista de compras).
///
/// Dependencias que toma del `ServiceLocator` de la app (scope base):
/// - `ShoppingListRepository` (obligatorio), que registra el adaptador de
///   almacenamiento que elige la app (p. ej. `ShoppingListIsar`). En tests,
///   `InMemoryShoppingListRepository` de `package:plugin_shopping_list/testing.dart`.
/// - `EventBus`, `IdGenerator` y `Clock` (opcionales: si faltan usa los
///   suyos).
/// - `ShareService` (opcional, buscado al exportar): sin él no se ofrece
///   exportar.
///
/// Su pantalla principal es la lista ([entryRoute]).
///
/// Mientras está activo registra en su scope las capacidades públicas
/// `ShoppingListQuery` y `ShoppingListWriter` (`shopping_list_contract`) y
/// publica `ShoppingItemPurchased` en el `EventBus`.
class ShoppingListPlugin implements HomePlugin, HomePluginEntryRoute {
  ShoppingListPlugin({required ServiceLocator locator, LocalizationCoordinator? localization})
      : _locator = locator,
        _localization = localization ?? LocalizationCoordinator.instance;

  static const String pluginId = 'shopping_list';

  final ServiceLocator _locator;
  final LocalizationCoordinator _localization;

  ShoppingListDependencies get _dependencies => _locator.get<ShoppingListDependencies>();

  @override
  String get id => pluginId;

  @override
  String get nameKey => 'shoppingList.title';

  @override
  String get descriptionKey => 'shoppingList.description';

  @override
  IconData get icon => Icons.shopping_cart_outlined;

  @override
  String get version => '0.2.0';

  /// La lista: desde la grilla del inicio se abre directamente.
  @override
  String get entryRoute => ShoppingListRoutes.base;

  @override
  Future<bool> isAvailable() async => true;

  /// Registra el idioma y las traducciones del plugin. La app lo llama al
  /// registrar el plugin, aunque esté desactivado, para que el catálogo pueda
  /// mostrar su nombre ([nameKey]). Es idempotente.
  void registerLocalization() {
    _localization.register(
      pluginId,
      (String code) => i18n.LocaleSettings.setLocaleRawSync(code),
      translate: (String key) {
        final Object? value = i18n.shoppingListStrings[key];
        return value is String ? value : null;
      },
      override: (String code, Map<String, Object?> overrides) =>
          i18n.LocaleSettings.instance.overrideTranslationsFromMapSync(
            locale: i18n.AppLocaleUtils.parse(code),
            isFlatMap: false,
            map: overrides,
          ),
    );
  }

  @override
  Future<void> initialize() async {
    registerLocalization();
    await _locator.pushScope(
      pluginId,
      init: (ServiceLocator locator) async {
        final ShoppingListRepository repository = locator.get<ShoppingListRepository>();
        final IdGenerator ids =
            locator.isRegistered<IdGenerator>() ? locator.get<IdGenerator>() : const UuidV4Generator();
        final Clock clock = locator.isRegistered<Clock>() ? locator.get<Clock>() : const SystemClock();
        final EventBus eventBus;
        if (locator.isRegistered<EventBus>()) {
          eventBus = locator.get<EventBus>();
        } else {
          eventBus = EventBus();
          locator.registerSingleton(eventBus, dispose: (EventBus bus) => bus.dispose());
        }
        await EnsureDefaultShoppingCategories(repository, ids)();

        final CreateShoppingItem createItem = CreateShoppingItem(repository, ids, clock);
        final MarkShoppingItemPending markPending = MarkShoppingItemPending(repository, clock);
        locator.registerSingleton(
          ShoppingListDependencies(
            createItem: createItem,
            updateItem: UpdateShoppingItem(repository, clock),
            getItem: GetShoppingItem(repository),
            deleteItems: DeleteShoppingItems(repository, clock),
            markPurchased: MarkShoppingItemPurchased(repository, ids, clock, eventBus),
            undoPurchase: UndoShoppingPurchase(repository, clock),
            markPending: markPending,
            clearPurchased: ClearPurchasedShoppingItems(repository, clock),
            createCategory: CreateShoppingCategory(repository, ids, categoryName),
            renameCategory: RenameShoppingCategory(repository, categoryName),
            countCategoryUsage: CountShoppingCategoryUsage(repository),
            deleteCategory: DeleteShoppingCategory(repository, clock),
            reorderCategories: ReorderShoppingCategories(repository),
            watchList: WatchShoppingList(repository, clock),
            watchCategories: WatchShoppingCategories(repository),
            buildExport: const BuildShoppingExport(),
            // Se busca al usarlo: la app puede no registrar ninguno.
            shareService: () => _locator.isRegistered<ShareService>() ? _locator.get<ShareService>() : null,
            now: clock.nowUtc,
          ),
        );

        // Capacidades públicas: desaparecen con el scope en dispose().
        final ShoppingListApi api = ShoppingListApi(
          repository: repository,
          clock: clock,
          createItem: createItem,
          markPending: markPending,
          categoryName: categoryName,
        );
        locator
          ..registerSingleton<ShoppingListQuery>(api)
          ..registerSingleton<ShoppingListWriter>(api);
      },
    );
  }

  @override
  Future<void> dispose() => _locator.dropScope(pluginId);

  @override
  Widget buildDashboardTile(BuildContext context) => ShoppingListDashboardTile(watchList: _dependencies.watchList);

  @override
  List<RouteBase> get routes => <RouteBase>[
        GoRoute(
          path: ShoppingListRoutes.base,
          builder: (BuildContext context, GoRouterState state) {
            final ShoppingListDependencies deps = _dependencies;
            final ShareService? share = deps.shareService();
            return BlocProvider<ShoppingListCubit>(
              create: (_) => ShoppingListCubit(
                watchList: deps.watchList,
                markPurchased: deps.markPurchased,
                undoPurchase: deps.undoPurchase,
                markPending: deps.markPending,
                clearPurchased: deps.clearPurchased,
              ),
              child: ShoppingListScreen(
                exportSheet: share == null
                    ? null
                    : (ShoppingListState list) => ShoppingExportSheet(
                          allEntries: list.snapshot.entries,
                          filteredEntries: list.filtered,
                          isFiltered: !list.filter.isEmpty,
                          initialGrouping: list.grouping,
                          buildExport: deps.buildExport,
                          shareService: share,
                          now: deps.now(),
                        ),
              ),
            );
          },
        ),
        GoRoute(
          path: ShoppingListRoutes.create,
          builder: (BuildContext context, GoRouterState state) => _itemForm(null),
        ),
        GoRoute(
          path: ShoppingListRoutes.editPattern,
          builder: (BuildContext context, GoRouterState state) => _itemForm(state.pathParameters['id']),
        ),
        GoRoute(
          path: ShoppingListRoutes.categories,
          builder: (BuildContext context, GoRouterState state) {
            final ShoppingListDependencies deps = _dependencies;
            return BlocProvider<ShoppingCategoriesCubit>(
              create: (_) => ShoppingCategoriesCubit(
                watchCategories: deps.watchCategories,
                createCategory: deps.createCategory,
                renameCategory: deps.renameCategory,
                countUsage: deps.countCategoryUsage,
                deleteCategory: deps.deleteCategory,
                reorderCategories: deps.reorderCategories,
              ),
              child: const ShoppingCategoriesScreen(),
            );
          },
        ),
      ];

  Widget _itemForm(String? itemId) {
    final ShoppingListDependencies deps = _dependencies;
    return BlocProvider<ShoppingItemFormCubit>(
      create: (_) => ShoppingItemFormCubit(
        itemId: itemId,
        getItem: deps.getItem,
        watchCategories: deps.watchCategories,
        createItem: deps.createItem,
        updateItem: deps.updateItem,
        deleteItems: deps.deleteItems,
      ),
      child: const ShoppingItemFormScreen(),
    );
  }
}
