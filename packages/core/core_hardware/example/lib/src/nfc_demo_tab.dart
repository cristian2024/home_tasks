import 'dart:async';

import 'package:core_hardware/core_hardware.dart';
import 'package:flutter/material.dart';

import 'scan_feedback.dart';

class NfcDemoTab extends StatefulWidget {
  const NfcDemoTab({super.key, required this.scannerFactory});

  final NfcIdentifierScanner Function() scannerFactory;

  @override
  State<NfcDemoTab> createState() => _NfcDemoTabState();
}

enum _Session { idle, reading, writing }

class _NfcDemoTabState extends State<NfcDemoTab> {
  late final NfcIdentifierScanner _scanner = widget.scannerFactory();
  StreamSubscription<PhysicalScanResult>? _subscription;
  final List<PhysicalScanResult> _results = <PhysicalScanResult>[];
  final TextEditingController _writeController = TextEditingController(
    text: 'NFC-DEMO-001',
  );

  HardwareStatus? _status;
  _Session _session = _Session.idle;

  @override
  void initState() {
    super.initState();
    _subscription = _scanner.scanStream.listen(
      (PhysicalScanResult result) {
        if (!mounted) {
          return;
        }
        setState(() {
          _results.insert(0, result);
          _session = _Session
              .idle; // En iOS la sesión se cierra tras la primera lectura.
        });
        announceScan(context, result);
        unawaited(_scanner.stopScanning());
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() => _session = _Session.idle);
        if (error is ScanException) {
          _showMessage(describeScanError(error));
        }
      },
    );
    unawaited(_checkHardware());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_scanner.dispose());
    _writeController.dispose();
    super.dispose();
  }

  Future<void> _checkHardware() async {
    final HardwareStatus status = await _scanner.checkHardware();
    if (mounted) {
      setState(() => _status = status);
    }
  }

  Future<void> _read() async {
    setState(() => _session = _Session.reading);
    await _scanner.startScanning();
  }

  Future<void> _cancel() async {
    await _scanner.stopScanning();
    if (mounted) {
      setState(() => _session = _Session.idle);
    }
  }

  Future<void> _write() async {
    setState(() => _session = _Session.writing);
    try {
      await _scanner.writeTag(_writeController.text);
      _showMessage('Tag escrito correctamente.');
    } on ScanException catch (error) {
      _showMessage(describeScanError(error));
    } finally {
      if (mounted) {
        setState(() => _session = _Session.idle);
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_status) {
      null => const Center(child: CircularProgressIndicator()),
      // AC-06: sin NFC la opción se desactiva con un mensaje accesible.
      HardwareStatus.unsupported => const StatusMessage(
        icon: Icons.nfc,
        message:
            'Este dispositivo no tiene NFC. Puedes usar QR, códigos de barras o el registro manual.',
      ),
      HardwareStatus.disabled => StatusMessage(
        icon: Icons.nfc,
        message:
            'NFC está desactivado. Actívalo en los Ajustes del sistema y vuelve a comprobar.',
        action: FilledButton(
          onPressed: _checkHardware,
          child: const Text('Comprobar de nuevo'),
        ),
      ),
      HardwareStatus.available => _buildControls(context),
    };
  }

  Widget _buildControls(BuildContext context) {
    final bool busy = _session != _Session.idle;
    return Column(
      children: <Widget>[
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (busy)
                  // En Android no hay diálogo del sistema: la app muestra el suyo.
                  Card(
                    child: ListTile(
                      leading: const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(),
                      ),
                      title: Text(
                        _session == _Session.reading
                            ? 'Acerca un tag NFC para leerlo…'
                            : 'Acerca un tag NFC para escribirlo…',
                      ),
                      trailing: _session == _Session.reading
                          ? IconButton(
                              tooltip: 'Cancelar lectura',
                              icon: const Icon(Icons.close),
                              onPressed: _cancel,
                            )
                          : null,
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: busy ? null : _read,
                  icon: const Icon(Icons.nfc),
                  label: const Text('Leer tag'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _writeController,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Texto a escribir',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy ? null : _write,
                  icon: const Icon(Icons.edit),
                  label: const Text('Escribir tag'),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: ScanResultsList(results: _results)),
      ],
    );
  }
}
