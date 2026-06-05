import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category_model.dart';
import '../providers/category_provider.dart';
import '../widgets/category_visuals.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategoriler')),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (items) {
          final expenses =
              items.where((c) => c.kind == CategoryKind.expense).toList();
          final incomes =
              items.where((c) => c.kind == CategoryKind.income).toList();
          return ListView(
            children: [
              _SectionHeader(title: 'Gider Kategorileri'),
              ...expenses.map((c) => _CategoryRow(category: c)),
              _SectionHeader(title: 'Gelir Kategorileri'),
              ...incomes.map((c) => _CategoryRow(category: c)),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Kategori Ekle'),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddCategorySheet(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = categoryColor(category, theme.colorScheme.primary);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(categoryIcon(category), color: color),
      ),
      title: Text(category.name),
      subtitle: category.isSystem ? const Text('Hazir kategori') : null,
      trailing: category.isSystem
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref
                  .read(categoriesProvider.notifier)
                  .removeCategory(category.id),
            ),
    );
  }
}

class _AddCategorySheet extends ConsumerStatefulWidget {
  const _AddCategorySheet();

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  static const List<String> _palette = [
    '#FF7043', '#42A5F5', '#66BB6A', '#AB47BC',
    '#EF5350', '#26A69A', '#FFCA28', '#5C6BC0',
  ];

  final _nameController = TextEditingController();
  CategoryKind _kind = CategoryKind.expense;
  String _icon = selectableIconNames.first;
  String _color = _palette.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yeni Kategori', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<CategoryKind>(
              segments: const [
                ButtonSegment(value: CategoryKind.expense, label: Text('Gider')),
                ButtonSegment(value: CategoryKind.income, label: Text('Gelir')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Kategori adi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Ikon', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: selectableIconNames.map((name) {
                final selected = name == _icon;
                return ChoiceChip(
                  selected: selected,
                  label: Icon(iconForName(name), size: 20),
                  onSelected: (_) => setState(() => _icon = name),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Renk', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _palette.map((hex) {
                final selected = hex == _color;
                final color = categoryColor(
                  Category(
                      id: '', userId: '', name: '', kind: _kind, color: hex),
                  theme.colorScheme.primary,
                );
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: CircleAvatar(
                    backgroundColor: color,
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text('Hata: $_error',
                  style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Kategori adi girin');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final category = Category(
      id: '',
      userId: '',
      name: name,
      kind: _kind,
      icon: _icon,
      color: _color,
    );

    final error =
        await ref.read(categoriesProvider.notifier).addCategory(category);

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop();
  }
}
