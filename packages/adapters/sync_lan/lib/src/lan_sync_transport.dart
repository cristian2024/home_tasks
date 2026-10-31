import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';

import 'lan_transport.dart';

/// Añade un [LanTransport] a `SyncTransports`. Quien compone la app solo lo
/// elige, antes de `SyncModule`:
///
/// ```dart
/// adapters: <DependencyModule>[LanSyncTransport()]
/// ```
///
/// La app declara en iOS `NSLocalNetworkUsageDescription` y `NSBonjourServices`
/// con [serviceType], y en Android los permisos de red y multicast.
class LanSyncTransport implements DependencyModule {
  const LanSyncTransport({this.serviceType = LanTransport.defaultServiceType});

  /// Tipo de servicio mDNS que se anuncia y se busca.
  final String serviceType;

  @override
  Future<void> register(ServiceLocator services) async {
    final LanTransport transport = LanTransport(serviceType: serviceType);
    services.registerSingleton<LanTransport>(transport, dispose: (LanTransport transport) => transport.dispose());
    SyncTransports.of(services).add(transport);
  }
}
