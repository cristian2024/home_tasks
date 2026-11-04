import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_secrets/core_secrets.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';

import '../sync_engine_exception.dart';
import 'household_invitation.dart';
import 'household_keys.dart';

/// Identidad del dispositivo y hogar al que pertenece: crearlo, unirse con una
/// invitación, salir y expulsar (solo el creador).
///
/// La clave del hogar va en el [SecretStore], con un nombre por hogar
/// ([secretKeyFor]): varios servicios sobre el mismo almacén (un espacio de
/// datos por hogar) no se pisan. El resto va en el [SyncStateRepository].
class HouseholdService {
  HouseholdService({
    required SyncStateRepository state,
    required SecretStore secrets,
    required SyncCipher cipher,
    IdGenerator ids = const UuidV4Generator(),
  })  : _state = state,
        _secrets = secrets,
        _cipher = cipher,
        _ids = ids;

  /// Clave del [SecretStore] donde se guarda la del hogar [householdId] (en
  /// base64url).
  static String secretKeyFor(String householdId) => 'sync.household.$householdId.key';

  /// Clave del [SecretStore] de las versiones con un solo hogar. Se lee para
  /// migrar a [secretKeyFor] y se mantiene al día mientras sea la del hogar
  /// actual, para que una versión anterior siga sincronizando.
  static const String legacySecretKey = 'sync.household.key';

  @Deprecated('Usar secretKeyFor(householdId); se quitará en una versión futura')
  static const String secretKey = legacySecretKey;

  final SyncStateRepository _state;
  final SecretStore _secrets;
  final SyncCipher _cipher;
  final IdGenerator _ids;

  /// Identidad del dispositivo. La crea con [defaultName] la primera vez.
  Future<DeviceIdentity> ensureDevice({required String defaultName}) async {
    final DeviceIdentity? device = await _state.readDevice();
    if (device != null) {
      return device;
    }
    final DeviceIdentity created = DeviceIdentity(deviceId: _ids.newId(), name: defaultName);
    await _state.saveDevice(created);
    return created;
  }

  /// Cambia el nombre con el que lo ven los demás.
  Future<DeviceIdentity> renameDevice(String name) async {
    final DeviceIdentity device = DeviceIdentity(deviceId: (await _requireDevice()).deviceId, name: name);
    await _state.saveDevice(device);
    return device;
  }

  Future<Household?> current() => _state.readHousehold();

  Stream<Household?> watch() => _state.watchHousehold();

  /// Claves del hogar actual, o `null` sin hogar (o sin su clave).
  Future<HouseholdKeys?> keys() async {
    final Household? household = await _state.readHousehold();
    final String? key = household == null ? null : await _readKey(household);
    if (household == null || key == null) {
      return null;
    }
    return HouseholdKeys(household, base64Url.decode(key), _cipher);
  }

  /// Crea un hogar con este dispositivo como creador y devuelve su
  /// invitación. Lanza [AlreadyInHouseholdException] si ya está en uno.
  Future<HouseholdInvitation> create() async {
    await _requireNoHousehold();
    final DeviceIdentity device = await _requireDevice();
    final Household household = Household(id: _ids.newId(), epoch: 1, creatorDeviceId: device.deviceId);
    return _save(household, await _cipher.newKey());
  }

  /// Invitación del hogar actual, para mostrar su QR. Lanza
  /// [NotInHouseholdException] sin hogar.
  Future<HouseholdInvitation> invitation() async {
    final Household? household = await _state.readHousehold();
    final String? key = household == null ? null : await _readKey(household);
    if (household == null || key == null) {
      throw const NotInHouseholdException();
    }
    return HouseholdInvitation(household: household, key: base64Url.decode(key));
  }

