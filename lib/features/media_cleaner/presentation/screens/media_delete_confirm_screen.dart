import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
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
      appBar: AppBar(title: const Text('Silme onayi')),
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
        _Warning(count: assets.length, freed: freed),
        Expanded(child: _ThumbGrid(assets: assets)),
        _DeleteBar(
          count: assets.length,
          freed: freed,
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
        content: Text('$count dosya kalici olarak silinecek, '
            '~${formatBytes(freed)} yer bosalacak. Android sistem onayi da '
            'istenecek. Geri alinamaz.'),
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
          '${result.deletedCount} dosya silindi, ~${formatBytes(result.freedBytes)} bosaldi');
    }
  }
}

// Danger banner (errorContainer): irreversible-delete warning.
class _Warning extends StatelessWidget {
  const _Warning({required this.count, required this.freed});

  final int count;
  final int freed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Card(
        color: scheme.errorContainer,
        elevation: AppElevation.elev0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '$count dosya kalici olarak silinecek '
                  '(~${formatBytes(freed)}). Geri alinamaz.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
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

  // Reverting the delete decision drops the asset from the pending queue.
  void _unmark(WidgetRef ref) =>
      ref.read(mediaCleanerControllerProvider).undo(asset);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ThumbImage(asset: asset),
          Positioned(
            top: 2,
            right: 2,
            child: _UnmarkButton(onTap: () => _unmark(ref)),
          ),
          if (asset.isVideo)
            const Positioned(
              top: 4,
              left: 4,
              child: Icon(Icons.videocam, size: 16, color: Colors.white),
            ),
          Positioned(
            left: 4,
            bottom: 4,
            child: _SizeChip(label: formatBytes(asset.sizeBytes)),
          ),
        ],
      ),
    );
  }
}

class _ThumbImage extends ConsumerWidget {
  const _ThumbImage({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<Uint8List?>(
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
    );
  }
}

class _UnmarkButton extends StatelessWidget {
  const _UnmarkButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.xs),
          child: Icon(Icons.close, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFeatures: kTabularFigures)),
    );
  }
}

class _DeleteBar extends StatelessWidget {
  const _DeleteBar({
    required this.count,
    required this.freed,
    required this.running,
    required this.onPressed,
  });

  final int count;
  final int freed;
  final bool running;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: running ? null : onPressed,
            icon: running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_forever),
            label: Text(running
                ? 'Siliniyor...'
                : '$count dosyayi sil  .  ${formatBytes(freed)}'),
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
