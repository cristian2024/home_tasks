import 'package:core_hardware/core_hardware.dart';
import 'package:flutter/material.dart';

import 'camera_demo_tab.dart';
import 'nfc_demo_tab.dart';

/// Demo de core_hardware. Recibe los escáneres por inyección para poder
/// probarla con los fakes de `package:core_hardware/testing.dart`.
class HardwareDemoApp extends StatelessWidget {
  const HardwareDemoApp({
    super.key,
    required this.cameraScannerFactory,
    required this.nfcScannerFactory,
    required this.permissions,
  });

  final CameraIdentifierScanner Function() cameraScannerFactory;
  final NfcIdentifierScanner Function() nfcScannerFactory;
  final HardwarePermissions permissions;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'core_hardware',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1E88E5)),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E88E5),
        brightness: Brightness.dark,
      ),
      home: _HomePage(app: this),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage({required this.app});

  final HardwareDemoApp app;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Solo se monta la pestaña visible: cada escáner se crea al entrar y se
    // libera al salir (spec §16).
    return Scaffold(
      appBar: AppBar(title: const Text('core_hardware')),
      body: switch (_tab) {
        0 => CameraDemoTab(
          scannerFactory: widget.app.cameraScannerFactory,
          permissions: widget.app.permissions,
        ),
        _ => NfcDemoTab(scannerFactory: widget.app.nfcScannerFactory),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (int index) => setState(() => _tab = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Cámara',
          ),
          NavigationDestination(icon: Icon(Icons.nfc), label: 'NFC'),
        ],
      ),
    );
  }
}
