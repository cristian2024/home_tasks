import 'package:bloc_test/bloc_test.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/src/presentation/scan/scan_bloc.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late FakeHardware hardware;
  late TestUseCases useCases;
  late DateTime now;

  setUp(() {
    hardware = FakeHardware();
    useCases = TestUseCases();
    now = DateTime.utc(2026);
  });

  ScanBloc build({ScanMode mode = ScanMode.camera}) => ScanBloc(
        findItemByIdentifier: useCases.findItemByIdentifier,
        cameraScannerFactory: hardware.createCamera,
        nfcScannerFactory: hardware.createNfc,
        permissions: hardware.permissions,
        initialMode: mode,
        now: () => now,
      );

  group('cámara', () {
    blocTest<ScanBloc, ScanState>(
      'con permiso inicia la cámara',
      build: build,
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        // blocTest cierra el bloc (y libera la cámara) antes de `verify`.
        expect(hardware.camera.isScanning, isTrue);
        expect(bloc.cameraScanner, same(hardware.camera));
      },
      expect: () => [const ScanState(cameraPermission: HardwarePermissionStatus.granted)],
    );

    blocTest<ScanBloc, ScanState>(
      'sin permiso no crea la cámara; al concederlo la inicia',
      setUp: () => hardware.permissions
        ..status = HardwarePermissionStatus.denied
        ..statusAfterRequest = HardwarePermissionStatus.granted,
      build: build,
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        expect(hardware.cameras, isEmpty);
        bloc.add(const ScanCameraPermissionRequested());
        await Future<void>.delayed(Duration.zero);
        expect(hardware.camera.isScanning, isTrue);
      },
      expect: () => [
        const ScanState(cameraPermission: HardwarePermissionStatus.denied),
        const ScanState(cameraPermission: HardwarePermissionStatus.granted),
      ],
    );

    blocTest<ScanBloc, ScanState>(
      'abrir Ajustes delega en los permisos',
      build: build,
      act: (bloc) => bloc.add(const ScanSettingsRequested()),
      verify: (_) => expect(hardware.permissions.openSettingsCalls, 1),
    );

    blocTest<ScanBloc, ScanState>(
      'AC-03: un QR conocido produce ScanItemFound y detiene la cámara',
      setUp: () async => useCases.createItem(name: 'Caja A', identifier: (rawValue: 'QR-123', type: IdentifierType.qr)),
      build: build,
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        hardware.camera.emit('QR-123');
      },
      skip: 1,
      expect: () => [
        const ScanState(cameraPermission: HardwarePermissionStatus.granted, lookingUp: true),
        const ScanState(
          cameraPermission: HardwarePermissionStatus.granted,
          outcome: ScanItemFound(itemId: 'id-1', rawValue: 'QR-123', type: IdentifierType.qr, fromScanner: true),
        ),
      ],
      verify: (_) => expect(hardware.camera.isScanning, isFalse),
    );

    blocTest<ScanBloc, ScanState>(
      'AC-04: un QR desconocido produce ScanItemNotFound; al volver se reanuda la cámara',
      build: build,
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        hardware.camera.emit('UNKNOWN-99');
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.outcome, const ScanItemNotFound(rawValue: 'UNKNOWN-99', type: IdentifierType.qr, fromScanner: true));
        bloc.add(const ScanOutcomeHandled());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.outcome, isNull);
        expect(hardware.camera.isScanning, isTrue);
      },
    );

    blocTest<ScanBloc, ScanState>(
      'ignora lecturas repetidas dentro de 2 s y las acepta después',
      build: build,
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        hardware.camera.emit('A');
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ScanOutcomeHandled());
        await Future<void>.delayed(Duration.zero);
        hardware.camera.emit('A'); // Repetida: se ignora.
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.outcome, isNull);
        now = now.add(ScanBloc.duplicateWindow);
        hardware.camera.emit('A');
      },
      verify: (bloc) => expect(bloc.state.outcome, isA<ScanItemNotFound>()),
    );

    blocTest<ScanBloc, ScanState>(
      'los errores de cámara se convierten en avisos o en falta de permiso',
      build: build,
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        hardware.camera.emitError(const ScanException(ScanErrorCode.unknown));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.notice, ScanNotice.cameraError);
        bloc.add(const ScanNoticeShown());
        hardware.camera.emit('\x00'); // Valor inválido tras sanear.
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.notice, ScanNotice.readError);
        hardware.camera.emitError(const ScanException(ScanErrorCode.permissionDenied));
      },
      verify: (bloc) => expect(bloc.state.cameraPermission, HardwarePermissionStatus.denied),
    );
  });

  group('modos', () {
    blocTest<ScanBloc, ScanState>(
      'cambiar a modo Código libera la cámara (y viceversa)',
      build: build,
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ScanModeChanged(ScanMode.manual));
        await Future<void>.delayed(Duration.zero);
        expect(hardware.cameras.single.isDisposed, isTrue);
        expect(bloc.cameraScanner, isNull);
        bloc.add(const ScanModeChanged(ScanMode.camera));
        await Future<void>.delayed(Duration.zero);
        expect(hardware.cameras, hasLength(2));
        expect(hardware.camera.isScanning, isTrue);
      },
    );

    blocTest<ScanBloc, ScanState>(
      'cerrar el bloc libera los escáneres',
      build: build,
      act: (bloc) => bloc.add(const ScanStarted()),
      verify: (_) => expect(hardware.camera.isDisposed, isTrue),
    );
  });

  group('NFC', () {
    blocTest<ScanBloc, ScanState>(
      'AC-06: sin NFC informa unsupported y no permite leer',
      setUp: () => hardware.nfcStatus = HardwareStatus.unsupported,
      build: () => build(mode: ScanMode.nfc),
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ScanNfcReadRequested());
      },
      expect: () => [const ScanState(mode: ScanMode.nfc, nfcStatus: HardwareStatus.unsupported)],
      verify: (_) => expect(hardware.nfc.isScanning, isFalse),
    );

    blocTest<ScanBloc, ScanState>(
      'NFC desactivado: al comprobar de nuevo detecta que se activó',
      setUp: () => hardware.nfcStatus = HardwareStatus.disabled,
      build: () => build(mode: ScanMode.nfc),
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        hardware.nfc.hardwareStatus = HardwareStatus.available;
        bloc.add(const ScanNfcStatusRefreshed());
      },
      expect: () => [
        const ScanState(mode: ScanMode.nfc, nfcStatus: HardwareStatus.disabled),
        const ScanState(mode: ScanMode.nfc, nfcStatus: HardwareStatus.available),
      ],
    );

    blocTest<ScanBloc, ScanState>(
      'lee una etiqueta, detiene la sesión y busca el objeto',
      setUp: () async => useCases.createItem(name: 'Cama'),
      build: () => build(mode: ScanMode.nfc),
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ScanNfcReadRequested());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.nfcReading, isTrue);
        expect(hardware.nfc.isScanning, isTrue);
        hardware.nfc.emit('NFC-BED');
      },
      verify: (bloc) {
        expect(bloc.state.nfcReading, isFalse);
        expect(hardware.nfc.isScanning, isFalse);
        expect(bloc.state.outcome, const ScanItemNotFound(rawValue: 'NFC-BED', type: IdentifierType.nfc, fromScanner: true));
      },
    );

    blocTest<ScanBloc, ScanState>(
      'no deduplica lecturas NFC: cada una es una acción del usuario',
      build: () => build(mode: ScanMode.nfc),
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        for (var i = 0; i < 2; i++) {
          bloc.add(const ScanNfcReadRequested());
          await Future<void>.delayed(Duration.zero);
          hardware.nfc.emit('NFC-1');
          await Future<void>.delayed(Duration.zero);
          expect(bloc.state.outcome, isA<ScanItemNotFound>(), reason: 'lectura ${i + 1}');
          bloc.add(const ScanOutcomeHandled());
          await Future<void>.delayed(Duration.zero);
        }
      },
    );

    blocTest<ScanBloc, ScanState>(
      'cancelar la lectura detiene la sesión',
      build: () => build(mode: ScanMode.nfc),
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ScanNfcReadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ScanNfcReadCancelled());
      },
      verify: (bloc) {
        expect(bloc.state.nfcReading, isFalse);
        expect(hardware.nfc.isScanning, isFalse);
      },
    );

    blocTest<ScanBloc, ScanState>(
      'los errores de NFC actualizan el estado o muestran un aviso',
      build: () => build(mode: ScanMode.nfc),
      act: (bloc) async {
        bloc.add(const ScanStarted());
        await Future<void>.delayed(Duration.zero);
        hardware.nfc.emitError(const ScanException(ScanErrorCode.cancelled));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.notice, ScanNotice.readCancelled);
        hardware.nfc.emitError(const ScanException(ScanErrorCode.unknown));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.notice, ScanNotice.readError);
        hardware.nfc.emitError(const ScanException(ScanErrorCode.hardwareDisabled));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.nfcStatus, HardwareStatus.disabled);
        hardware.nfc.emitError(const ScanException(ScanErrorCode.hardwareUnsupported));
      },
      verify: (bloc) => expect(bloc.state.nfcStatus, HardwareStatus.unsupported),
    );
  });

  group('entrada manual', () {
    blocTest<ScanBloc, ScanState>(
      'busca el código escrito (sin espacios sobrantes) y no lo anuncia',
      setUp: () async => useCases.createItem(name: 'Caja', identifier: (rawValue: '049000000443', type: IdentifierType.barcode)),
      build: () => build(mode: ScanMode.manual),
      act: (bloc) => bloc.add(const ScanManualSubmitted(rawValue: ' 049000000443 ', type: IdentifierType.barcode)),
      expect: () => [
        const ScanState(mode: ScanMode.manual, lookingUp: true),
        const ScanState(
          mode: ScanMode.manual,
          outcome: ScanItemFound(
            itemId: 'id-1',
            rawValue: '049000000443',
            type: IdentifierType.barcode,
            fromScanner: false,
          ),
        ),
      ],
    );

    blocTest<ScanBloc, ScanState>(
      'un código con caracteres de control produce un aviso',
      build: () => build(mode: ScanMode.manual),
      act: (bloc) => bloc.add(const ScanManualSubmitted(rawValue: 'A\u0007B', type: IdentifierType.qr)),
      verify: (bloc) => expect(bloc.state.notice, ScanNotice.invalidValue),
    );
  });
}
