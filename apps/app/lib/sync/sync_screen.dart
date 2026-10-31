import 'package:core_sync/core_sync.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_engine/sync_engine.dart';

import '../i18n/strings.g.dart';
import '../navigation/app_router.dart';
import 'sync_cubit.dart';
import 'sync_time_format.dart';

/// Sincronización con los demás dispositivos de casa: estado, hogar
/// (crear, unirse, mostrar el código, salir y expulsar) y acceso a los
/// conflictos.
class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appStrings.app.sync.title)),
      body: BlocBuilder<SyncCubit, SyncViewState>(
        builder: (BuildContext context, SyncViewState state) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            _StatusCard(state: state),
            if (state.household == null)
              _NoHouseholdSection(busy: state.busy)
            else ...<Widget>[
              _HouseholdSection(state: state),
              _DevicesSection(state: state),
              _ConflictsSection(openConflicts: state.openConflicts),
            ],
          ],
        ),
      ),
    );
  }
}

/// Muestra el error de una acción del hogar, si lo hubo.
void showSyncActionError(BuildContext context, SyncActionError? error) {
  if (error == null || !context.mounted) {
    return;
  }
  final AppTranslations$app$sync$household$es t = appStrings.app.sync.household;
  final String message = switch (error) {
    SyncActionError.alreadyInHousehold => t.errorAlreadyInHousehold,
    SyncActionError.notCreator => t.errorNotCreator,
    SyncActionError.generic => t.errorGeneric,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final SyncViewState state;

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$status$es t = appStrings.app.sync.status;
    final SyncStatus status = state.status;
    final DateTime? lastSyncAt = status.lastSyncAt;
    final int? pending = status.pendingChanges;
    if (state.household == null) {
      return AppSyncStatusCard(tone: AppSyncTone.off, title: t.noHousehold, message: t.noHouseholdMessage);
    }
    final SyncErrorKind? error = status.lastError;
    final AppSyncTone tone = switch (status.phase) {
      SyncPhase.syncing => AppSyncTone.syncing,
      _ when error != null => AppSyncTone.error,
      SyncPhase.disabled => AppSyncTone.off,
      SyncPhase.idle => AppSyncTone.idle,
    };
    return AppSyncStatusCard(
      tone: tone,
      title: switch (tone) {
        AppSyncTone.syncing => t.syncing,
        AppSyncTone.error => t.failed,
        _ => lastSyncAt == null ? t.neverSynced : t.syncedAt(time: formatSyncTime(context, lastSyncAt)),
      },
      details: <String>[
        if (pending != null && pending > 0) t.pendingChanges(n: pending),
        t.visibleDevices(n: status.visibleDevices.length),
      ],
      message: switch (error) {
        null => null,
        SyncErrorKind.transport => t.errorTransport,
        SyncErrorKind.authentication => t.errorAuthentication,
        SyncErrorKind.protocol => t.errorProtocol,
        SyncErrorKind.unknown => t.errorUnknown,
      },
      actionLabel: t.syncNow,
      onAction: context.read<SyncCubit>().syncNow,
    );
  }
}

class _NoHouseholdSection extends StatelessWidget {
  const _NoHouseholdSection({required this.busy});

  final bool busy;

  Future<void> _create(BuildContext context) async {
    final SyncActionError? error = await context.read<SyncCubit>().createHousehold();
    if (!context.mounted) {
      return;
    }
    if (error == null) {
      await context.push(AppRoutes.syncInvitation);
    } else {
      showSyncActionError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$household$es t = appStrings.app.sync.household;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(t.section),
        AppButton(label: t.create, icon: Icons.add_home_outlined, isLoading: busy, expand: true, onPressed: () => _create(context)),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: t.join,
          icon: Icons.qr_code_scanner,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: busy ? null : () => context.push(AppRoutes.syncJoin),
        ),
      ],
    );
  }
}

class _HouseholdSection extends StatelessWidget {
  const _HouseholdSection({required this.state});

  final SyncViewState state;

