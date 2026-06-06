import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton.dart';
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
        loading: () => const _CategoriesLoading(),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Bir sorun olustu',
          message: e.toString(),
        ),
        data: (items) {
          final expenses =
              items.where((c) => c.kind == CategoryKind.expense).toList();
          final incomes =
              items.where((c) => c.kind == CategoryKind.income).toList();
          return ListView(
            children: [
              _SectionHeader(title: 'Gider Kategorileri'),
              ..._sectionRows(expenses),
              _SectionHeader(title: 'Gelir Kategorileri'),
              ..._sectionRows(incomes),
              AppSpacing.fabClearance,
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

  List<Widget> _sectionRows(List<Category> items) {
    if (items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          child: Text('Henuz kategori yok'),
        ),
      ];
    }
    return items.map((c) => _CategoryRow(category: c)).toList();
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddCategorySheet(),
    );
  }
}

class _CategoriesLoading extends StatelessWidget {
  const _CategoriesLoading();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
            child: SkeletonBox(width: 160, height: 14),
          ),
          SkeletonListTile(),
          SkeletonListTile(),
          SkeletonListTile(),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
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
              tooltip: 'Sil',
              onPressed: () => _confirmDelete(context, ref),
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategoriyi sil'),
        content: Text('"${category.name}" kategorisi silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error =
        await ref.read(categoriesControllerProvider).remove(category.id);
    if (!context.mounted) return;
    if (error == null) {
      AppFeedback.success(context, 'Kategori silindi');
    } else {
      AppFeedback.error(context, 'Silinemedi: $error');
    }
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
  void initState() {
    super.initState();
    // Live-update the preview chip as the user types the name.
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Category get _draft => Category(
        id: '',
        userId: '',
        name: _nameController.text.trim(),
        kind: _kind,
        icon: _icon,
        color: _color,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, bottomInset + AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yeni Kategori', style: theme.textTheme.titleLarge),
            AppSpacing.gapLg,
            Center(child: _CategoryPreview(category: _draft)),
            AppSpacing.gapLg,
            SegmentedButton<CategoryKind>(
              segments: const [
                ButtonSegment(value: CategoryKind.expense, label: Text('Gider')),
                ButtonSegment(value: CategoryKind.income, label: Text('Gelir')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            AppSpacing.gapLg,
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Kategori adi',
                border: OutlineInputBorder(),
              ),
            ),
            AppSpacing.gapLg,
            Text('Ikon', style: theme.textTheme.labelLarge),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: selectableIconNames.map((name) {
                final selected = name == _icon;
                return ChoiceChip(
                  selected: selected,
                  label: Icon(iconForName(name), size: 20),
                  onSelected: (_) => setState(() => _icon = name),
                );
              }).toList(),
            ),
            AppSpacing.gapLg,
            Text('Renk', style: theme.textTheme.labelLarge),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
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
              AppSpacing.gapMd,
              Text('Hata: $_error',
                  style: TextStyle(color: theme.colorScheme.error)),
            ],
            AppSpacing.gapXl,
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

    final error =
        await ref.read(categoriesControllerProvider).add(_draft);

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    AppFeedback.success(context, 'Kategori eklendi');
    Navigator.of(context).pop();
  }
}

/// Live preview of the category being created (icon + color + name).
class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = categoryColor(category, theme.colorScheme.primary);
    final name = category.name.isEmpty ? 'Onizleme' : category.name;
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(categoryIcon(category), color: color, size: 18),
      ),
      label: Text(name),
    );
  }
}
