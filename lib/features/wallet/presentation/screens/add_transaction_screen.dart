import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/category_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/category_visuals.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(title: const Text('Islem Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<CategoryKind>(
              segments: const [
                ButtonSegment(
                  value: CategoryKind.expense,
                  label: Text('Gider'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: CategoryKind.income,
                  label: Text('Gelir'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                _categoryId = null; // reset: categories differ per kind
              }),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Tutar',
                suffixText: 'AZN',
                border: OutlineInputBorder(),
              ),
              validator: _validateAmount,
            ),
            const SizedBox(height: 20),
            Text('Kategori', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _CategoryPicker(
              options: options,
              selectedId: _categoryId,
              onSelected: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Aciklama (istege bagli)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Tarih'),
              subtitle: Text(formatDate(_date)),
              trailing: const Icon(Icons.edit),
              onTap: _pickDate,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text('Hata: $_error',
                  style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
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
          ],
        ),
      ),
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

    final transaction = Transaction(
      id: '',
      userId: '',
      amount: signed,
      createdAt: _date,
      categoryId: _categoryId,
      description: description.isEmpty ? null : description,
    );

    final error = await ref
        .read(transactionsProvider.notifier)
        .addTransaction(transaction);

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    context.pop();
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