  Future<void> _rename(BuildContext context) async {
    final SyncCubit cubit = context.read<SyncCubit>();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _RenameDialog(initialName: state.device?.name ?? ''),
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }
    final SyncActionError? error = await cubit.rename(name.trim());
    if (context.mounted) {
      showSyncActionError(context, error);
    }
  }

  Future<void> _leave(BuildContext context) async {
    final AppTranslations$app$sync$household$es t = appStrings.app.sync.household;
    final SyncCubit cubit = context.read<SyncCubit>();
    final bool confirmed = await showAppConfirmDialog(
      context,
      title: t.leaveTitle,
      message: t.leaveMessage,
      confirmLabel: t.leaveConfirm,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    final SyncActionError? error = await cubit.leave();
    if (context.mounted) {
      showSyncActionError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$household$es t = appStrings.app.sync.household;
    return AppSettingsSection(
      title: t.section,
      children: <Widget>[
        AppSettingsTile(
          icon: Icons.qr_code_2,
          title: t.showCode,
          subtitle: t.showCodeDescription,
          onTap: () => context.push(AppRoutes.syncInvitation),
        ),
        AppSettingsTile(
          icon: Icons.smartphone,
          title: t.thisDevice,
          subtitle: <String>[state.device?.name ?? '', if (state.isCreator) t.creator].join(' · '),
          trailing: AppIconButton(icon: Icons.edit_outlined, tooltip: t.rename, onPressed: () => _rename(context)),
        ),
        AppSettingsTile(
          icon: Icons.logout,
          title: t.leave,
          enabled: !state.busy,
          onTap: () => _leave(context),
        ),
      ],
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$household$es t = appStrings.app.sync.household;
    return AlertDialog(
      title: Text(t.renameTitle),
      content: AppTextField(
        label: t.renameField,
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        onSubmitted: (String value) => Navigator.of(context).pop(value),
      ),
      actions: <Widget>[
        AppButton(label: t.save, onPressed: () => Navigator.of(context).pop(_controller.text)),
      ],
    );
  }
}

class _DevicesSection extends StatelessWidget {
  const _DevicesSection({required this.state});

  final SyncViewState state;

  Future<void> _expel(BuildContext context, SyncPeer peer) async {
    final AppTranslations$app$sync$household$es t = appStrings.app.sync.household;
    final SyncCubit cubit = context.read<SyncCubit>();
    final bool confirmed = await showAppConfirmDialog(
      context,
      title: t.expelTitle(name: peer.name),
      message: t.expelMessage(name: peer.name),
      confirmLabel: t.expelConfirm,
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final SyncActionError? error = await cubit.expel(peer.deviceId);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      showSyncActionError(context, error);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t.expelled)));
    await context.push(AppRoutes.syncInvitation);
  }

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$household$es t = appStrings.app.sync.household;
    return AppSettingsSection(
      title: t.devicesSection,
      children: <Widget>[
        if (state.peers.isEmpty)
          ListTile(title: Text(t.noDevices))
        else
          for (final SyncPeer peer in state.peers)
            AppSettingsTile(
              icon: Icons.devices_other,
              title: peer.name,
              subtitle: t.lastSynced(time: formatSyncTime(context, peer.lastSyncedAt)),
              trailing: state.isCreator
                  ? AppIconButton(
                      icon: Icons.person_remove_outlined,
                      tooltip: t.expel(name: peer.name),
                      onPressed: state.busy ? null : () => _expel(context, peer),
                    )
                  : null,
            ),
      ],
    );
  }
}

class _ConflictsSection extends StatelessWidget {
  const _ConflictsSection({required this.openConflicts});

  final int openConflicts;

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$conflicts$es t = appStrings.app.sync.conflicts;
    return AppSettingsSection(
      title: t.title,
      children: <Widget>[
        AppSettingsTile(
          icon: openConflicts == 0 ? Icons.check_circle_outline : Icons.report_problem_outlined,
          title: t.tile,
          subtitle: openConflicts == 0 ? t.tileNone : t.tileCount(n: openConflicts),
          trailing: openConflicts == 0 ? null : AppBadge(label: '$openConflicts', tone: AppBadgeTone.warning),
          onTap: () => context.push(AppRoutes.syncConflicts),
        ),
      ],
    );
  }
}
