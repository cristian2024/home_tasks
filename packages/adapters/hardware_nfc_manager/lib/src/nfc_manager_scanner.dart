import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

import 'package:core_hardware/core_hardware.dart'
    show
        HardwareStatus,
        NfcIdentifierScanner,
        PhysicalScanResult,
        ScanErrorCode,
        ScanException,
        ScanType,
        ScannedValueSanitizer;

import 'ndef_codec.dart';

/// [NfcIdentifierScanner] sobre `nfc_manager`.
///
/// En iOS la lectura muestra el diálogo nativo de CoreNFC con
/// [iosReadAlertMessage]; en Android no hay UI del sistema, así que la
/// pantalla debe mostrar la suya mientras haya una sesión activa.
class NfcManagerScanner implements NfcIdentifierScanner {
  NfcManagerScanner({
    NfcManager? manager,
    this.iosReadAlertMessage,
    this.iosWriteAlertMessage,
    this.iosWriteSuccessMessage,
  }) : _manager = manager;

  /// Textos ya localizados para el diálogo nativo de iOS.
  final String? iosReadAlertMessage;
  final String? iosWriteAlertMessage;
  final String? iosWriteSuccessMessage;

  final NfcManager? _manager;
  final StreamController<PhysicalScanResult> _results = StreamController<PhysicalScanResult>.broadcast();
  bool _sessionActive = false;

  NfcManager get _nfc => _manager ?? NfcManager.instance;

  static const Set<NfcPollingOption> _allPollingOptions = <NfcPollingOption>{
    NfcPollingOption.iso14443,
    NfcPollingOption.iso15693,
    NfcPollingOption.iso18092,
  };

  @override
  Stream<PhysicalScanResult> get scanStream => _results.stream;

  @override
  Future<HardwareStatus> checkHardware() async {
    try {
      return switch (await _nfc.checkAvailability()) {
        NfcAvailability.enabled => HardwareStatus.available,
        NfcAvailability.disabled => HardwareStatus.disabled,
        NfcAvailability.unsupported => HardwareStatus.unsupported,
      };
    } on UnsupportedError {
      return HardwareStatus.unsupported;
    } catch (_) {
      return HardwareStatus.unsupported;
    }
  }

  @override
  Future<void> startScanning() async {
    if (_sessionActive) {
      return;
    }
    final ScanException? unavailable = await _unavailableError();
    if (unavailable != null) {
      _results.addError(unavailable);
      return;
    }
    _sessionActive = true;
    try {
      await _nfc.startSession(
        pollingOptions: _allPollingOptions,
        alertMessageIos: iosReadAlertMessage,
        onDiscovered: _onTagRead,
        onSessionErrorIos: (NfcReaderSessionErrorIos error) {
          _sessionActive = false;
          _results.addError(_mapIosError(error));
        },
      );
    } catch (error) {
      _sessionActive = false;
      _results.addError(ScanException(ScanErrorCode.unknown, cause: error));
    }
  }

  @override
  Future<void> stopScanning() async {
    if (!_sessionActive) {
      return;
    }
    _sessionActive = false;
    try {
      await _nfc.stopSession();
    } catch (_) {
      // La sesión ya estaba cerrada por el sistema.
    }
  }

  @override
  Future<void> writeTag(String value) async {
    if (_sessionActive) {
      throw StateError('No se puede escribir un tag mientras hay una lectura en curso.');
    }
    final String sanitized = ScannedValueSanitizer.sanitize(value);
    final ScanException? unavailable = await _unavailableError();
    if (unavailable != null) {
      throw unavailable;
    }

    final Completer<void> completer = Completer<void>();
    _sessionActive = true;
    try {
      await _nfc.startSession(
        pollingOptions: _allPollingOptions,
        alertMessageIos: iosWriteAlertMessage,
        onDiscovered: (NfcTag tag) async {
          try {
            final Ndef? ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              throw const ScanException(ScanErrorCode.tagNotWritable);
            }
            await ndef.write(message: NdefMessage(records: <NdefRecord>[NdefCodec.encodeText(sanitized)]));
            await _finishWriteSession(alertMessageIos: iosWriteSuccessMessage);
            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (error) {
            await _finishWriteSession(errorMessageIos: error.toString());
            if (!completer.isCompleted) {
              completer.completeError(
                error is ScanException ? error : ScanException(ScanErrorCode.unknown, cause: error),
              );
            }
          }
        },
        onSessionErrorIos: (NfcReaderSessionErrorIos error) {
          _sessionActive = false;
          if (!completer.isCompleted) {
            completer.completeError(_mapIosError(error));
          }
        },
      );
    } catch (error) {
      _sessionActive = false;
      throw ScanException(ScanErrorCode.unknown, cause: error);
    }
    return completer.future;
  }

  @override
  Future<void> dispose() async {
    await stopScanning();
    await _results.close();
  }

  Future<void> _onTagRead(NfcTag tag) async {
    try {
      final Ndef? ndef = Ndef.from(tag);
      final NdefMessage? message = ndef?.cachedMessage ?? await ndef?.read();
      final String? rawValue = NdefCodec.resolveRawValue(message: message, uid: _tagUid(tag));
      if (rawValue == null) {
        throw const ScanException(ScanErrorCode.invalidValue, message: 'Tag sin contenido ni UID');
      }
      _results.add(
        PhysicalScanResult(rawValue: ScannedValueSanitizer.sanitize(rawValue), type: ScanType.nfc),
      );
    } on ScanException catch (error) {
      _results.addError(error);
    } catch (error) {
      _results.addError(ScanException(ScanErrorCode.unknown, cause: error));
    }
  }

  Future<void> _finishWriteSession({String? alertMessageIos, String? errorMessageIos}) async {
    _sessionActive = false;
    try {
      await _nfc.stopSession(alertMessageIos: alertMessageIos, errorMessageIos: errorMessageIos);
    } catch (_) {
      // La sesión ya estaba cerrada por el sistema.
    }
  }

  Future<ScanException?> _unavailableError() async {
    return switch (await checkHardware()) {
      HardwareStatus.available => null,
      HardwareStatus.disabled => const ScanException(ScanErrorCode.hardwareDisabled),
      HardwareStatus.unsupported => const ScanException(ScanErrorCode.hardwareUnsupported),
    };
  }

  static Uint8List? _tagUid(NfcTag tag) => switch (defaultTargetPlatform) {
        TargetPlatform.android => NfcTagAndroid.from(tag)?.id,
        TargetPlatform.iOS => MiFareIos.from(tag)?.identifier ??
            Iso7816Ios.from(tag)?.identifier ??
            Iso15693Ios.from(tag)?.identifier ??
            FeliCaIos.from(tag)?.currentIDm,
        _ => null,
      };

  static ScanException _mapIosError(NfcReaderSessionErrorIos error) =>
      error.code == NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled
          ? ScanException(ScanErrorCode.cancelled, message: error.message)
          : ScanException(ScanErrorCode.unknown, message: error.message, cause: error);
}
