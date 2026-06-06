import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/responsive.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../models/transaction_prefill.dart';
import '../providers/category_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/category_visuals.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.prefill});

  /// Seed values when opened from a notification (null = manual add).
  final TransactionPrefill? prefill;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  CategoryKind _kind = CategoryKind.expense;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  bool get _isDraftCommit => widget.prefill?.existingTransactionId != null;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p == null) return;
    if (p.amountMagnitude != null) {
      _amountController.text = p.amountMagnitude!.toStringAsFixed(2);
    }
    if (p.kind != null) _kind = p.kind!;
    if (p.description != null && p.description!.isNotEmpty) {
      _descriptionController.text = p.description!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final options = categories.where((c) => c.kind == _kind).toList();
    // Selected segment tints the amount: expense red / income green.
    final accent = _kind == CategoryKind.expense
        ? theme.colorScheme.error
        : context.money.income;

    final form = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SegmentedButton<CategoryKind>(
            segments: const [
              ButtonSegment(
                value: CategoryKind.expense,
                label: Text('Gider'),
                icon: Icon(Icons.north_east),
              ),
              ButtonSegment(
                value: CategoryKind.income,
                label: Text('Gelir'),
                icon: Icon(Icons.south_west),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _categoryId = null; // reset: categories differ per kind
            }),
          ),
          AppSpacing.gapXl,
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: theme.textTheme.headlineSmall?.copyWith(
              color: accent,
              fontFeatures: kTabularFigures,
            ),
            decoration: InputDecoration(
              labelText: 'Tutar',
              suffixText: 'AZN',
              suffixStyle: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            validator: _validateAmount,
          ),
          AppSpacing.gapXl,
          Text('Kategori', style: theme.textTheme.labelLarge),
          AppSpacing.gapSm,
          _CategoryPicker(
            options: options,
            selectedId: _categoryId,
            onSelected: (id) => setState(() => _categoryId = id),
          ),
          AppSpacing.gapXl,
          TextFormField(
            controller: _descriptionController,
            decoration:
                const InputDecoration(labelText: 'Aciklama (istege bagli)'),
            maxLines: 2,
          ),
          AppSpacing.gapXl,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Tarih'),
            subtitle: Text(formatDate(_date)),
            trailing: const Icon(Icons.edit),
            onTap: _pickDate,
          ),
          if (_error != null) ...[
            AppSpacing.gapMd,
            Text('Hata: $_error',
                style: TextStyle(color: theme.colorScheme.error)),
          ],
          AppSpacing.gapXxl,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      // Constrain the form on desktop so it is not full-bleed.
      body: context.isWide
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: form,
              ),
            )
          : form,
    );
  }

  String? _validateAmount(String? value) {
    final parsed = _parseAmount(value);
    if (parsed == null || parsed <= 0) return 'Gecerli bir tutar girin';
    return null;
  }

  double? _parseAmount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.trim().replaceAll(',', '.'));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = 'Bir kategori secin');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final magnitude = _parseAmount(_amountController.text)!;
    final signed = _kind == CategoryKind.expense ? -magnitude : magnitude;
    final description = _descriptionController.text.trim();
    final prefill = widget.prefill;

    final transaction = Transaction(
      id: prefill?.existingTransactionId ?? '',
      userId: '',
      amount: signed,
      createdAt: _date,
      categoryId: _categoryId,
      description: description.isEmpty ? null : description,
      source: prefill?.notificationId != null ? 'notification' : 'manual',
      notificationId: prefill?.notificationId,
    );

    final controller = ref.read(transactionsControllerProvider);
    // Committing a pending draft upserts the same row (pending -> false);
    // a fresh add inserts a new row.
    final error = _isDraftCommit
        ? await controller.update(transaction)
        : await controller.add(transaction);

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    AppFeedback.success(context, _isDraftCommit ? 'Islem onaylandi' : 'Islem eklendi');
    context.pop();
  }

  String get _appBarTitle {
    if (_isDraftCommit) return 'Taslagi Onayla';
    if (widget.prefill?.notificationId != null) return 'Cuzdana Ekle';
    return 'Islem Ekle';
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> options;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (options.isEmpty) {
      return const Text('Bu tur icin kategori yok');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((c) {
        final selected = c.id == selectedId;
        final color = categoryColor(c, theme.colorScheme.primary);
        return ChoiceChip(
          selected: selected,
          avatar: Icon(categoryIcon(c), size: 18, color: color),
          label: Text(c.name),
          onSelected: (_) => onSelected(c.id),
        );
      }).toList(),
    );
  }
}
