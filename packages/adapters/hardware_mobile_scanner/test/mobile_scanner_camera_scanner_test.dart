import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hardware_mobile_scanner/src/mobile_scanner_camera_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Controlador que no toca la cámara: cuenta los arranques.
class _RecordingController extends MobileScannerController {
  _RecordingController() : super(autoStart: false);

  int starts = 0;
  int stops = 0;

  @override
  Future<void> start({CameraFacing? cameraDirection, CameraLensType? cameraLensType}) async => starts++;

  @override
  Future<void> stop() async => stops++;
}

class _Preview extends StatelessWidget {
  const _Preview(this.scanner);

  final MobileScannerCameraScanner scanner;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: scanner.buildPreview(context),
      );
}

void main() {
  late _RecordingController controller;
  late MobileScannerCameraScanner scanner;

  setUp(() {
    controller = _RecordingController();
    scanner = MobileScannerCameraScanner(controllerFactory: () => controller);
  });

  testWidgets('sin vista previa, startScanning espera a que se monte para arrancar', (WidgetTester tester) async {
    await scanner.startScanning();
    expect(controller.starts, 0);

    await tester.pumpWidget(_Preview(scanner));
    await tester.pump();

    expect(controller.starts, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('con la vista previa montada, startScanning arranca enseguida', (WidgetTester tester) async {
    await tester.pumpWidget(_Preview(scanner));
    await tester.pump();

    await scanner.startScanning();

    expect(controller.starts, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stopScanning antes de montar la vista previa cancela el arranque pendiente',
      (WidgetTester tester) async {
    await scanner.startScanning();
    await scanner.stopScanning();

    await tester.pumpWidget(_Preview(scanner));
    await tester.pump();

    expect(controller.starts, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('al desmontar la vista previa, el siguiente startScanning vuelve a esperarla',
      (WidgetTester tester) async {
    await tester.pumpWidget(_Preview(scanner));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());

    await scanner.startScanning();
    expect(controller.starts, 0);

    await tester.pumpWidget(_Preview(scanner));
    await tester.pump();
    expect(controller.starts, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