  /// Se une al hogar de [invitation]. Los datos locales se conservan y se
  /// fusionan al sincronizar. Si ya está en ese hogar, adopta la época de la
  /// invitación cuando es más nueva. Lanza [AlreadyInHouseholdException] si
  /// está en otro hogar.
  Future<void> join(HouseholdInvitation invitation) async {
    await _requireDevice();
    final Household? current = await _state.readHousehold();
    if (current != null && current.id != invitation.household.id) {
      throw AlreadyInHouseholdException(current.id);
    }
    if (current == null || invitation.household.epoch > current.epoch) {
      await _save(invitation.household, invitation.key);
    }
  }

  /// Sale del hogar: borra la clave, el hogar y los dispositivos conocidos.
  /// Los datos locales se conservan. No falla si no está en ninguno.
  Future<void> leave() async {
    final Household? household = await _state.readHousehold();
    if (household != null) {
      // Migra antes, para saber si la clave antigua es la de este hogar.
      await _readKey(household);
      if (await _legacyKeyBelongsTo(household.id)) {
        await _secrets.delete(legacySecretKey);
      }
      await _secrets.delete(secretKeyFor(household.id));
    }
    await _state.clearHousehold();
  }

  /// Expulsa a [deviceId]: abre una época nueva con otra clave y devuelve su
  /// invitación, que el resto debe volver a escanear. Lanza
  /// [NotInHouseholdException] sin hogar y [NotHouseholdCreatorException] si
  /// este dispositivo no lo creó.
  Future<HouseholdInvitation> expel(String deviceId) async {
    final Household? household = await _state.readHousehold();
    if (household == null) {
      throw const NotInHouseholdException();
    }
    if (!household.isCreator((await _requireDevice()).deviceId)) {
      throw const NotHouseholdCreatorException();
    }
    final HouseholdInvitation invitation = await _save(household.nextEpoch(), await _cipher.newKey());
    await _state.removePeer(deviceId);
    return invitation;
  }

  /// La clave va antes que el hogar: un hogar guardado sin su clave por
  /// hogar solo puede venir de una versión anterior, y [_readKey] la migra.
  Future<HouseholdInvitation> _save(Household household, Uint8List key) async {
    final Household? current = await _state.readHousehold();
    if (current != null && current.id == household.id) {
      // Una época nueva de un hogar aún sin migrar: migra antes, para saber
      // si la clave antigua es la suya.
      await _readKey(current);
    }
    final String encoded = base64Url.encode(key);
    final bool updateLegacy = await _legacyKeyBelongsTo(household.id);
    await _secrets.write(secretKeyFor(household.id), encoded);
    if (updateLegacy) {
      await _secrets.write(legacySecretKey, encoded);
    }
    await _state.saveHousehold(household);
    return HouseholdInvitation(household: household, key: key);
  }

  /// Clave de [household] (en base64url), o `null` si no la hay. Si falta la
  /// suya y está la de las versiones con un solo hogar, es la de este hogar
  /// (ver [_save]): la copia a [secretKeyFor], comprueba la copia y conserva
  /// la antigua.
  Future<String?> _readKey(Household household) async {
    final String name = secretKeyFor(household.id);
    final String? key = await _secrets.read(name);
    if (key != null) {
      return key;
    }
    final String? legacy = await _secrets.read(legacySecretKey);
    if (legacy == null) {
      return null;
    }
    await _secrets.write(name, legacy);
    if (await _secrets.read(name) != legacy) {
      throw StateError('No se pudo copiar la clave del hogar ${household.id}');
    }
    return legacy;
  }

  /// Si la clave antigua es (aún) la del hogar [householdId].
  Future<bool> _legacyKeyBelongsTo(String householdId) async {
    final String? legacy = await _secrets.read(legacySecretKey);
    return legacy != null && legacy == await _secrets.read(secretKeyFor(householdId));
  }

  Future<DeviceIdentity> _requireDevice() async {
    final DeviceIdentity? device = await _state.readDevice();
    if (device == null) {
      throw StateError('Falta la identidad del dispositivo: llamar antes a ensureDevice');
    }
    return device;
  }

  Future<void> _requireNoHousehold() async {
    final Household? current = await _state.readHousehold();
    if (current != null) {
      throw AlreadyInHouseholdException(current.id);
    }
  }
}
