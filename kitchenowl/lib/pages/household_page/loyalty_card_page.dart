import 'dart:io' show Platform;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/loyalty_cards_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'loyalty_card_add_update_page.dart';

/// Whether the camera scan entry point should be offered. mobile_scanner
/// supports iOS and Android; on other platforms the manual entry form is
/// the only input. kIsWeb is checked first because dart:io is stubbed on
/// the web build.
bool scannerSupported() => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class LoyaltyCardPage extends StatefulWidget {
  final LoyaltyCard card;

  const LoyaltyCardPage({super.key, required this.card});

  @override
  State<LoyaltyCardPage> createState() => _LoyaltyCardPageState();
}

class _LoyaltyCardPageState extends State<LoyaltyCardPage> {
  @override
  void initState() {
    super.initState();
    // Keep the screen on so the barcode stays scannable at a till.
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final format = widget.card.format;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.storeName),
        actions: [
          IconButton(
            tooltip: loc.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final res = await Navigator.of(context).push<UpdateEnum>(
                MaterialPageRoute(
                  builder: (ctx) => BlocProvider.value(
                    value: BlocProvider.of<LoyaltyCardsCubit>(context),
                    child: LoyaltyCardAddUpdatePage(
                      household:
                          BlocProvider.of<LoyaltyCardsCubit>(context).household,
                      card: widget.card,
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
                    loc.loyaltyCardDeleteConfirmation(widget.card.storeName),
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
              final res = await BlocProvider.of<LoyaltyCardsCubit>(context)
                  .deleteLoyaltyCard(widget.card);
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
          if (format != null && widget.card.cardNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: BarcodeWidget(
                  barcode: format.toBarcode(),
                  data: widget.card.cardNumber,
                  width: 300,
                  height: 120,
                  // 2D codes would be distorted by the fixed height.
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          SelectableText(
            widget.card.cardNumber,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (format != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.qr_code_rounded),
              title: Text(loc.loyaltyCardFormat),
              subtitle: Text(format.toLocalizedString(context)),
            ),
          if (widget.card.notes?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: KitchenOwlMarkdownBody(data: widget.card.notes!),
            ),
        ],
      ),
    );
  }
}
