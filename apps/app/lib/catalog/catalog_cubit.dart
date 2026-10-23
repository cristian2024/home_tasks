import 'package:bloc/bloc.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:equatable/equatable.dart';

import '../plugins/plugin_controller.dart';

class CatalogState extends Equatable {
  const CatalogState({this.plugins = const <PluginState>[], this.pending = const <String>{}});

  /// Todos los plugins registrados, en el orden del dashboard.
  final List<PluginState> plugins;

  /// Plugins con un cambio de activación en curso.
  final Set<String> pending;

  @override
  List<Object?> get props => <Object?>[
    <(String, PluginStatus)>[for (final PluginState p in plugins) (p.plugin.id, p.status)],
    pending,
  ];
}

/// Catálogo de plugins (`/plugins-catalog`): activar y desactivar.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._controller)
    : super(CatalogState(plugins: _controller.states)) {
    _controller.addListener(_onChanged);
  }

  final PluginController _controller;

  void _onChanged() =>
      emit(CatalogState(plugins: _controller.states, pending: state.pending));

  Future<void> setEnabled(String pluginId, {required bool enabled}) async {
    if (state.pending.contains(pluginId)) {
      return;
    }
    emit(
      CatalogState(
        plugins: state.plugins,
        pending: <String>{...state.pending, pluginId},
      ),
    );
    try {
      await _controller.setEnabled(pluginId, enabled: enabled);
    } finally {
      if (!isClosed) {
        emit(
          CatalogState(
            plugins: _controller.states,
            pending: <String>{...state.pending}..remove(pluginId),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _controller.removeListener(_onChanged);
    return super.close();
  }
}
