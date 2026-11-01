import 'package:core_spaces/core_spaces.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../i18n/strings.g.dart';
import 'spaces_cubit.dart';

/// Espacios de datos del dispositivo: cada uno, local o de un hogar, con sus
/// propios datos y plugins. Tocar uno cambia a él.
class SpacesScreen extends StatelessWidget {
  const SpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$spaces$es t = appStrings.app.spaces;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocBuilder<SpacesCubit, SpacesState>(
        builder: (BuildContext context, SpacesState state) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            AppSettingsSection(
              title: t.section,
              children: <Widget>[
                for (final DataSpace space in state.spaces)
                  _SpaceTile(space: space, active: space.id == state.activeSpaceId, busy: state.busy),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: t.create,
              icon: Icons.add,
              variant: AppButtonVariant.secondary,
              expand: true,
              isLoading: state.busy,
              onPressed: () => _create(context, spaceCount: state.spaces.length),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(t.createDescription, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Pide el nombre del espacio nuevo y, si no se cancela, lo crea.
Future<void> _create(BuildContext context, {required int spaceCount}) async {
  final AppTranslations$app$spaces$es t = appStrings.app.spaces;
  final SpacesCubit cubit = context.read<SpacesCubit>();
  final String? name = await showDialog<String>(
    context: context,
    builder: (BuildContext context) => _SpaceNameDialog(
      title: t.createTitle,
      initialName: t.newSpaceName(n: spaceCount + 1),
      confirmLabel: t.createConfirm,
    ),
  );
  if (name != null && name.trim().isNotEmpty && context.mounted) {
    await _run(context, cubit.create(name.trim()));
  }
}

/// Avisa si [action] no se completó.
Future<void> _run(BuildContext context, Future<bool> action) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  if (!await action) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(appStrings.app.spaces.errorGeneric)));
  }
}

class _SpaceTile extends StatelessWidget {
  const _SpaceTile({required this.space, required this.active, required this.busy});

  final DataSpace space;
  final bool active;
  final bool busy;

  Future<void> _switch(BuildContext context) async {
    final AppTranslations$app$spaces$es t = appStrings.app.spaces;
    final SpacesCubit cubit = context.read<SpacesCubit>();
    final bool confirmed = await showAppConfirmDialog(
      context,
      title: t.switchTitle(name: space.name),
      message: t.switchMessage,
      confirmLabel: t.switchConfirm,
    );
    if (confirmed && context.mounted) {
      await _run(context, cubit.switchTo(space.id));
    }
  }

  Future<void> _rename(BuildContext context) async {
    final SpacesCubit cubit = context.read<SpacesCubit>();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SpaceNameDialog(
        title: appStrings.app.spaces.renameTitle,
        initialName: space.name,
        confirmLabel: appStrings.app.spaces.save,
      ),
    );
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      await _run(context, cubit.rename(space.id, name.trim()));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final AppTranslations$app$spaces$es t = appStrings.app.spaces;
    final SpacesCubit cubit = context.read<SpacesCubit>();
    final bool confirmed = await showAppConfirmDialog(
      context,
      title: t.deleteTitle(name: space.name),
      message: t.deleteMessage,
      confirmLabel: t.deleteConfirm,
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await _run(context, cubit.delete(space.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$spaces$es t = appStrings.app.spaces;
    return AppSettingsTile(
      icon: space.isShared ? Icons.home_outlined : Icons.smartphone,
      title: space.name,
      subtitle: <String>[space.isShared ? t.shared : t.local, if (active) t.active].join(' · '),
      enabled: !busy,
      onTap: active ? null : () => _switch(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconButton(
            icon: Icons.edit_outlined,
            tooltip: t.rename(name: space.name),
            onPressed: busy ? null : () => _rename(context),
          ),
          if (!active)
            AppIconButton(
              icon: Icons.delete_outline,
              tooltip: t.delete(name: space.name),
              onPressed: busy ? null : () => _delete(context),
            ),
        ],
      ),
    );
  }
}

/// Pide el nombre de un espacio. Devuelve el texto escrito, o `null` si se
/// cancela.
class _SpaceNameDialog extends StatefulWidget {
  const _SpaceNameDialog({required this.title, required this.initialName, required this.confirmLabel});

  final String title;
  final String initialName;
  final String confirmLabel;

  @override
  State<_SpaceNameDialog> createState() => _SpaceNameDialogState();
}

class _SpaceNameDialogState extends State<_SpaceNameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$spaces$es t = appStrings.app.spaces;
    return AlertDialog(
      title: Text(widget.title),
      content: AppTextField(
        label: t.renameField,
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        onSubmitted: (String value) => Navigator.of(context).pop(value),
      ),
      actions: <Widget>[
        AppButton(label: t.cancel, variant: AppButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
        AppButton(label: widget.confirmLabel, onPressed: () => Navigator.of(context).pop(_controller.text)),
      ],
    );
  }
}
