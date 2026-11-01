import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';
import 'package:sync_engine/sync_engine.dart';

import '../spaces/space_switcher.dart';

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

  /// Un código válido con el espacio actual sin hogar: el usuario elige si
  /// se lleva sus datos al hogar ([JoinHouseholdCubit.chooseData]).
  choosingData,

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
///
/// Con [spaces], cada hogar va en su espacio de datos: si el hogar ya tiene
/// uno, se une allí; si el espacio actual es de otro hogar, en uno nuevo y
/// vacío; si no tiene hogar, el usuario elige si lleva sus datos
/// ([JoinPhase.choosingData]). Unirse en otro espacio lo abre, y la app
/// cambia de entorno.
class JoinHouseholdCubit extends Cubit<JoinState> {
  JoinHouseholdCubit({
    required HouseholdService households,
    SpaceSwitcher? spaces,
    CameraIdentifierScanner Function()? cameraFactory,
    HardwarePermissions? permissions,
  })  : _households = households,
        _spaces = spaces,
        _cameraFactory = cameraFactory,
        _permissions = permissions,
        super(const JoinState());

  final HouseholdService _households;
  final SpaceSwitcher? _spaces;

  /// Invitación pendiente mientras [JoinPhase.choosingData], y la fase a la
  /// que se vuelve si el usuario cancela.
  HouseholdInvitation? _pending;
  JoinPhase _beforeChoice = JoinPhase.starting;
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

  /// Nombre del espacio de datos abierto, o `null` sin espacios.
  Future<String?> activeSpaceName() async => (await _spaces?.activeSpace())?.name;

  /// Se une con [code]. Ignora lo que llegue mientras se une, ya se unió o
  /// el usuario elige qué hacer con sus datos.
  Future<void> submit(String code) async {
    if (state.phase == JoinPhase.joining ||
        state.phase == JoinPhase.joined ||
        state.phase == JoinPhase.choosingData) {
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
    final SpaceSwitcher? spaces = _spaces;
    if (spaces != null) {
      final String? existing = await spaces.spaceOfHousehold(invitation.household.id);
      if (existing != null && existing != spaces.activeSpaceId) {
        return _joinInSpace(spaces, invitation, spaceId: existing);
      }
      if (existing == null) {
        final Household? current = await _households.current();
        if (current == null) {
          _pending = invitation;
          _beforeChoice = previous;
          emit(state.copyWith(phase: JoinPhase.choosingData, error: () => null));
          return;
        }
        if (current.id != invitation.household.id) {
          return _joinInSpace(spaces, invitation);
        }
      }
    }
    return _joinHere(code, previous, invitation);
  }

  /// Respuesta a [JoinPhase.choosingData]: con [bringData], se une en este
  /// espacio y comparte sus datos; si no, en un espacio nuevo y vacío.
  Future<void> chooseData({required bool bringData}) async {
    final HouseholdInvitation? invitation = _pending;
    final SpaceSwitcher? spaces = _spaces;
    if (state.phase != JoinPhase.choosingData || invitation == null || spaces == null) {
      return;
    }
    _pending = null;
    if (bringData) {
      return _joinHere(invitation.encode(), _beforeChoice, invitation);
    }
    return _joinInSpace(spaces, invitation);
  }

  /// El usuario cerró la elección sin decidir: vuelve a leer códigos.
  void cancelChoice() {
    if (state.phase == JoinPhase.choosingData) {
      _pending = null;
      emit(state.copyWith(phase: _beforeChoice));
    }
  }

  /// Se une en otro espacio: la app cambia de entorno y cierra este cubit.
  Future<void> _joinInSpace(SpaceSwitcher spaces, HouseholdInvitation invitation, {String? spaceId}) async {
    emit(state.copyWith(phase: JoinPhase.joining, error: () => null));
    _releaseCamera();
    await spaces.joinInSpace(invitation, spaceId: spaceId);
  }

  Future<void> _joinHere(String code, JoinPhase previous, HouseholdInvitation invitation) async {
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
