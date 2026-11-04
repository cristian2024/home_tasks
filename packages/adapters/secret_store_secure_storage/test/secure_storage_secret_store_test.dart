import 'package:core_di/core_di.dart';
import 'package:core_secrets/core_secrets.dart';
import 'package:core_secrets/testing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_store_secure_storage/secret_store_secure_storage.dart';

/// Plataforma en memoria que además apunta las opciones de cada llamada.
class _RecordingPlatform extends TestFlutterSecureStoragePlatform {
  _RecordingPlatform() : super(<String, String>{});

  final List<Map<String, String>> options = <Map<String, String>>[];

  @override
  Future<String?> read({required String key, required Map<String, String> options}) {
    this.options.add(options);
    return super.read(key: key, options: options);
  }

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) {
    this.options.add(options);
    return super.write(key: key, value: value, options: options);
  }

  @override
  Future<void> delete({required String key, required Map<String, String> options}) {
    this.options.add(options);
    return super.delete(key: key, options: options);
  }
}

void main() {
  secretStoreContract('SecureStorageSecretStore', create: () {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    return SecureStorageSecretStore();
  });

  group('SecureStorageSecretStore', () {
    late _RecordingPlatform platform;

    setUp(() => FlutterSecureStoragePlatform.instance = platform = _RecordingPlatform());
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    for (final TargetPlatform target in <TargetPlatform>[TargetPlatform.iOS, TargetPlatform.macOS]) {
      test('en ${target.name}, el secreto no sale del dispositivo ni a iCloud', () async {
        debugDefaultTargetPlatformOverride = target;
        final SecureStorageSecretStore store = SecureStorageSecretStore();

        await store.write('sync.household.key', 'a');
        await store.read('sync.household.key');
        await store.delete('sync.household.key');

        expect(platform.options, hasLength(3));
        for (final Map<String, String> options in platform.options) {
          expect(options['accessibility'], 'first_unlock_this_device');
          expect(options['synchronizable'], 'false');
        }
      });
    }
  });

  test('SecureStorageSecrets registra SecureStorageSecretStore como SecretStore', () async {
    final ServiceLocator services = ServiceLocator();
    addTearDown(services.reset);

    await const SecureStorageSecrets().register(services);

    expect(services.get<SecretStore>(), isA<SecureStorageSecretStore>());
  });
}
