import 'dart:io' show Platform;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/loyalty_cards_cubit.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/loyalty_card.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // A card-like, till-friendly layout: the barcode fills most of the
          // width so it stays scannable at arm's length. 2D matrix codes are
          // kept square; 1D codes stretch to the available width.
          final cardWidth =
              (constraints.maxWidth - 32).clamp(0.0, 560.0).toDouble();
          final barcodeWidth =
              (cardWidth - 64).clamp(0.0, 520.0).toDouble();
          final matrixSide = barcodeWidth.clamp(0.0, 360.0).toDouble();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.card.storeName,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          if (format != null &&
                              widget.card.cardNumber.isNotEmpty)
                            Center(
                              child: Container(
                                // A barcode must always be black on white,
                                // regardless of the app theme, so store
                                // scanners get full contrast. The white
                                // container also provides the quiet zone.
                                color: Colors.white,
                                padding: const EdgeInsets.all(12),
                                child: BarcodeWidget(
                                  barcode: format.toBarcode(),
                                  data: widget.card.cardNumber,
                                  color: Colors.black,
                                  backgroundColor: Colors.white,
                                  drawText: false,
                                  width: format.isMatrix
                                      ? matrixSide
                                      : barcodeWidth,
                                  height: format.isMatrix ? matrixSide : 160,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 72,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          const SizedBox(height: 16),
                          SelectableText(
                            widget.card.cardNumber,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          if (format != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              format.toLocalizedString(context),
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.card.notes?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: KitchenOwlMarkdownBody(data: widget.card.notes!),
                ),
            ],
          );
        },
      ),
    );
  }
}
