import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:equatable/equatable.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../domain/use_cases/bind_identifier.dart';
import '../../domain/use_cases/find_item_by_identifier.dart';
import '../../item_tracker_dependencies.dart';
import '../common/item_tracker_l10n.dart';

enum ScanMode { camera, nfc, manual }

/// Aviso puntual que la pantalla muestra una vez (SnackBar).
enum ScanNotice { cameraError, readError, readCancelled, invalidValue, itemNotFound, unexpected }

/// Resultado de identificar un código: la pantalla navega y después envía
/// [ScanOutcomeHandled].
sealed class ScanOutcome extends Equatable {
  const ScanOutcome({required this.rawValue, required this.type, required this.fromScanner});

  final String rawValue;
  final IdentifierType type;

  /// Si viene de un escáner (se anuncia a los lectores de pantalla).
  final bool fromScanner;

  @override
  List<Object?> get props => <Object?>[rawValue, type, fromScanner];
}

final class ScanItemFound extends ScanOutcome {
  const ScanItemFound({required this.itemId, required super.rawValue, required super.type, required super.fromScanner});

  final String itemId;

  @override
  List<Object?> get props => <Object?>[...super.props, itemId];
}

final class ScanItemNotFound extends ScanOutcome {
  const ScanItemNotFound({required super.rawValue, required super.type, required super.fromScanner});
}

/// Modo asociar: el identificador quedó ligado al objeto [itemId].
final class ScanIdentifierBound extends ScanOutcome {
  const ScanIdentifierBound({required this.itemId, required super.rawValue, required super.type, required super.fromScanner});

  final String itemId;

  @override
  List<Object?> get props => <Object?>[...super.props, itemId];
}

/// Modo asociar: el identificador ya estaba ligado a [boundItemId] (que puede
/// ser el mismo objeto) y no se asoció.
final class ScanBindRejected extends ScanOutcome {
  const ScanBindRejected({
    required this.boundItemId,
    required this.boundItemName,
    required this.sameItem,
    required super.rawValue,
    required super.type,
    required super.fromScanner,
  });

  final String boundItemId;
  final String boundItemName;
  final bool sameItem;

  @override
  List<Object?> get props => <Object?>[...super.props, boundItemId, boundItemName, sameItem];
}

class ScanState extends Equatable {
  const ScanState({
    this.mode = ScanMode.camera,
    this.cameraPermission,
    this.nfcStatus,
    this.nfcReading = false,
    this.lookingUp = false,
    this.outcome,
    this.notice,
  });

  final ScanMode mode;

  /// `null` mientras se comprueba.
  final HardwarePermissionStatus? cameraPermission;

  /// `null` hasta que se entra en modo NFC por primera vez.
  final HardwareStatus? nfcStatus;
  final bool nfcReading;
  final bool lookingUp;
  final ScanOutcome? outcome;
  final ScanNotice? notice;

  ScanState copyWith({
    ScanMode? mode,
    HardwarePermissionStatus? cameraPermission,
    HardwareStatus? nfcStatus,
    bool? nfcReading,
    bool? lookingUp,
    ScanOutcome? Function()? outcome,
    ScanNotice? Function()? notice,
  }) {
    return ScanState(
      mode: mode ?? this.mode,
      cameraPermission: cameraPermission ?? this.cameraPermission,
      nfcStatus: nfcStatus ?? this.nfcStatus,
      nfcReading: nfcReading ?? this.nfcReading,
      lookingUp: lookingUp ?? this.lookingUp,
      outcome: outcome == null ? this.outcome : outcome(),
      notice: notice == null ? this.notice : notice(),
    );
  }

  @override
  List<Object?> get props => <Object?>[mode, cameraPermission, nfcStatus, nfcReading, lookingUp, outcome, notice];
}

sealed class ScanEvent {
  const ScanEvent();
}

final class ScanStarted extends ScanEvent {
  const ScanStarted();
}

final class ScanModeChanged extends ScanEvent {
  const ScanModeChanged(this.mode);
  final ScanMode mode;
}

final class ScanCameraPermissionRequested extends ScanEvent {
  const ScanCameraPermissionRequested();
}

final class ScanSettingsRequested extends ScanEvent {
  const ScanSettingsRequested();
}

final class ScanNfcStatusRefreshed extends ScanEvent {
  const ScanNfcStatusRefreshed();
}

