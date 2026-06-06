import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/responsive.dart';
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
          tone: EmptyStateTone.error,
        ),
        data: (items) {
          final expenses =
              items.where((c) => c.kind == CategoryKind.expense).toList();
          final incomes =
              items.where((c) => c.kind == CategoryKind.income).toList();
          return ListView(
            children: [
              const _SectionHeader(title: 'Gider Kategorileri'),
              ..._sectionRows(expenses),
              const _SectionHeader(title: 'Gelir Kategorileri'),
              ..._sectionRows(incomes),
              AppSpacing.fabClearance,
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Kategori Ekle'),
      ),
    );
  }

  List<Widget> _sectionRows(List<Category> items) {
    if (items.isEmpty) {
      return const [
        Padding(
          padding:
              EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          child: Text('Henuz kategori yok'),
        ),
      ];
    }
    return items.map((c) => _CategoryRow(category: c)).toList();
  }

  // Desktop presents the add form as a Dialog; phone as a bottom sheet.
  Future<void> _openAdd(BuildContext context) async {
    if (context.isWide) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: AddCategoryForm(),
            ),
          ),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: const AddCategoryForm(),
      ),
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
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
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
        style: theme.textTheme.labelLarge
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
      leading: _Avatar(category: category, color: color),
      title: Text(category.name, style: theme.textTheme.titleSmall),
      subtitle: category.isSystem ? const _PresetTag() : null,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.category, required this.color});

  final Category category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      child: Icon(categoryIcon(category), color: color, size: 22),
    );
  }
}

class _PresetTag extends StatelessWidget {
  const _PresetTag();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadii.pillR,
        ),
        child: Text(
          'Hazir kategori',
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Shared add-category form. Hosted either in a bottom sheet (phone) or a
/// dialog (desktop); the inner controls are identical in both.
class AddCategoryForm extends ConsumerStatefulWidget {
  const AddCategoryForm({super.key});

  @override
  ConsumerState<AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends ConsumerState<AddCategoryForm> {
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

    return SingleChildScrollView(
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
            decoration: const InputDecoration(labelText: 'Kategori adi'),
          ),
          AppSpacing.gapLg,
          Text('Ikon', style: theme.textTheme.labelLarge),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: selectableIconNames.map((name) {
              return ChoiceChip(
                selected: name == _icon,
                label: Icon(iconForName(name), size: 20),
                onSelected: (_) => setState(() => _icon = name),
              );
            }).toList(),
          ),
          AppSpacing.gapLg,
          Text('Renk', style: theme.textTheme.labelLarge),
          AppSpacing.gapSm,
          _ColorPicker(
            palette: _palette,
            selected: _color,
            onSelected: (hex) => setState(() => _color = hex),
          ),
          if (_error != null) ...[
            AppSpacing.gapMd,
            Text('Hata: $_error',
                style: TextStyle(color: theme.colorScheme.error)),
          ],
          AppSpacing.gapXl,
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

    final error = await ref.read(categoriesControllerProvider).add(_draft);

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

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.palette,
    required this.selected,
    required this.onSelected,
  });

  final List<String> palette;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: palette.map((hex) {
        final isSelected = hex == selected;
        final color = categoryColor(
          Category(id: '', userId: '', name: '', kind: CategoryKind.expense,
              color: hex),
          Theme.of(context).colorScheme.primary,
        );
        return GestureDetector(
          onTap: () => onSelected(hex),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface, width: 2)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
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
