import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/documents_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/document.dart';

import 'document_add_update_page.dart';

class DocumentPage extends StatelessWidget {
  final Document document;

  const DocumentPage({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: [
          IconButton(
            tooltip: loc.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final res = await Navigator.of(context).push<UpdateEnum>(
                MaterialPageRoute(
                  builder: (ctx) => BlocProvider.value(
                    value: BlocProvider.of<DocumentsCubit>(context),
                    child: DocumentAddUpdatePage(
                      household:
                          BlocProvider.of<DocumentsCubit>(context).household,
                      document: document,
                    ),
                  ),
                ),
              );
              if (res == UpdateEnum.updated && context.mounted) {
                Navigator.of(context).pop(UpdateEnum.updated);
              }
            },
          ),
          IconButton(
            tooltip: loc.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(loc.delete),
                  content: Text(
                    loc.documentDeleteConfirmation(document.title),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(loc.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(loc.delete),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              final res = await BlocProvider.of<DocumentsCubit>(context)
                  .deleteDocument(document);
              if (!context.mounted) return;
              if (res) {
                Navigator.of(context).pop(UpdateEnum.updated);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.error)),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (document.expiresAt != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: Text(loc.expiryDate),
              subtitle: Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(document.expiresAt!),
              ),
              trailing: document.isExpired()
                  ? Text(
                      loc.documentsExpired,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : null,
            ),
          if (document.contact != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(loc.person),
              subtitle: Text(document.contact!.name),
            ),
          if (document.filename != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file_rounded),
              title: Text(loc.documentsFile),
              subtitle: Text(document.filename!),
            ),
          if (document.notes?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: KitchenOwlMarkdownBody(data: document.notes!),
            ),
        ],
      ),
    );
  }
}
