import 'dart:async';
import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../i18n/strings.g.dart';
import '../spaces/bring_data_dialog.dart';
import 'join_household_cubit.dart';

/// Unirse a un hogar: lee con la cámara el código que muestra otro
/// dispositivo o lo recibe pegado. Al unirse, vuelve atrás.
class JoinHouseholdScreen extends StatefulWidget {
  const JoinHouseholdScreen({super.key});

  @override
  State<JoinHouseholdScreen> createState() => _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends State<JoinHouseholdScreen> {
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _chooseData(BuildContext context) async {
    final JoinHouseholdCubit cubit = context.read<JoinHouseholdCubit>();
    final String spaceName = await cubit.activeSpaceName() ?? '';
    if (!context.mounted) {
      return;
    }
    final bool? bringData = await showBringDataDialog(context, spaceName: spaceName);
    if (bringData == null) {
      cubit.cancelChoice();
    } else {
      await cubit.chooseData(bringData: bringData);
    }
  }

  void _onState(BuildContext context, JoinState state) {
    if (state.phase == JoinPhase.choosingData) {
      unawaited(_chooseData(context));
      return;
    }
    final AppTranslations$app$sync$join$es joinStrings = appStrings.app.sync.join;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (state.phase == JoinPhase.joined) {
      messenger.showSnackBar(SnackBar(content: Text(joinStrings.joined)));
      context.pop();
      return;
    }
    final String? message = switch (state.error) {
      null => null,
      JoinError.invalidCode => joinStrings.invalidCode,
      JoinError.alreadyInHousehold => appStrings.app.sync.household.errorAlreadyInHousehold,
      JoinError.generic => appStrings.app.sync.household.errorGeneric,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$join$es joinStrings = appStrings.app.sync.join;
    final JoinHouseholdCubit cubit = context.read<JoinHouseholdCubit>();
    return Scaffold(
      appBar: AppTopBar(title: Text(joinStrings.title)),
      body: BlocConsumer<JoinHouseholdCubit, JoinState>(
        listenWhen: (JoinState previous, JoinState current) =>
            current.attempt != previous.attempt ||
            (current.phase == JoinPhase.joined && previous.phase != JoinPhase.joined) ||
            (current.phase == JoinPhase.choosingData && previous.phase != JoinPhase.choosingData),
        listener: _onState,
        builder: (BuildContext context, JoinState state) {
          final bool joining = state.phase == JoinPhase.joining ||
              state.phase == JoinPhase.joined ||
              state.phase == JoinPhase.choosingData;
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) => ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              children: <Widget>[
                _CameraArea(
                  state: state,
                  cubit: cubit,
                  previewHeight: math.max(_minPreviewHeight, constraints.maxHeight - _heightBesidesPreview),
                ),
                const SizedBox(height: AppSpacing.s300),
                AppTextField(
                  label: joinStrings.manualField,
                  controller: _code,
                  enabled: !joining,
                  textInputAction: TextInputAction.done,
                  onSubmitted: cubit.submit,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: joining ? joinStrings.joining : joinStrings.manualSubmit,
                  isLoading: joining,
                  expand: true,
                  onPressed: () => cubit.submit(_code.text),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Alto mínimo de la vista previa de la cámara.
const double _minPreviewHeight = 240.0;

/// Lo que ocupa el resto de la pantalla: márgenes, aviso, campo y botón.
const double _heightBesidesPreview = 234.0;

class _CameraArea extends StatelessWidget {
  const _CameraArea({required this.state, required this.cubit, required this.previewHeight});

  final JoinState state;
  final JoinHouseholdCubit cubit;
  final double previewHeight;

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$join$es joinStrings = appStrings.app.sync.join;
    final ThemeData theme = Theme.of(context);
    switch (state.phase) {
      case JoinPhase.starting:
        return const SizedBox(height: 120, child: AppLoadingView());
      case JoinPhase.cameraUnavailable:
        return Text(joinStrings.cameraUnavailable, style: theme.textTheme.bodyLarge);
      case JoinPhase.cameraDenied:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(joinStrings.cameraDenied, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                // Vuelve a pedir el permiso o, si se dio desde Ajustes, lo
                // comprueba y arranca la cámara.
                AppButton(
                  label: joinStrings.retryPermission,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  onPressed: cubit.start,
                ),
                if (state.canOpenSettings)
                  AppButton(
                    label: joinStrings.openSettings,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.medium,
                    onPressed: cubit.openSettings,
                  ),
              ],
            ),
          ],
        );
      case JoinPhase.scanning:
      case JoinPhase.choosingData:
      case JoinPhase.joining:
      case JoinPhase.joined:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: previewHeight,
              child: AppCameraFrame(child: cubit.camera?.buildPreview(context) ?? const SizedBox.shrink()),
            ),
            const SizedBox(height: AppSpacing.s300),
            Text(
              joinStrings.scanPrompt,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        );
    }
  }
}
