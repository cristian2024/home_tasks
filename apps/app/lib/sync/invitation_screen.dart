import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_display/qr_display.dart';

import '../i18n/strings.g.dart';
import 'invitation_cubit.dart';

/// Código QR del hogar, para que otro dispositivo se una escaneándolo.
class InvitationScreen extends StatelessWidget {
  const InvitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$invitation$es t = appStrings.app.sync.invitation;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocBuilder<InvitationCubit, String?>(
        builder: (BuildContext context, String? code) => code == null
            ? AppStatusView(icon: Icons.qr_code_2, title: t.loading)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: AppQrCode(data: code, semanticLabel: t.qrLabel),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.message, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  AppBadge(label: t.warning, tone: AppBadgeTone.warning, icon: Icons.lock_outline),
                ],
              ),
      ),
    );
  }
}
