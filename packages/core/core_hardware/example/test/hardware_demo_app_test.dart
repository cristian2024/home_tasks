import 'package:core_hardware/core_hardware.dart';
import 'package:core_hardware/testing.dart';
import 'package:core_hardware_example/src/hardware_demo_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCameraScanner camera;
  late FakeNfcScanner nfc;
  late FakeHardwarePermissions permissions;

  setUp(() {
    camera = FakeCameraScanner();
    nfc = FakeNfcScanner();
    permissions = FakeHardwarePermissions();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      HardwareDemoApp(
        cameraScannerFactory: () => camera,
        nfcScannerFactory: () => nfc,
        permissions: permissions,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Cámara', () {
    testWidgets(
      'con permiso muestra la previsualización, escanea y lista lecturas',
      (tester) async {
        await pumpApp(tester);

        expect(find.byKey(FakeCameraScanner.previewKey), findsOneWidget);
        expect(camera.isScanning, isTrue);

        camera.emit('QR-123');
        // El evento del stream llega en una microtarea posterior al primer frame.
        await tester.pumpAndSettle();

        expect(find.text('QR-123'), findsOneWidget);
      },
    );

    testWidgets('pide el permiso cuando está denegado', (tester) async {
      permissions
        ..status = HardwarePermissionStatus.denied
        ..statusAfterRequest = HardwarePermissionStatus.granted;
      await pumpApp(tester);

      expect(find.byKey(FakeCameraScanner.previewKey), findsNothing);

      await tester.tap(find.text('Conceder permiso'));
      await tester.pumpAndSettle();

      expect(permissions.requestCalls, 1);
      expect(find.byKey(FakeCameraScanner.previewKey), findsOneWidget);
    });

    testWidgets('con denegación permanente ofrece abrir Ajustes', (
      tester,
    ) async {
      permissions.status = HardwarePermissionStatus.permanentlyDenied;
      await pumpApp(tester);

      await tester.tap(find.text('Abrir Ajustes'));

      expect(permissions.openSettingsCalls, 1);
    });

    testWidgets('libera el escáner al cambiar de pestaña', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('NFC'));
      await tester.pumpAndSettle();

      expect(camera.isDisposed, isTrue);
    });
  });

  group('NFC', () {
    Future<void> openNfcTab(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('NFC'));
      await tester.pumpAndSettle();
    }

    testWidgets('AC-06: sin NFC desactiva la opción con un mensaje', (
      tester,
    ) async {
      nfc.hardwareStatus = HardwareStatus.unsupported;
      await openNfcTab(tester);

      expect(find.textContaining('no tiene NFC'), findsOneWidget);
      expect(find.text('Leer tag'), findsNothing);
    });

    testWidgets('lee un tag y lo muestra', (tester) async {
      await openNfcTab(tester);

      await tester.tap(find.text('Leer tag'));
      await tester.pump();
      expect(find.text('Acerca un tag NFC para leerlo…'), findsOneWidget);

      nfc.emit('NFC-BED');
      await tester.pumpAndSettle();

      expect(find.text('NFC-BED'), findsOneWidget);
      expect(find.text('Acerca un tag NFC para leerlo…'), findsNothing);
    });

    testWidgets('escribe el texto indicado', (tester) async {
      await openNfcTab(tester);

      await tester.enterText(find.byType(TextField), 'NFC-CAMA');
      await tester.tap(find.text('Escribir tag'));
      await tester.pumpAndSettle();

      expect(nfc.writtenValues, ['NFC-CAMA']);
      expect(find.text('Tag escrito correctamente.'), findsOneWidget);
    });

    testWidgets('informa si el tag no admite escritura', (tester) async {
      nfc.writeError = const ScanException(ScanErrorCode.tagNotWritable);
      await openNfcTab(tester);

      await tester.tap(find.text('Escribir tag'));
      await tester.pumpAndSettle();

      expect(find.text('El tag no admite escritura.'), findsOneWidget);
    });
  });
}
