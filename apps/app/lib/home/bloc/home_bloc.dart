import 'package:bloc/bloc.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:equatable/equatable.dart';

import '../../plugins/plugin_controller.dart';

class HomeState extends Equatable {
  const HomeState({
    this.loading = true,
    this.tiles = const <PluginState>[],
    this.retrying = false,
  });

  final bool loading;

  /// Plugins del dashboard en su orden (§6.2): activos y disponibles,
  /// incluidos los que fallaron al iniciarse (tarjeta de error).
  final List<PluginState> tiles;
  final bool retrying;

  @override
  List<Object?> get props => <Object?>[
    loading,
    <(String, PluginStatus)>[for (final PluginState tile in tiles) (tile.plugin.id, tile.status)],
    retrying,
  ];
}

sealed class HomeEvent {
  const HomeEvent();
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// Índices con la convención de `ReorderableListView.onReorderItem`:
/// [newIndex] es la posición final del elemento.
final class HomeTileMoved extends HomeEvent {
  const HomeTileMoved(this.oldIndex, this.newIndex);
  final int oldIndex;
  final int newIndex;
}

final class HomeRetryRequested extends HomeEvent {
  const HomeRetryRequested();
}

final class _HomePluginsChanged extends HomeEvent {
  const _HomePluginsChanged();
}

/// Pantalla de inicio (§6.2): refleja el [PluginController] y traduce los
/// gestos del usuario en cambios de orden y reintentos.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._controller) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeTileMoved>(
      (HomeTileMoved event, _) =>
          _controller.moveDashboardTile(event.oldIndex, event.newIndex),
    );
    on<HomeRetryRequested>(_onRetry);
    on<_HomePluginsChanged>((_, Emitter<HomeState> emit) => emit(_fromController()));
    _controller.addListener(_onControllerChanged);
  }

  final PluginController _controller;

  void _onControllerChanged() => add(const _HomePluginsChanged());

  HomeState _fromController({bool retrying = false}) => HomeState(
    loading: !_controller.isLoaded,
    tiles: _controller.dashboard,
    retrying: retrying,
  );

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    if (!_controller.isLoaded) {
      await _controller.load();
    }
    emit(_fromController());
  }

  Future<void> _onRetry(
    HomeRetryRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(_fromController(retrying: true));
    await _controller.load();
    emit(_fromController());
  }

  @override
  Future<void> close() {
    _controller.removeListener(_onControllerChanged);
    return super.close();
  }
}
