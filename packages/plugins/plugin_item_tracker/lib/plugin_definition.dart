import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:core_storage/core_storage.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'src/data/item_tracker_storage.dart';
import 'src/data/repositories/isar_household_item_repository.dart';
import 'src/domain/repositories/household_item_repository.dart';
import 'src/domain/use_cases/add_item_event.dart';
import 'src/domain/use_cases/bind_identifier.dart';
import 'src/domain/use_cases/create_item.dart';
import 'src/domain/use_cases/find_item_by_identifier.dart';
import 'src/domain/use_cases/item_queries.dart';
import 'src/domain/use_cases/unbind_identifier.dart';
import 'src/domain/use_cases/update_item.dart';
import 'src/i18n/strings.g.dart' as i18n;
import 'src/item_tracker_dependencies.dart';
import 'src/presentation/add_event/add_event_cubit.dart';
import 'src/presentation/add_event/add_event_screen.dart';
import 'src/presentation/associate/associate_cubit.dart';
import 'src/presentation/associate/associate_screen.dart';
import 'src/presentation/dashboard/item_tracker_dashboard_tile.dart';
import 'src/presentation/detail/item_detail_cubit.dart';
import 'src/presentation/detail/item_detail_screen.dart';
import 'src/presentation/form/item_form_cubit.dart';
import 'src/presentation/form/item_form_screen.dart';
import 'src/presentation/item_tracker_routes.dart';
import 'src/presentation/list/item_list_cubit.dart';
import 'src/presentation/list/item_list_screen.dart';
import 'src/presentation/not_found/not_found_screen.dart';
import 'src/presentation/scan/scan_bloc.dart';
import 'src/presentation/scan/scan_screen.dart';

/// Plugin de identificación y seguimiento de objetos (§8).
///
/// Dependencias que toma del `ServiceLocator` de la app (scope base):
/// - `Isar` (obligatoria salvo que se pase [repositoryFactory]).
/// - `EventBus`, `IdGenerator` y `Clock` (opcionales: si faltan usa los
///   suyos).
///
/// Los escáneres y los permisos se inyectan por constructor para poder usar
/// los fakes de `package:core_hardware/testing.dart`.
class ItemTrackerPlugin implements HomePlugin, StorageSchemaContributor {
  ItemTrackerPlugin({
    required ServiceLocator locator,
    CameraScannerFactory? cameraScannerFactory,
    NfcScannerFactory? nfcScannerFactory,
    HardwarePermissions? permissions,
    HouseholdItemRepository Function(ServiceLocator locator)? repositoryFactory,
    LocalizationCoordinator? localization,
  })  : _locator = locator,
        _cameraScannerFactory = cameraScannerFactory ?? MobileScannerCameraScanner.new,
        _nfcScannerFactory = nfcScannerFactory ?? NfcManagerScanner.new,
        _permissions = permissions ?? const PermissionHandlerPermissions(),
        _repositoryFactory = repositoryFactory ?? ((locator) => IsarHouseholdItemRepository(locator.get<Isar>())),
        _localization = localization ?? LocalizationCoordinator.instance;

  static const String pluginId = 'item_tracker';

  final ServiceLocator _locator;
  final CameraScannerFactory _cameraScannerFactory;
  final NfcScannerFactory _nfcScannerFactory;
  final HardwarePermissions _permissions;
  final HouseholdItemRepository Function(ServiceLocator locator) _repositoryFactory;
  final LocalizationCoordinator _localization;

  ItemTrackerDependencies get _dependencies => _locator.get<ItemTrackerDependencies>();

  @override
  String get id => pluginId;

  @override
  String get nameKey => 'itemTracker.title';

  @override
  String get descriptionKey => 'itemTracker.description';

  @override
  IconData get icon => Icons.qr_code_scanner;

  @override
  String get version => '1.0.0';

  @override
  List<CollectionSchema<dynamic>> get storageSchemas => itemTrackerSchemas;

  /// Siempre disponible: sin cámara ni NFC queda la entrada manual. Cada modo
  /// de escaneo comprueba su propio hardware.
  @override
  Future<bool> isAvailable() async => true;

  /// Registra el idioma y las traducciones del plugin. La app lo llama al
  /// registrar el plugin, aunque esté desactivado, para que el catálogo pueda
  /// mostrar su nombre ([nameKey]). Es idempotente.
  void registerLocalization() {
    _localization.register(
      pluginId,
      (code) => i18n.LocaleSettings.setLocaleRawSync(code),
      translate: (key) {
        final value = i18n.itemTrackerStrings[key];
        return value is String ? value : null;
      },
    );
  }

