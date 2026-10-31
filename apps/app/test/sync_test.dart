import 'package:core_hardware/core_hardware.dart';
import 'package:core_hardware/testing.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/sync/join_household_cubit.dart';
import 'package:home_utility_app/sync/join_household_screen.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:qr_display/qr_display.dart';
import 'package:sync_engine/sync_engine.dart';

import 'helpers/app_harness.dart';
import 'helpers/synced_device.dart';

HouseholdItem _item(String id, String name, {String? parentId}) {
  final DateTime now = DateTime.now().toUtc();
  return HouseholdItem(
    id: id,
    name: name,
    description: '',
    metadata: const ItemMetadata.empty(),
    createdAt: now,
    updatedAt: now,
    parentId: parentId,
  );
}

/// Deja correr las sesiones y el debounce del controlador.
Future<void> _settleSync(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late InMemorySyncNetwork network;
  final List<SyncedDevice> devices = <SyncedDevice>[];

  setUp(() => network = InMemorySyncNetwork());

  /// Como `testWidgets`, pero libera los dispositivos dentro del test: en un
  /// `tearDown`, con la app aún montada, `SyncController.stop()` no termina
  /// con el reloj simulado.
  void syncTest(String description, Future<void> Function(WidgetTester tester) body) {
    testWidgets(description, (WidgetTester tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox());
        for (final SyncedDevice device in devices) {
          await device.dispose();
        }
        devices.clear();
      }
    });
  }

  Future<SyncedDevice> device(String name) async {
    final SyncedDevice created = await SyncedDevice.create(name, network: network);
    devices.add(created);
    return created;
  }

  Future<void> openSync(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sincronizar con otros dispositivos'));
    await tester.pumpAndSettle();
  }

  testWidgets('AC-12: sin la sincronización compuesta, Configuración no la muestra', (WidgetTester tester) async {
    final AppHarness harness = AppHarness();
    addTearDown(harness.dispose);
    await harness.pump(tester, initialLocation: '/settings');

    expect(find.text('Sincronizar con otros dispositivos'), findsNothing);
  });

  syncTest('crear un hogar muestra su código QR y luego las secciones del hogar', (WidgetTester tester) async {
    final SyncedDevice a = await device('Teléfono A');
    await a.harness.pump(tester);
    await openSync(tester);

    expect(find.text('Sin hogar'), findsOneWidget);
    await tester.tap(find.text('Crear un hogar'));
    await tester.pumpAndSettle();

    final AppQrCode qr = tester.widget<AppQrCode>(find.byType(AppQrCode));
    final HouseholdInvitation invitation = HouseholdInvitation.parse(qr.data);
    expect(invitation.household, await a.sync.households.current());
    expect(find.bySemanticsLabel('Código QR para unirse al hogar'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Aún no se ha sincronizado'), findsOneWidget);
    expect(find.text('Teléfono A · Creaste este hogar'), findsOneWidget);
    expect(find.text('Todavía no se ha sincronizado con ningún otro dispositivo.'), findsOneWidget);
    expect(find.text('Ninguno por revisar'), findsOneWidget);
  });

  syncTest('AC-1 y AC-8: otro dispositivo se une, sus datos llegan y el creador lo expulsa', (WidgetTester tester) async {
    final SyncedDevice a = await device('Teléfono A');
    final SyncedDevice b = await device('Teléfono B');
    await a.harness.pump(tester);
    await b.startHeadless();
    await b.harness.items.createItem(_item('item-b', 'Caja de B'), events: const <ItemEvent>[]);

    await openSync(tester);
    await tester.tap(find.text('Crear un hogar'));
    await tester.pumpAndSettle();
    final String code = tester.widget<AppQrCode>(find.byType(AppQrCode)).data;
    await b.sync.households.join(HouseholdInvitation.parse(code));
    await tester.tap(find.byType(BackButton));
    await _settleSync(tester);
    await tester.tap(find.text('Sincronizar ahora'));
    await _settleSync(tester);

    expect((await a.harness.items.getById('item-b'))?.name, 'Caja de B');
    expect(find.text('Teléfono B'), findsOneWidget);
    expect(find.textContaining('Última sincronización:'), findsOneWidget);

    await tester.tap(find.byTooltip('Expulsar a Teléfono B'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Expulsar'));
    await tester.pumpAndSettle();

    expect(find.text('Clave nueva. Los demás dispositivos deben escanear este código.'), findsOneWidget);
    final HouseholdInvitation renewed = HouseholdInvitation.parse(tester.widget<AppQrCode>(find.byType(AppQrCode)).data);
    expect(renewed.household.epoch, 2);
    expect((await b.sync.households.current())!.epoch, 1, reason: 'el expulsado se queda en la época vieja');
  });

  syncTest('un dispositivo que no creó el hogar no puede expulsar y puede salir', (WidgetTester tester) async {
    final SyncedDevice a = await device('Teléfono A');
    final SyncedDevice b = await device('Teléfono B');
    await a.startHeadless();
    final HouseholdInvitation invitation = await a.sync.households.create();
    await b.sync.households.join(invitation);
    await b.harness.pump(tester);
    await openSync(tester);
    await tester.tap(find.text('Sincronizar ahora'));
    await _settleSync(tester);

    expect(find.text('Teléfono A'), findsOneWidget);
    expect(find.byTooltip('Expulsar a Teléfono A'), findsNothing);

    await tester.scrollUntilVisible(find.text('Salir del hogar'), 200);
    await tester.tap(find.text('Salir del hogar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salir'));
    await tester.pumpAndSettle();

    expect(await b.sync.households.current(), isNull);
    expect(find.text('Sin hogar'), findsOneWidget);
  });

  syncTest('cambiar el nombre del dispositivo', (WidgetTester tester) async {
    final SyncedDevice a = await device('Teléfono A');
    await a.harness.pump(tester);
    await a.sync.households.create();
    await openSync(tester);

    await tester.tap(find.byTooltip('Cambiar el nombre'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Cocina');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect((await a.sync.state.readDevice())!.name, 'Cocina');
    expect(find.text('Cocina · Creaste este hogar'), findsOneWidget);
  });

  group('unirse a un hogar', () {
    late SyncedDevice creator;
    late SyncedDevice joiner;
    late String code;

    Future<void> setUpDevices({CameraIdentifierScanner Function()? camera, HardwarePermissions? permissions}) async {
      creator = await device('Teléfono A');
      joiner = await device('Teléfono B');
      if (camera != null) {
        joiner.harness.locator.registerFactory<CameraIdentifierScanner>(camera);
      }
      if (permissions != null) {
        joiner.harness.locator.registerSingleton<HardwarePermissions>(permissions);
      }
      await creator.startHeadless();
      code = (await creator.sync.households.create()).encode();
    }

    Future<void> openJoin(WidgetTester tester) async {
      await joiner.harness.pump(tester);
      await openSync(tester);
      await tester.tap(find.text('Unirse a un hogar'));
      await tester.pump();
      await tester.pump();
    }

    syncTest('con la cámara: lee el código, se une y vuelve atrás', (WidgetTester tester) async {
      final FakeCameraScanner scanner = FakeCameraScanner();
      await setUpDevices(camera: () => scanner, permissions: FakeHardwarePermissions());
      await openJoin(tester);

      expect(find.byKey(FakeCameraScanner.previewKey), findsOneWidget);
      expect(scanner.isScanning, isTrue);
      scanner.emit(code);
      await tester.pumpAndSettle();

      expect(await joiner.sync.households.current(), await creator.sync.households.current());
      expect(find.text('Te uniste al hogar. Los datos se combinarán al sincronizar.'), findsOneWidget);
      expect(find.text('Mostrar el código para unirse'), findsOneWidget);
    });

    syncTest('un código que no es de un hogar avisa una sola vez', (WidgetTester tester) async {
      final FakeCameraScanner scanner = FakeCameraScanner();
      await setUpDevices(camera: () => scanner);
      await openJoin(tester);

      scanner
        ..emit('QR-123')
        ..emit('QR-123');
      await tester.pump();
      await tester.pump();

      expect(find.text('Ese código no es de un hogar de esta app.'), findsWidgets);
      final JoinHouseholdCubit cubit = tester.element(find.byType(JoinHouseholdScreen)).read<JoinHouseholdCubit>();
      expect(cubit.state.attempt, 1, reason: 'el mismo código leído otra vez no vuelve a avisar');
      expect(await joiner.sync.households.current(), isNull);
    });

    syncTest('sin cámara se pega el código', (WidgetTester tester) async {
      await setUpDevices();
      await openJoin(tester);

      expect(find.text('La cámara no está disponible. Pega el código del hogar.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.text('Unirse'));
      await tester.pumpAndSettle();

      expect(await joiner.sync.households.current(), isNotNull);
    });

    syncTest('sin permiso para la cámara ofrece abrir Ajustes', (WidgetTester tester) async {
      final FakeHardwarePermissions permissions =
          FakeHardwarePermissions(status: HardwarePermissionStatus.permanentlyDenied);
      await setUpDevices(camera: FakeCameraScanner.new, permissions: permissions);
      await openJoin(tester);

      expect(find.text('Sin permiso para la cámara. Pega el código del hogar o da el permiso en Ajustes.'), findsOneWidget);
      await tester.tap(find.text('Abrir Ajustes'));
      await tester.pump();
      expect(permissions.openSettingsCalls, 1);
    });

    syncTest('si ya está en otro hogar, lo explica', (WidgetTester tester) async {
      await setUpDevices();
      await joiner.sync.households.create();
      await joiner.harness.pump(tester, initialLocation: '/settings/sync/join');
      await tester.pump();

      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.text('Unirse'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Este dispositivo ya está en otro hogar. Sal de él antes de unirte a uno nuevo.'), findsOneWidget);
    });
  });

  group('conflictos', () {
    syncTest('se muestran con los nombres de los objetos y se resuelven', (WidgetTester tester) async {
      final SyncedDevice a = await device('Teléfono A');
      await a.sync.households.create();
      await a.harness.items.createItem(_item('caja', 'Caja'), events: const <ItemEvent>[]);
      await a.harness.items.createItem(_item('llaves', 'Llaves'), events: const <ItemEvent>[]);
      final SyncConflict conflict = SyncConflict(
        id: 'item_tracker.containerDeleted:llaves:caja',
        collection: ItemTrackerCollections.items,
        kind: ItemTrackerResolver.containerDeleted,
        entityIds: const <String>['llaves', 'caja'],
        options: <ConflictOption>[
          ConflictOption(ItemTrackerResolver.keepOption),
          ConflictOption(ItemTrackerResolver.deleteOption),
        ],
        provisionalOptionId: ItemTrackerResolver.keepOption,
        detectedAt: DateTime.utc(2026, 10, 31),
      );
      await a.harness.locator.get<ConflictRepository>().save(conflict);
      await a.harness.pump(tester);
      await openSync(tester);

      await tester.ensureVisible(find.text('1 por revisar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 por revisar'));
      await tester.pumpAndSettle();

      expect(find.text('Contenedor borrado'), findsOneWidget);
      expect(
        find.text('Se borró «Caja» mientras otro dispositivo guardaba «Llaves» dentro. «Llaves» quedó fuera.'),
        findsOneWidget,
      );
      expect(find.text('Conservar «Llaves»'), findsOneWidget);
      expect(find.text('Aplicada ahora'), findsOneWidget);

      await tester.tap(find.text('Borrar «Llaves» también'));
      await tester.pumpAndSettle();

      expect(find.text('Sin conflictos'), findsOneWidget);
      expect(await a.harness.items.getById('llaves'), isNull);
      expect((await a.sync.inbox.open()), isEmpty);
    });

    syncTest('con varios, «Dejar todos así» confirma la resolución de cada uno', (WidgetTester tester) async {
      final SyncedDevice a = await device('Teléfono A');
      await a.sync.households.create();
      final ConflictRepository conflicts = a.harness.locator.get<ConflictRepository>();
      for (final String id in <String>['uno', 'dos']) {
        await conflicts.save(SyncConflict(
          id: 'item_tracker.moveReverted:$id',
          collection: ItemTrackerCollections.items,
          kind: ItemTrackerResolver.moveReverted,
          entityIds: <String>[id],
          options: <ConflictOption>[ConflictOption(ItemTrackerResolver.confirmOption)],
          provisionalOptionId: ItemTrackerResolver.confirmOption,
          detectedAt: DateTime.utc(2026, 10, 31),
        ));
      }
      await a.harness.pump(tester, initialLocation: '/settings/sync/conflicts');

      expect(find.text('Movimiento deshecho'), findsNWidgets(2));
      expect(find.text('Entendido'), findsNWidgets(2));
      await tester.tap(find.text('Dejar todos así'));
      await tester.pumpAndSettle();

      expect(find.text('Sin conflictos'), findsOneWidget);
    });
  });
}
