import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:equatable/equatable.dart';
import 'package:sync_engine/sync_engine.dart';

/// Qué muestra la pantalla de unirse a un hogar.
enum JoinPhase {
  /// Comprobando la cámara.
  starting,

  /// Leyendo con la cámara (y con el campo para pegar el código).
  scanning,

  /// Sin cámara: solo el campo.
  cameraUnavailable,

  /// Sin permiso para la cámara: el campo y, si es permanente, Ajustes.
  cameraDenied,

  joining,
  joined,
}

enum JoinError { invalidCode, alreadyInHousehold, generic }

class JoinState extends Equatable {
  const JoinState({this.phase = JoinPhase.starting, this.canOpenSettings = false, this.error, this.attempt = 0});

  final JoinPhase phase;

  /// El permiso se denegó de forma permanente: solo se cambia en Ajustes.
  final bool canOpenSettings;

  /// Error del último intento; [attempt] cambia en cada uno para avisar
  /// aunque se repita el mismo error.
  final JoinError? error;
  final int attempt;

  JoinState copyWith({JoinPhase? phase, bool? canOpenSettings, JoinError? Function()? error, int? attempt}) => JoinState(
        phase: phase ?? this.phase,
        canOpenSettings: canOpenSettings ?? this.canOpenSettings,
        error: error == null ? this.error : error(),
        attempt: attempt ?? this.attempt,
      );

  @override
  List<Object?> get props => <Object?>[phase, canOpenSettings, error, attempt];
}

/// Se une a un hogar con el código que muestra otro dispositivo: leído con la
/// cámara o pegado a mano.
class JoinHouseholdCubit extends Cubit<JoinState> {
  JoinHouseholdCubit({
    required HouseholdService households,
    CameraIdentifierScanner Function()? cameraFactory,
    HardwarePermissions? permissions,
  })  : _households = households,
        _cameraFactory = cameraFactory,
        _permissions = permissions,
        super(const JoinState());

  final HouseholdService _households;
  final CameraIdentifierScanner Function()? _cameraFactory;
  final HardwarePermissions? _permissions;
  CameraIdentifierScanner? _camera;
  StreamSubscription<PhysicalScanResult>? _scans;

  /// Lo que se ve en la vista previa mientras [JoinPhase.scanning].
  CameraIdentifierScanner? get camera => _camera;

  /// El último código leído que no sirvió, para no avisar en cada fotograma.
  String? _rejected;

  /// Pide el permiso y arranca la cámara, si la hay.
  Future<void> start() async {
    final CameraIdentifierScanner Function()? factory = _cameraFactory;
    if (factory == null) {
      emit(state.copyWith(phase: JoinPhase.cameraUnavailable));
      return;
    }
    final HardwarePermissions? permissions = _permissions;
    if (permissions != null) {
      HardwarePermissionStatus status = await permissions.cameraStatus();
      if (status == HardwarePermissionStatus.denied) {
        status = await permissions.requestCamera();
      }
      if (status != HardwarePermissionStatus.granted) {
        emit(state.copyWith(
          phase: JoinPhase.cameraDenied,
          canOpenSettings: status == HardwarePermissionStatus.permanentlyDenied,
        ));
        return;
      }
    }
    final CameraIdentifierScanner camera = factory();
    if (await camera.checkHardware() != HardwareStatus.available) {
      unawaited(camera.dispose());
      emit(state.copyWith(phase: JoinPhase.cameraUnavailable));
      return;
    }
    _camera = camera;
    _scans = camera.scanStream.listen(
      (PhysicalScanResult result) {
        if (result.rawValue != _rejected) {
          unawaited(submit(result.rawValue));
        }
      },
      onError: (Object _) {},
    );
    await camera.startScanning();
    if (!isClosed) {
      emit(state.copyWith(phase: JoinPhase.scanning));
    }
  }

  Future<void> openSettings() async => _permissions?.openSettings();

  /// Se une con [code]. Ignora lo que llegue mientras se une o ya se unió.
  Future<void> submit(String code) async {
    if (state.phase == JoinPhase.joining || state.phase == JoinPhase.joined) {
      return;
    }
    final JoinPhase previous = state.phase;
    final HouseholdInvitation invitation;
    try {
      invitation = HouseholdInvitation.parse(code.trim());
    } on FormatException {
      _fail(code, previous, JoinError.invalidCode);
      return;
    }
    emit(state.copyWith(phase: JoinPhase.joining, error: () => null));
    try {
      await _households.join(invitation);
    } on AlreadyInHouseholdException {
      _fail(code, previous, JoinError.alreadyInHousehold);
      return;
    } on Object {
      _fail(code, previous, JoinError.generic);
      return;
    }
    _releaseCamera();
    if (!isClosed) {
      emit(state.copyWith(phase: JoinPhase.joined));
    }
  }

  void _fail(String code, JoinPhase phase, JoinError error) {
    _rejected = code;
    if (!isClosed) {
      emit(state.copyWith(phase: phase, error: () => error, attempt: state.attempt + 1));
    }
  }

  // Sin await: en testWidgets esos futuros no terminan con el reloj simulado.
  void _releaseCamera() {
    unawaited(_scans?.cancel());
    _scans = null;
    unawaited(_camera?.dispose());
    _camera = null;
  }

  @override
  Future<void> close() {
    _releaseCamera();
    return super.close();
  }
}