  @override
  Future<void> initialize() async {
    registerLocalization();
    await _locator.pushScope(
      pluginId,
      init: (locator) {
        final repository = _repositoryFactory(locator);
        final ids = locator.isRegistered<IdGenerator>() ? locator.get<IdGenerator>() : const UuidV4Generator();
        final clock = locator.isRegistered<Clock>() ? locator.get<Clock>() : const SystemClock();
        final EventBus eventBus;
        if (locator.isRegistered<EventBus>()) {
          eventBus = locator.get<EventBus>();
        } else {
          eventBus = EventBus();
          locator.registerSingleton(eventBus, dispose: (bus) => bus.dispose());
        }
        locator.registerSingleton(
          ItemTrackerDependencies(
            createItem: CreateItem(repository, ids, clock, eventBus),
            updateItem: UpdateItem(repository, ids, clock),
            bindIdentifier: BindIdentifier(repository, ids, clock),
            unbindIdentifier: UnbindIdentifier(repository, ids, clock),
            addItemEvent: AddItemEvent(repository, ids, clock),
            findItemByIdentifier: FindItemByIdentifier(repository),
            getItem: GetItem(repository),
            watchItem: WatchItem(repository),
            watchItems: WatchItems(repository),
            searchItems: SearchItems(repository),
            watchItemIdentifiers: WatchItemIdentifiers(repository),
            watchItemEvents: WatchItemEvents(repository),
            cameraScannerFactory: _cameraScannerFactory,
            nfcScannerFactory: _nfcScannerFactory,
            permissions: _permissions,
          ),
        );
      },
    );
  }

  @override
  Future<void> dispose() => _locator.dropScope(pluginId);

  @override
  Widget buildDashboardTile(BuildContext context) =>
      ItemTrackerDashboardTile(watchItems: _dependencies.watchItems);

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: ItemTrackerRoutes.base,
          redirect: (_, _) => ItemTrackerRoutes.scan,
        ),
        GoRoute(
          path: ItemTrackerRoutes.scan,
          builder: (context, state) {
            final deps = _dependencies;
            return BlocProvider(
              create: (_) => ScanBloc(
                findItemByIdentifier: deps.findItemByIdentifier,
                cameraScannerFactory: deps.cameraScannerFactory,
                nfcScannerFactory: deps.nfcScannerFactory,
                permissions: deps.permissions,
              )..add(const ScanStarted()),
              child: const ScanScreen(),
            );
          },
        ),
        GoRoute(
          path: ItemTrackerRoutes.items,
          builder: (context, state) => BlocProvider(
            create: (_) => ItemListCubit(_dependencies.watchItems),
            child: const ItemListScreen(),
          ),
        ),
        GoRoute(
          path: ItemTrackerRoutes.notFound,
          redirect: (_, state) =>
              ItemTrackerRoutes.identifierFrom(state.uri.queryParameters) == null ? ItemTrackerRoutes.scan : null,
          builder: (context, state) =>
              NotFoundScreen(identifier: ItemTrackerRoutes.identifierFrom(state.uri.queryParameters)!),
        ),
        // `create` y `associate` van antes de `item/:id` para que no se tomen como un ID.
        GoRoute(
          path: ItemTrackerRoutes.create,
          builder: (context, state) => BlocProvider(
            create: (_) => ItemFormCubit.create(
              createItem: _dependencies.createItem,
              identifier: ItemTrackerRoutes.identifierFrom(state.uri.queryParameters),
            ),
            child: const ItemFormScreen(),
          ),
        ),
        GoRoute(
          path: ItemTrackerRoutes.associate,
          redirect: (_, state) =>
              ItemTrackerRoutes.identifierFrom(state.uri.queryParameters) == null ? ItemTrackerRoutes.scan : null,
          builder: (context, state) => BlocProvider(
            create: (_) => AssociateCubit(
              identifier: ItemTrackerRoutes.identifierFrom(state.uri.queryParameters)!,
              searchItems: _dependencies.searchItems,
              bindIdentifier: _dependencies.bindIdentifier,
            ),
            child: const AssociateScreen(),
          ),
        ),
        GoRoute(
          path: ItemTrackerRoutes.detailPattern,
          builder: (context, state) {
            final deps = _dependencies;
            return BlocProvider(
              create: (_) => ItemDetailCubit(
                state.pathParameters['id']!,
                watchItem: deps.watchItem,
                watchItemIdentifiers: deps.watchItemIdentifiers,
                watchItemEvents: deps.watchItemEvents,
                unbindIdentifier: deps.unbindIdentifier,
              ),
              child: const ItemDetailScreen(),
            );
          },
        ),
        GoRoute(
          path: ItemTrackerRoutes.editPattern,
          builder: (context, state) => BlocProvider(
            create: (_) => ItemFormCubit.edit(
              state.pathParameters['id']!,
              getItem: _dependencies.getItem,
              updateItem: _dependencies.updateItem,
            ),
            child: const ItemFormScreen(),
          ),
        ),
        GoRoute(
          path: ItemTrackerRoutes.addEventPattern,
          builder: (context, state) => BlocProvider(
            create: (_) => AddEventCubit(state.pathParameters['id']!, addItemEvent: _dependencies.addItemEvent),
            child: const AddEventScreen(),
          ),
        ),
        GoRoute(
          path: ItemTrackerRoutes.addIdentifierPattern,
          builder: (context, state) {
            final deps = _dependencies;
            return BlocProvider(
              create: (_) => ScanBloc(
                findItemByIdentifier: deps.findItemByIdentifier,
                cameraScannerFactory: deps.cameraScannerFactory,
                nfcScannerFactory: deps.nfcScannerFactory,
                permissions: deps.permissions,
                bindToItemId: state.pathParameters['id']!,
                bindIdentifier: deps.bindIdentifier,
              )..add(const ScanStarted()),
              child: const ScanScreen(),
            );
          },
        ),
      ];
}