final class ScanNfcReadRequested extends ScanEvent {
  const ScanNfcReadRequested();
}

final class ScanNfcReadCancelled extends ScanEvent {
  const ScanNfcReadCancelled();
}

final class ScanManualSubmitted extends ScanEvent {
  const ScanManualSubmitted({required this.rawValue, required this.type});
  final String rawValue;
  final IdentifierType type;
}

final class ScanOutcomeHandled extends ScanEvent {
  const ScanOutcomeHandled();
}

final class ScanNoticeShown extends ScanEvent {
  const ScanNoticeShown();
}

final class _ScanResultReceived extends ScanEvent {
  const _ScanResultReceived(this.result);
  final PhysicalScanResult result;
}

final class _ScanErrorReceived extends ScanEvent {
  const _ScanErrorReceived(this.error, {required this.fromNfc});
  final ScanException error;
  final bool fromNfc;
}

/// Pantalla de escaneo (BLoC por ser un flujo continuo de lecturas, §11.1).
///
/// Con [bindToItemId] funciona en modo asociar: cada lectura se asocia a ese
/// objeto en lugar de buscar a qué objeto pertenece.
///
/// Solo existe el escáner del modo activo: al cambiar de modo el anterior se
/// libera (cámara apagada en modo NFC o Código, spec §16).
class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc({
    required FindItemByIdentifier findItemByIdentifier,
    required CameraScannerFactory cameraScannerFactory,
    required NfcScannerFactory nfcScannerFactory,
    required HardwarePermissions permissions,
    ScanMode initialMode = ScanMode.camera,
    this.bindToItemId,
    BindIdentifier? bindIdentifier,
    DateTime Function()? now,
  })  : assert(bindToItemId == null || bindIdentifier != null, 'El modo asociar necesita BindIdentifier'),
        _find = findItemByIdentifier,
        _bind = bindIdentifier,
        _cameraFactory = cameraScannerFactory,
        _nfcFactory = nfcScannerFactory,
        _permissions = permissions,
        _now = now ?? DateTime.now,
        super(ScanState(mode: initialMode)) {
    on<ScanStarted>(_onStarted);
    on<ScanModeChanged>(_onModeChanged);
    on<ScanCameraPermissionRequested>(_onPermissionRequested);
    on<ScanSettingsRequested>((_, _) => _permissions.openSettings());
    on<ScanNfcStatusRefreshed>(_onNfcStatusRefreshed);
    on<ScanNfcReadRequested>(_onNfcReadRequested);
    on<ScanNfcReadCancelled>(_onNfcReadCancelled);
    on<ScanManualSubmitted>(_onManualSubmitted);
    on<ScanOutcomeHandled>(_onOutcomeHandled);
    on<ScanNoticeShown>((_, Emitter<ScanState> emit) => emit(state.copyWith(notice: () => null)));
    on<_ScanResultReceived>(_onResult);
    on<_ScanErrorReceived>(_onError);
  }

  /// Lecturas de cámara iguales dentro de este intervalo se ignoran.
  static const Duration duplicateWindow = Duration(seconds: 2);

  /// Objeto al que se asocian las lecturas; `null` fuera del modo asociar.
  final String? bindToItemId;

  final FindItemByIdentifier _find;
  final BindIdentifier? _bind;
  final CameraScannerFactory _cameraFactory;
  final NfcScannerFactory _nfcFactory;
  final HardwarePermissions _permissions;
  final DateTime Function() _now;

  CameraIdentifierScanner? _camera;
  NfcIdentifierScanner? _nfc;
  StreamSubscription<PhysicalScanResult>? _cameraSubscription;
  StreamSubscription<PhysicalScanResult>? _nfcSubscription;
  ({String key, DateTime at})? _lastAccepted;

  /// Lecturas de cámara ya rechazadas en modo asociar: no se reintentan
  /// mientras el código siga en el encuadre.
  final Set<String> _rejectedKeys = <String>{};

  /// Escáner de cámara activo, para que la pantalla muestre su preview.
  CameraIdentifierScanner? get cameraScanner => _camera;

  Future<void> _onStarted(ScanStarted event, Emitter<ScanState> emit) => _enterMode(state.mode, emit);

  Future<void> _onModeChanged(ScanModeChanged event, Emitter<ScanState> emit) async {
    if (event.mode == state.mode) {
      return;
    }
    _releaseCamera();
    _releaseNfc();
    emit(state.copyWith(mode: event.mode, nfcReading: false));
    await _enterMode(event.mode, emit);
  }

  Future<void> _enterMode(ScanMode mode, Emitter<ScanState> emit) async {
    switch (mode) {
      case ScanMode.camera:
        final HardwarePermissionStatus permission = await _permissions.cameraStatus();
        emit(state.copyWith(cameraPermission: permission));
        await _startCameraIfAllowed();
      case ScanMode.nfc:
        final NfcIdentifierScanner nfc = _ensureNfc();
        emit(state.copyWith(nfcStatus: await nfc.checkHardware()));
      case ScanMode.manual:
        break;
    }
  }

  Future<void> _onPermissionRequested(ScanCameraPermissionRequested event, Emitter<ScanState> emit) async {
    emit(state.copyWith(cameraPermission: await _permissions.requestCamera()));
    await _startCameraIfAllowed();
  }

  Future<void> _onNfcStatusRefreshed(ScanNfcStatusRefreshed event, Emitter<ScanState> emit) async {
    emit(state.copyWith(nfcStatus: await _ensureNfc().checkHardware()));
  }

  Future<void> _onNfcReadRequested(ScanNfcReadRequested event, Emitter<ScanState> emit) async {
    if (state.nfcStatus != HardwareStatus.available || state.nfcReading) {
      return;
    }
    emit(state.copyWith(nfcReading: true));
    await _ensureNfc().startScanning();
  }

  Future<void> _onNfcReadCancelled(ScanNfcReadCancelled event, Emitter<ScanState> emit) async {
    await _nfc?.stopScanning();
    emit(state.copyWith(nfcReading: false));
  }

  Future<void> _onManualSubmitted(ScanManualSubmitted event, Emitter<ScanState> emit) =>
      _resolve(event.rawValue.trim(), event.type, emit, fromScanner: false);

  Future<void> _onResult(_ScanResultReceived event, Emitter<ScanState> emit) async {
    final PhysicalScanResult result = event.result;
    final IdentifierType type = identifierTypeFromScan(result.type);
    final String key = '${type.name}:${result.rawValue}';
    if (state.lookingUp || state.outcome != null) {
      return;
    }
    // La cámara detecta el mismo código una y otra vez mientras sigue en el
    // encuadre (también al volver de otra pantalla). En NFC cada lectura es
    // una acción explícita del usuario, así que no se deduplica.
    if (result.type != ScanType.nfc) {
      final DateTime now = _now();
      final ({DateTime at, String key})? last = _lastAccepted;
      if (_rejectedKeys.contains(key) ||
          (last != null && last.key == key && now.difference(last.at) < duplicateWindow)) {
        return;
      }
      _lastAccepted = (key: key, at: now);
    }
    if (result.type == ScanType.nfc) {
      await _nfc?.stopScanning();
      emit(state.copyWith(nfcReading: false));
    }
    await _resolve(result.rawValue, type, emit, fromScanner: true, fromCamera: result.type != ScanType.nfc);
  }

  /// Busca el objeto del identificador o, en modo asociar, lo asocia.
  Future<void> _resolve(
    String rawValue,
    IdentifierType type,
    Emitter<ScanState> emit, {
    required bool fromScanner,
    bool fromCamera = false,
  }) async {
    emit(state.copyWith(lookingUp: true));
    try {
      final ScanOutcome outcome = await _outcomeFor(rawValue, type, fromScanner: fromScanner);
      if (outcome is ScanBindRejected && fromCamera) {
        _rejectedKeys.add('${type.name}:$rawValue');
      }
      await _camera?.stopScanning();
      emit(state.copyWith(lookingUp: false, outcome: () => outcome));
    } on ItemValidationException {
      emit(state.copyWith(lookingUp: false, notice: () => ScanNotice.invalidValue));
    } on ItemNotFoundException {
      emit(state.copyWith(lookingUp: false, notice: () => ScanNotice.itemNotFound));
    } catch (_) {
      emit(state.copyWith(lookingUp: false, notice: () => ScanNotice.unexpected));
    }
  }

  Future<ScanOutcome> _outcomeFor(String rawValue, IdentifierType type, {required bool fromScanner}) async {
    final String? itemId = bindToItemId;
    if (itemId == null) {
      final HouseholdItem? item = await _find(rawValue: rawValue, type: type);
      return item == null
          ? ScanItemNotFound(rawValue: rawValue, type: type, fromScanner: fromScanner)
          : ScanItemFound(itemId: item.id, rawValue: rawValue, type: type, fromScanner: fromScanner);
    }
    try {
      final PhysicalIdentifier identifier = await _bind!(itemId, rawValue: rawValue, type: type);
      return ScanIdentifierBound(
        itemId: itemId,
        rawValue: identifier.rawValue,
        type: identifier.type,
        fromScanner: fromScanner,
      );
    } on IdentifierAlreadyBoundException catch (error) {
      final HouseholdItem? boundItem = await _find(rawValue: error.rawValue, type: error.type);
      return ScanBindRejected(
        boundItemId: error.boundItemId,
        boundItemName: boundItem?.name ?? '',
        sameItem: error.boundItemId == itemId,
        rawValue: error.rawValue,
        type: error.type,
        fromScanner: fromScanner,
      );
    }
  }

  Future<void> _onOutcomeHandled(ScanOutcomeHandled event, Emitter<ScanState> emit) async {
    emit(state.copyWith(outcome: () => null));
    if (state.mode == ScanMode.camera) {
      await _startCameraIfAllowed();
    }
  }

  void _onError(_ScanErrorReceived event, Emitter<ScanState> emit) {
    final ScanErrorCode code = event.error.code;
    if (event.fromNfc) {
      emit(
        switch (code) {
          ScanErrorCode.hardwareUnsupported => state.copyWith(nfcReading: false, nfcStatus: HardwareStatus.unsupported),
          ScanErrorCode.hardwareDisabled => state.copyWith(nfcReading: false, nfcStatus: HardwareStatus.disabled),
          ScanErrorCode.cancelled => state.copyWith(nfcReading: false, notice: () => ScanNotice.readCancelled),
          _ => state.copyWith(nfcReading: false, notice: () => ScanNotice.readError),
        },
      );
      return;
    }
    emit(
      switch (code) {
        ScanErrorCode.permissionDenied => state.copyWith(cameraPermission: HardwarePermissionStatus.denied),
        ScanErrorCode.invalidValue => state.copyWith(notice: () => ScanNotice.readError),
        _ => state.copyWith(notice: () => ScanNotice.cameraError),
      },
    );
  }

  Future<void> _startCameraIfAllowed() async {
    if (state.mode != ScanMode.camera || state.cameraPermission != HardwarePermissionStatus.granted) {
      return;
    }
    final CameraIdentifierScanner camera = _camera ??= _cameraFactory();
    _cameraSubscription ??= camera.scanStream.listen(
      (PhysicalScanResult result) => add(_ScanResultReceived(result)),
      onError: (Object error) {
        if (error is ScanException) {
          add(_ScanErrorReceived(error, fromNfc: false));
        }
      },
    );
    await camera.startScanning();
  }

  NfcIdentifierScanner _ensureNfc() {
    final NfcIdentifierScanner nfc = _nfc ??= _nfcFactory();
    _nfcSubscription ??= nfc.scanStream.listen(
      (PhysicalScanResult result) => add(_ScanResultReceived(result)),
      onError: (Object error) {
        if (error is ScanException) {
          add(_ScanErrorReceived(error, fromNfc: true));
        }
      },
    );
    return nfc;
  }

  // Liberar el hardware no bloquea el cambio de modo. Cancelar la suscripción
  // deja de entregar eventos en el acto; su futuro y el `dispose` del escáner
  // terminan en segundo plano (esperarlos dentro del handler puede bloquear
  // el bloc, p. ej. en los widget tests).
  void _releaseCamera() {
    unawaited(_cameraSubscription?.cancel());
    _cameraSubscription = null;
    unawaited(_camera?.dispose());
    _camera = null;
  }

  void _releaseNfc() {
    unawaited(_nfcSubscription?.cancel());
    _nfcSubscription = null;
    unawaited(_nfc?.dispose());
    _nfc = null;
  }

  @override
  Future<void> close() {
    _releaseCamera();
    _releaseNfc();
    return super.close();
  }
}
