import 'package:core_share/core_share.dart';
import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:list_export/list_export.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../domain/use_cases/build_shopping_export.dart';
import '../../i18n/strings.g.dart';
import '../common/shopping_list_l10n.dart';

/// Hoja para exportar la lista (completa o filtrada) por WhatsApp, como
/// texto o como archivo Markdown. Es parte de la pantalla de la lista.
class ShoppingExportSheet extends StatefulWidget {
  const ShoppingExportSheet({
    super.key,
    required this.allEntries,
    required this.filteredEntries,
    required this.isFiltered,
    required this.initialGrouping,
    required this.buildExport,
    required this.shareService,
    required this.now,
  });

  final List<ShoppingListEntry> allEntries;
  final List<ShoppingListEntry> filteredEntries;

  /// Si hay filtros activos: solo entonces se ofrece exportar lo filtrado.
  final bool isFiltered;
  final ShoppingGrouping initialGrouping;
  final BuildShoppingExport buildExport;
  final ShareService shareService;
  final DateTime now;

  @override
  State<ShoppingExportSheet> createState() => _ShoppingExportSheetState();
}

class _ShoppingExportSheetState extends State<ShoppingExportSheet> {
  late bool _filtered = widget.isFiltered;
  late ShoppingGrouping _grouping = widget.initialGrouping;

  ExportDocument get _document => widget.buildExport(
        _filtered ? widget.filteredEntries : widget.allEntries,
        _grouping,
        exportTexts(widget.now),
      );

  Future<void> _run(Future<String?> Function(ExportDocument document) action) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    String? message;
    try {
      message = await action(_document);
    } on Object {
      message = commonStrings.common.unexpectedError;
    }
    navigator.pop();
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  ShareFile _markdownFile(ExportDocument document) => ShareFile.markdown(
        baseName: shoppingListStrings.shoppingList.export.fileName,
        content: const MarkdownFormatter().format(document),
      );

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$es t = shoppingListStrings.shoppingList;
    final ShareService share = widget.shareService;
    final bool empty = _document.isEmpty;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(t.export.title, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (widget.isFiltered)
              AppChoiceSelector<bool>(
                label: t.export.scope,
                options: <AppChoice<bool>>[
                  AppChoice<bool>(value: false, label: t.export.scopeAll),
                  AppChoice<bool>(value: true, label: t.export.scopeFiltered),
                ],
                selected: _filtered,
                onChanged: (bool filtered) => setState(() => _filtered = filtered),
              ),
            AppChoiceSelector<ShoppingGrouping>(
              label: t.export.grouping,
              options: <AppChoice<ShoppingGrouping>>[
                AppChoice<ShoppingGrouping>(value: ShoppingGrouping.category, label: t.list.groupByCategory),
                AppChoice<ShoppingGrouping>(value: ShoppingGrouping.urgency, label: t.list.groupByUrgency),
              ],
              selected: _grouping,
              onChanged: (ShoppingGrouping grouping) => setState(() => _grouping = grouping),
            ),
            if (empty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(t.export.nothing),
              ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: t.export.whatsapp,
              icon: Icons.chat_outlined,
              expand: true,
              onPressed: empty
                  ? null
                  : () => _run((ExportDocument document) async =>
                      await share.openWhatsApp(const WhatsAppFormatter().format(document))
                          ? null
                          : t.export.whatsappMissing),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: t.export.shareText,
              icon: Icons.share_outlined,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: empty
                  ? null
                  : () => _run((ExportDocument document) async {
                        await share.shareText(const WhatsAppFormatter().format(document), subject: document.title);
                        return null;
                      }),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: t.export.shareFile,
              icon: Icons.description_outlined,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: empty
                  ? null
                  : () => _run((ExportDocument document) async {
                        await share.shareFile(_markdownFile(document), subject: document.title);
                        return null;
                      }),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: t.export.saveFile,
              icon: Icons.save_alt,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: empty
                  ? null
                  : () => _run((ExportDocument document) async =>
                      await share.saveFile(_markdownFile(document)) == SaveFileResult.saved ? t.export.saved : null),
            ),
          ],
        ),
      ),
    );
  }
}
