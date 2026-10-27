import 'package:core_contracts/core_contracts.dart';
import 'package:core_contracts/testing.dart';

void main() {
  pluginPreferenceRepositoryContract(
    'en memoria',
    create: InMemoryPluginPreferenceRepository.new,
    dispose: (PluginPreferenceRepository repository) => (repository as InMemoryPluginPreferenceRepository).close(),
  );
}
