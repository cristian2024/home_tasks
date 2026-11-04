import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app.dart';
import '../i18n/strings.g.dart';
import 'space_switcher.dart';

/// Raíz de la app con espacios de datos: la app del espacio abierto, que se
/// crea de nuevo (con otro router y otros plugins) en cada cambio, y una
/// pantalla de espera mientras se cambia.
class SpaceRoot extends StatelessWidget {
  const SpaceRoot({super.key, required this.switcher});

  final SpaceSwitcher switcher;

  @override
  Widget build(BuildContext context) => BlocBuilder<SpaceSwitcher, SpaceSession>(
        bloc: switcher,
        builder: (BuildContext context, SpaceSession session) => session.switching
            ? const _SwitchingApp()
            : HomeUtilityApp(
                key: ObjectKey(session.environment),
                environment: session.environment,
                initialLocation: session.location,
                spaces: switcher,
                notice: session.notice,
              ),
      );
}

/// Mientras se cambia de espacio no hay entorno: ni router ni plugins.
class _SwitchingApp extends StatelessWidget {
  const _SwitchingApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(appStrings.app.spaces.switching),
              ],
            ),
          ),
        ),
      );
}
