import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../data/models/notification_model.dart';

/// "Ham veri" block: a monospace summary of the captured payload (package,
/// posted time, transaction flag) plus the pretty-printed raw JSON if present.
class RawPayloadBlock extends StatelessWidget {
  const RawPayloadBlock({super.key, required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final posted = item.postedAt;
    final lines = <String>[
      'package: ${item.appPackage ?? '-'}',
      'posted:  ${posted == null ? '-' : '${formatDate(posted)} ${formatTime(posted)}'}',
      'is_transaction: ${item.isTransaction}',
    ];

    final pretty = _prettyJson(item.rawJson);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ham veri', style: theme.textTheme.titleSmall),
        AppSpacing.gapSm,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: SelectableText(
            [lines.join('\n'), ?pretty].join('\n\n'),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String? _prettyJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } on FormatException {
      return raw; // not JSON; show as-is
    }
  }
}
