import 'dart:async';

import 'package:core_hardware/core_hardware.dart';
import 'package:flutter/material.dart';

import 'scan_feedback.dart';

class CameraDemoTab extends StatefulWidget {
  const CameraDemoTab({
    super.key,
    required this.scannerFactory,
    required this.permissions,
  });

  final CameraIdentifierScanner Function() scannerFactory;
  final HardwarePermissions permissions;

  @override
  State<CameraDemoTab> createState() => _CameraDemoTabState();
}

class _CameraDemoTabState extends State<CameraDemoTab> {
  late final CameraIdentifierScanner _scanner = widget.scannerFactory();
  StreamSubscription<PhysicalScanResult>? _subscription;
  final List<PhysicalScanResult> _results = <PhysicalScanResult>[];

  HardwarePermissionStatus? _permission;
  bool _scanning = false;
  ScanException? _error;

  @override
  void initState() {
    super.initState();
    _subscription = _scanner.scanStream.listen(
      (PhysicalScanResult result) {
        if (!mounted) {
          return;
        }
        setState(() => _results.insert(0, result));
        announceScan(context, result);
      },
      onError: (Object error) {
        if (mounted && error is ScanException) {
          setState(() => _error = error);
        }
      },
    );
    unawaited(_checkPermission());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_scanner.dispose());
    super.dispose();
  }

  Future<void> _checkPermission({bool request = false}) async {
    final HardwarePermissionStatus status = request
        ? await widget.permissions.requestCamera()
        : await widget.permissions.cameraStatus();
    if (!mounted) {
      return;
    }
    setState(() => _permission = status);
    if (status == HardwarePermissionStatus.granted) {
      await _start();
    }
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _scanning = true;
    });
    await _scanner.startScanning();
  }

  Future<void> _stop() async {
    await _scanner.stopScanning();
    if (mounted) {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_permission) {
      null => const Center(child: CircularProgressIndicator()),
      HardwarePermissionStatus.granted => _buildScanner(context),
      HardwarePermissionStatus.denied => StatusMessage(
        icon: Icons.no_photography,
        message: 'Se necesita permiso de cámara para escanear códigos.',
        action: FilledButton(
          onPressed: () => _checkPermission(request: true),
          child: const Text('Conceder permiso'),
        ),
      ),
      HardwarePermissionStatus.permanentlyDenied => StatusMessage(
        icon: Icons.no_photography,
        message:
            'El permiso de cámara está denegado. Actívalo desde los Ajustes de la app.',
        action: FilledButton(
          onPressed: widget.permissions.openSettings,
          child: const Text('Abrir Ajustes'),
        ),
      ),
      HardwarePermissionStatus.restricted => const StatusMessage(
        icon: Icons.block,
        message:
            'El sistema restringe el uso de la cámara en este dispositivo.',
      ),
    };
  }

  Widget _buildScanner(BuildContext context) {
    final ScanException? error = _error;
    return Column(
      children: <Widget>[
        // Proporciones flexibles: una relación fija desborda en horizontal.
        Expanded(
          flex: 3,
          child: ClipRect(
            child: _scanner.buildPreview(
              context,
              errorBuilder: (BuildContext context, ScanException error) => StatusMessage(
                icon: Icons.videocam_off,
                message: describeScanError(error),
              ),
            ),
          ),
        ),
        if (error != null)
          MaterialBanner(
            content: Text(describeScanError(error)),
            actions: <Widget>[
              TextButton(
                onPressed: () => setState(() => _error = null),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _scanning
                      ? 'Apunta a un código QR o de barras.'
                      : 'Escaneo en pausa.',
                ),
              ),
              IconButton.filledTonal(
                tooltip: _scanning ? 'Pausar escaneo' : 'Reanudar escaneo',
                icon: Icon(_scanning ? Icons.pause : Icons.play_arrow),
                onPressed: _scanning ? _stop : _start,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(flex: 2, child: ScanResultsList(results: _results)),
      ],
    );
  }
}
