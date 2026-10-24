import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/documents_cubit.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/document.dart';
import 'package:houseowl/helpers/share.dart';
import 'package:houseowl/services/api/api_service.dart';

import '../photo_view_page.dart';
import 'document_add_update_page.dart';

class DocumentPage extends StatefulWidget {
  final Document document;

  const DocumentPage({super.key, required this.document});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  bool _downloadingFile = false;

  bool _isImageFile(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// Derives a user-friendly download name from the document title, keeping
  /// the extension of the originally uploaded (server-stored) filename.
  String _downloadName() {
    final filename = widget.document.filename;
    if (filename == null) return widget.document.title;
    final ext = filename.contains('.') ? filename.split('.').last : null;
    final base = widget.document.title.replaceAll(RegExp(r'[/\\]'), '-').trim();
    if (base.isEmpty) return filename;
    return ext == null ? base : '$base.$ext';
  }

  void _openImageFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewPage(
          imageProvider: getImageProvider(context, widget.document.filename!),
          title: widget.document.title,
        ),
      ),
    );
  }

  Future<void> _downloadFile() async {
    final filename = widget.document.filename;
    if (filename == null || _downloadingFile) return;
    setState(() => _downloadingFile = true);
    try {
      final bytes = await ApiService.getInstance().downloadBytes(filename);
      if (!mounted) return;
      if (bytes == null) {
        showSnackbar(
          context: context,
          content: Text(AppLocalizations.of(context)!.error),
        );
        return;
      }
      await Share.shareFile(context, bytes, _downloadName());
    } finally {
      if (mounted) setState(() => _downloadingFile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
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
                      document: widget.document,
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
                    loc.documentDeleteConfirmation(widget.document.title),
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
                  .deleteDocument(widget.document);
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
          if (widget.document.expiresAt != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: Text(loc.expiryDate),
              subtitle: Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(widget.document.expiresAt!),
              ),
              trailing: widget.document.isExpired()
                  ? Text(
                      loc.documentsExpired,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : null,
            ),
          if (widget.document.contact != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(loc.person),
              subtitle: Text(widget.document.contact!.name),
            ),
          if (_isImageFile(widget.document.filename!)) ...[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openImageFullscreen,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.document.fileBlurHash != null)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: 440,
                            height: 220,
                            child: Image(
                              image: BlurHashImage(
                                widget.document.fileBlurHash!,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Image(
                        image: getImageProvider(
                          context,
                          widget.document.filename!,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            widget.document.fileBlurHash != null
                                ? const SizedBox.shrink()
                                : const Center(
                                    child: Icon(Icons.broken_image_rounded),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (widget.document.filename != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _downloadingFile
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              title: Text(loc.documentsFile),
              subtitle: Text(widget.document.filename!),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              enabled: !_downloadingFile,
              onTap: _downloadFile,
            ),
          if (widget.document.notes?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: KitchenOwlMarkdownBody(data: widget.document.notes!),
            ),
        ],
      ),
    );
  }
}
