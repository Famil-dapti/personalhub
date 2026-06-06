import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../providers/settings_provider.dart';

/// App settings. Phase 4: the per-account Groq API key that enables the AI
/// fallback parser (regex runs first; AI only when a key is set). The key is
/// the user's own and syncs to their other devices.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _obscure = true;
  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyAsync = ref.watch(groqApiKeyProvider);

    // Seed the field once from the synced value (without clobbering edits).
    keyAsync.whenData((stored) {
      if (!_seeded) {
        _keyController.text = stored ?? '';
        _seeded = true;
      }
    });

    final hasKey = (keyAsync.valueOrNull ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text('Yapay zeka destekli okuma', style: theme.textTheme.titleMedium),
          AppSpacing.gapSm,
          Text(
            'Banka bildirimleri once cihazda kural tabanli okunur. Taninmayan '
            'bir bicim icin Groq API anahtarinizi girerseniz, yedek olarak '
            'yapay zeka kullanilir. Anahtar girilmezse hicbir veri disari '
            'gonderilmez.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          AppSpacing.gapLg,
          TextField(
            controller: _keyController,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Groq API anahtari',
              hintText: 'gsk_...',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                tooltip: _obscure ? 'Goster' : 'Gizle',
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Kaydet'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _saving || !hasKey ? null : _clear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Temizle'),
              ),
            ],
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Icon(
                hasKey ? Icons.check_circle_outline : Icons.info_outline,
                size: 18,
                color: hasKey
                    ? Colors.green.shade600
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                hasKey ? 'Yapay zeka yedegi acik' : 'Yapay zeka yedegi kapali',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await ref
        .read(settingsControllerProvider)
        .setGroqKey(_keyController.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      AppFeedback.success(context, 'Kaydedildi');
    } else {
      AppFeedback.error(context, 'Kaydedilemedi: $error');
    }
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    final error = await ref.read(settingsControllerProvider).clearGroqKey();
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error == null) _keyController.clear();
    });
    if (error == null) {
      AppFeedback.success(context, 'Anahtar silindi');
    } else {
      AppFeedback.error(context, 'Silinemedi: $error');
    }
  }
}
