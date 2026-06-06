import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/media_models.dart';
import '../providers/media_providers.dart';
import '../widgets/format_bytes.dart';

/// Batch-delete confirmation: shows everything queued for deletion, the total
/// freed-space estimate, and runs the OS-confirmed delete on demand.
class MediaDeleteConfirmScreen extends ConsumerStatefulWidget {
  const MediaDeleteConfirmScreen({super.key});

  @override
  ConsumerState<MediaDeleteConfirmScreen> createState() =>
      _MediaDeleteConfirmScreenState();
}

class _MediaDeleteConfirmScreenState
    extends ConsumerState<MediaDeleteConfirmScreen> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(mediaPendingDeletesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Silinecekler')),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Bir sorun olustu',
          message: e.toString(),
        ),
        data: (assets) =>
            assets.isEmpty ? const _NothingPending() : _content(assets),
      ),
    );
  }

  Widget _content(List<MediaAsset> assets) {
    final freed = assets.fold<int>(0, (sum, a) => sum + a.sizeBytes);
    return Column(
      children: [
        _Summary(count: assets.length, freed: freed),
        Expanded(child: _ThumbGrid(assets: assets)),
        _DeleteBar(
          count: assets.length,
          running: _running,
          onPressed: () => _confirmAndDelete(assets.length, freed),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(int count, int freed) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme onayi'),
        content: Text('$count oge silinecek, ~${formatBytes(freed)} yer '
            'bosalacak. Android sistem onayi da istenecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Vazgec')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _runDelete();
  }

  Future<void> _runDelete() async {
    setState(() => _running = true);
    final result =
        await ref.read(mediaCleanerControllerProvider).executeDeletes();
    if (!mounted) return;
    setState(() => _running = false);
    _reportResult(result);
    if (context.mounted) context.pop();
  }

  void _reportResult(MediaDeleteResult result) {
    if (result.error != null) {
      AppFeedback.error(context, 'Silinemedi. Tekrar deneyin.');
    } else if (result.deletedCount == 0) {
      AppFeedback.error(context, 'Iptal edildi');
    } else {
      AppFeedback.success(context,
          '${result.deletedCount} oge silindi, ${formatBytes(result.freedBytes)} bosaldi');
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.count, required this.freed});

  final int count;
  final int freed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.delete_sweep, color: theme.colorScheme.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$count oge - tahmini ${formatBytes(freed)} bosalacak',
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbGrid extends ConsumerWidget {
  const _ThumbGrid({required this.assets});

  final List<MediaAsset> assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: assets.length,
      itemBuilder: (context, i) => _Thumb(asset: assets[i]),
    );
  }
}

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: FutureBuilder<Uint8List?>(
        future: ref.read(mediaScannerProvider).thumbnail(asset.assetId),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null) {
            return Container(
              color: scheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: snapshot.connectionState == ConnectionState.done
                  ? Icon(Icons.broken_image_outlined, color: scheme.outline)
                  : const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
        },
      ),
    );
  }
}

class _DeleteBar extends StatelessWidget {
  const _DeleteBar({
    required this.count,
    required this.running,
    required this.onPressed,
  });

  final int count;
  final bool running;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: running ? null : onPressed,
            icon: running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_forever),
            label: Text(running ? 'Siliniyor...' : 'Sec ve sil ($count)'),
          ),
        ),
      ),
    );
  }
}

class _NothingPending extends StatelessWidget {
  const _NothingPending();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyState(
        icon: Icons.delete_outline,
        title: 'Silinecek oge yok',
        message: 'Kart yiginindan sola kaydirdigin medya burada toplanir.',
      ),
    );
  }
}
