import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/planned_buys_cubit.dart';
import 'package:kitchenowl/enums/buy_status.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/person.dart';
import 'package:kitchenowl/models/planned_buy.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class PlannedBuyAddUpdatePage extends StatefulWidget {
  final Household household;
  final PlannedBuy? plannedBuy;

  const PlannedBuyAddUpdatePage({
    super.key,
    required this.household,
    this.plannedBuy,
  });

  @override
  State<PlannedBuyAddUpdatePage> createState() =>
      _PlannedBuyAddUpdatePageState();
}

class _PlannedBuyAddUpdatePageState extends State<PlannedBuyAddUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _actualPriceController;
  late BuyStatus _status;
  late int _priority;
  DateTime? _targetDate;
  int? _assigneeId;
  late final Future<List<String>> _categories;
  late final Future<List<Person>> _persons;
  bool _isLoading = false;

  bool get isEditing => widget.plannedBuy != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.plannedBuy?.name ?? "");
    _categoryController =
        TextEditingController(text: widget.plannedBuy?.category ?? "");
    _actualPriceController = TextEditingController(
      text: widget.plannedBuy?.actualPrice?.toString() ?? "",
    );
    _status = widget.plannedBuy?.status ?? BuyStatus.idea;
    _priority = widget.plannedBuy?.priority ?? 0;
    _targetDate = widget.plannedBuy?.targetDate?.toLocal();
    _assigneeId = widget.plannedBuy?.assigneeId;
    _categories = ApiService.getInstance()
        .getPlannedBuyCategories(widget.household)
        .then((v) => v ?? const <String>[]);
    _persons = ApiService.getInstance()
        .getPersons(widget.household)
        .then((v) => v ?? const <Person>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _actualPriceController.dispose();
    super.dispose();
  }

  Future<void> _selectTargetDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: AppLocalizations.of(context)!.targetDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (selected != null) {
      setState(() => _targetDate = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final priceText = _actualPriceController.text.trim().replaceAll(",", ".");
    final actualPrice = _status == BuyStatus.acquired && priceText.isNotEmpty
        ? num.tryParse(priceText)
        : null;

    final plannedBuy = PlannedBuy(
      id: widget.plannedBuy?.id,
      name: _nameController.text.trim(),
      status: _status,
      priority: _priority,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      targetDate: _targetDate?.toUtc(),
      actualPrice: actualPrice,
      assigneeId: _assigneeId,
    );

    final cubit = BlocProvider.of<PlannedBuysCubit>(context);
    final res = isEditing
        ? await cubit.updatePlannedBuy(plannedBuy)
        : await cubit.addPlannedBuy(plannedBuy);

    if (!mounted) return;
    if (res) {
      Navigator.of(context).pop(UpdateEnum.updated);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? AppLocalizations.of(context)!.plannedBuyEdit
              : AppLocalizations.of(context)!.plannedBuyAdd,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: _buildFormChildren(context),
        ),
      ),
    );
  }

  List<Widget> _buildFormChildren(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final priorities = [
      loc.priorityLow,
      loc.priorityNormal,
      loc.priorityHigh,
      loc.priorityUrgent,
    ];

    return [
      TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: loc.name),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? loc.name : null,
        autofocus: !isEditing,
      ),
      const SizedBox(height: 16),
      Text(loc.buyStatus, style: Theme.of(context).textTheme.titleSmall),
      Wrap(
        spacing: 8,
        children: [
          for (final status in BuyStatus.values)
            ChoiceChip(
              label: Text(status.toLocalizedString(context)),
              selected: _status == status,
              onSelected: (_) => setState(() => _status = status),
            ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        initialValue: _priority,
        decoration: InputDecoration(labelText: loc.priority),
        items: [
          for (var i = 0; i < priorities.length; i++)
            DropdownMenuItem(value: i, child: Text(priorities[i])),
        ],
        onChanged: (value) => setState(() => _priority = value ?? _priority),
      ),
      Autocomplete<String>(
        initialValue: _categoryController.text.isEmpty
            ? null
            : TextEditingValue(text: _categoryController.text),
        optionsBuilder: (TextEditingValue value) async {
          final categories = await _categories;
          if (value.text.isEmpty) return categories;

          return categories
              .where((e) => e.toLowerCase().contains(value.text.toLowerCase()))
              .toList();
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: loc.category),
          );
        },
        onSelected: (option) => _categoryController.text = option,
      ),
      FutureBuilder<List<Person>>(
        future: _persons,
        builder: (context, snapshot) {
          final persons = snapshot.data ?? const <Person>[];

          return DropdownButtonFormField<int?>(
            initialValue: _assigneeId,
            decoration: InputDecoration(labelText: loc.assignee),
            items: [
              const DropdownMenuItem(value: null, child: Text("\u2014")),
              ...persons.map(
                (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
              ),
            ],
            onChanged: (value) => setState(() => _assigneeId = value),
          );
        },
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.event_rounded),
        title: Text(
          _targetDate != null
              ? MaterialLocalizations.of(context).formatMediumDate(_targetDate!)
              : loc.targetDate,
        ),
        trailing: _targetDate != null
            ? Material(
                type: MaterialType.transparency,
                child: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(() => _targetDate = null),
                ),
              )
            : null,
        onTap: _selectTargetDate,
      ),
      if (_status == BuyStatus.acquired)
        TextFormField(
          controller: _actualPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: loc.actualPrice,
            prefixText: NumberFormat.simpleCurrency(
              locale: widget.household.language ?? Intl.defaultLocale,
            ).currencySymbol,
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
    ];
  }
}
