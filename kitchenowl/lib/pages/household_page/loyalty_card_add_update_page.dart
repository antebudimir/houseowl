import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/loyalty_cards_cubit.dart';
import 'package:houseowl/enums/barcode_format_enum.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/loyalty_card.dart';
import 'package:houseowl/models/household.dart';

import 'loyalty_card_scanner_page.dart';
import 'loyalty_card_page.dart' show scannerSupported;

class LoyaltyCardAddUpdatePage extends StatefulWidget {
  final Household household;
  final LoyaltyCard? card;

  const LoyaltyCardAddUpdatePage({
    super.key,
    required this.household,
    this.card,
  });

  @override
  State<LoyaltyCardAddUpdatePage> createState() =>
      _LoyaltyCardAddUpdatePageState();
}

class _LoyaltyCardAddUpdatePageState extends State<LoyaltyCardAddUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _storeController;
  late final TextEditingController _numberController;
  late final TextEditingController _notesController;

  /// ean13 is the manual-entry default per UX decision; scanning
  /// auto-detects the format instead.
  late BarcodeFormat _format;
  bool _isLoading = false;

  bool get isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    _storeController =
        TextEditingController(text: widget.card?.storeName ?? "");
    _numberController =
        TextEditingController(text: widget.card?.cardNumber ?? "");
    _notesController = TextEditingController(text: widget.card?.notes ?? "");
    _format = widget.card?.format ?? BarcodeFormat.ean13;
  }

  @override
  void dispose() {
    _storeController.dispose();
    _numberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (ctx) => const LoyaltyCardScannerPage(),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _numberController.text = result['number'] ?? _numberController.text;
      final scanned = BarcodeFormat.fromServerName(result['format']);
      if (scanned != null) {
        _format = scanned;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final card = (widget.card ?? const LoyaltyCard()).copyWith(
      storeName: _storeController.text.trim(),
      cardNumber: _numberController.text.trim(),
      barcodeFormat: _format.serverName,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final cubit = BlocProvider.of<LoyaltyCardsCubit>(context);
    final res = isEditing
        ? await cubit.updateLoyaltyCard(card)
        : await cubit.addLoyaltyCard(card);

    if (!mounted) return;
    if (res) {
      Navigator.of(context).pop(UpdateEnum.updated);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? loc.edit : loc.loyaltyCardAdd),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: _buildFormChildren(loc),
        ),
      ),
    );
  }

  List<Widget> _buildFormChildren(AppLocalizations loc) {
    return [
      TextFormField(
        controller: _storeController,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: loc.loyaltyCardStoreName,
        ),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? loc.name : null,
        autofocus: !isEditing,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _numberController,
        decoration: InputDecoration(
          labelText: loc.loyaltyCardNumber,
          suffixIcon: scannerSupported()
              ? IconButton(
                  tooltip: loc.loyaltyCardScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  onPressed: _scan,
                )
              : null,
        ),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? loc.name : null,
        keyboardType: TextInputType.text,
      ),
      DropdownButtonFormField<BarcodeFormat>(
        initialValue: _format,
        decoration: InputDecoration(
          labelText: loc.loyaltyCardFormat,
        ),
        items: BarcodeFormat.values
            .map(
              (f) => DropdownMenuItem(
                value: f,
                child: Text(f.toLocalizedString(context)),
              ),
            )
            .toList(),
        onChanged: (value) =>
            setState(() => _format = value ?? BarcodeFormat.ean13),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _notesController,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: loc.description,
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _isLoading ? null : _save,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(loc.save),
      ),
      if (kIsWeb)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            loc.loyaltyCardWebScanHint,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
    ];
  }
}
