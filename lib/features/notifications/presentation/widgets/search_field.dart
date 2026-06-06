import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notifications_provider.dart';

/// Pill search box bound to [notificationSearchProvider]. Filtering happens
/// reactively in the provider, so this only pushes text changes.
class NotificationSearchField extends ConsumerStatefulWidget {
  const NotificationSearchField({super.key});

  @override
  ConsumerState<NotificationSearchField> createState() =>
      _NotificationSearchFieldState();
}

class _NotificationSearchFieldState
    extends ConsumerState<NotificationSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = _controller.text.isNotEmpty;
    return TextField(
      controller: _controller,
      onChanged: (v) {
        ref.read(notificationSearchProvider.notifier).state = v;
        setState(() {}); // toggle the clear button
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Baslik, metin veya uygulama ara',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  ref.read(notificationSearchProvider.notifier).state = '';
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
