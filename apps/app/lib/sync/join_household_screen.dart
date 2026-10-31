import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../i18n/strings.g.dart';
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

  void _onState(BuildContext context, JoinState state) {
    final AppTranslations$app$sync$join$es t = appStrings.app.sync.join;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (state.phase == JoinPhase.joined) {
      messenger.showSnackBar(SnackBar(content: Text(t.joined)));
      context.pop();
      return;
    }
    final String? message = switch (state.error) {
      null => null,
      JoinError.invalidCode => t.invalidCode,
      JoinError.alreadyInHousehold => appStrings.app.sync.household.errorAlreadyInHousehold,
      JoinError.generic => appStrings.app.sync.household.errorGeneric,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$join$es t = appStrings.app.sync.join;
    final JoinHouseholdCubit cubit = context.read<JoinHouseholdCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocConsumer<JoinHouseholdCubit, JoinState>(
        listenWhen: (JoinState previous, JoinState current) =>
            current.attempt != previous.attempt || (current.phase == JoinPhase.joined && previous.phase != JoinPhase.joined),
        listener: _onState,
        builder: (BuildContext context, JoinState state) {
          final bool joining = state.phase == JoinPhase.joining || state.phase == JoinPhase.joined;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              _CameraArea(state: state, cubit: cubit),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: t.manualField,
                controller: _code,
                enabled: !joining,
                textInputAction: TextInputAction.done,
                onSubmitted: cubit.submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: joining ? t.joining : t.manualSubmit,
                isLoading: joining,
                expand: true,
                onPressed: () => cubit.submit(_code.text),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraArea extends StatelessWidget {
  const _CameraArea({required this.state, required this.cubit});

  final JoinState state;
  final JoinHouseholdCubit cubit;

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$join$es t = appStrings.app.sync.join;
    final ThemeData theme = Theme.of(context);
    switch (state.phase) {
      case JoinPhase.starting:
        return const SizedBox(height: 120, child: AppLoadingView());
      case JoinPhase.cameraUnavailable:
        return Text(t.cameraUnavailable, style: theme.textTheme.bodyLarge);
      case JoinPhase.cameraDenied:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(t.cameraDenied, style: theme.textTheme.bodyLarge),
            if (state.canOpenSettings) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppButton(label: t.openSettings, variant: AppButtonVariant.secondary, onPressed: cubit.openSettings),
            ],
          ],
        );
      case JoinPhase.scanning:
      case JoinPhase.joining:
      case JoinPhase.joined:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(t.scanPrompt, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.medium),
                child: cubit.camera?.buildPreview(context) ?? const SizedBox.shrink(),
              ),
            ),
          ],
        );
    }
  }
}
