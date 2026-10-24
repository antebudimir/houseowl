import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/documents_cubit.dart';
import 'package:houseowl/enums/documents_filter_enum.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/document.dart';

import 'document_page.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<DocumentsCubit>(context);

    return SafeArea(
      child: BlocBuilder<DocumentsCubit, DocumentsCubitState>(
        builder: (context, state) {
          final Widget body;
          if (state is LoadingDocumentsCubitState) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state.documents.isEmpty) {
            body = Center(
              child: Text(
                state is SearchDocumentsCubitState
                    ? AppLocalizations.of(context)!.noResults
                    : AppLocalizations.of(context)!.emptyDocumentList,
                textAlign: TextAlign.center,
              ),
            );
          } else {
            final expiringSoon = state is ListDocumentsCubitState &&
                    state.filter == DocumentsFilter.all
                ? state.expiringSoon
                : const <Document>[];
            final others = state.documents
                .where((d) => !expiringSoon.contains(d))
                .toList();

            body = ListView(
              children: [
                if (expiringSoon.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      AppLocalizations.of(context)!.documentsExpiringSoon,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  ...expiringSoon.map((d) => _DocumentTile(document: d)),
                  const Divider(height: 24),
                ],
                ...others.map((d) => _DocumentTile(document: d)),
              ],
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: KitchenowlPersistentSearchAnchor(
                  onSearch: cubit.search,
                  suggestionsBuilder: (context, controller) => state.documents
                      .map((e) => e.title)
                      .where((e) => e
                          .toLowerCase()
                          .startsWith(controller.text.toLowerCase()))
                      .toSet()
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: DocumentsFilter.values
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f.toLocalizedString(context)),
                            selected: f == cubit.filter,
                            onSelected: (_) => cubit.setFilter(f),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final Document document;

  const _DocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expired = document.isExpired(now);
    final soon =
        !expired && document.expiresWithin(const Duration(days: 30), now);

    return ListTile(
      title: Text(
        document.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: document.notes?.isNotEmpty ?? false
          ? Text(
              document.notes!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      leading: const CircleAvatar(child: Icon(Icons.folder_outlined)),
      trailing: expired || soon ? _ExpiryBadge(expired: expired) : null,
      onTap: () => Navigator.of(context).push<UpdateEnum>(
        MaterialPageRoute(
          builder: (ctx) => DocumentPage(document: document),
        ),
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final bool expired;

  const _ExpiryBadge({required this.expired});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = expired ? theme.colorScheme.error : Colors.amber.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        expired
            ? AppLocalizations.of(context)!.documentsExpired
            : AppLocalizations.of(context)!.documentsExpiresSoon,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
