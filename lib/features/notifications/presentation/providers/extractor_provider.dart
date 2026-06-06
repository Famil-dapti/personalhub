import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/groq_client.dart';
import '../../data/models/notification_model.dart';
import '../../domain/notification_parser.dart';
import '../../domain/parsed_transaction.dart';

final groqClientProvider = Provider<GroqClient>((ref) => const GroqClient());

final transactionExtractorProvider =
    Provider<TransactionExtractor>((ref) => TransactionExtractor(ref));

/// Hybrid notification -> transaction extraction. Runs the free, offline,
/// device-side regex parser first; only if that fails AND the account has a
/// Groq key configured does it fall back to the AI client. Called lazily (on
/// the "Cuzdana ekle" tap), never per-notification at ingest.
class TransactionExtractor {
  TransactionExtractor(this._ref);

  final Ref _ref;

  Future<ParsedTransaction?> extract(NotificationItem n) async {
    final viaRegex = parseNotification(
      appPackage: n.appPackage,
      title: n.title,
      body: n.body,
    );
    if (viaRegex != null) return viaRegex;

    final key = _ref.read(groqApiKeyProvider).valueOrNull;
    if (key == null || key.isEmpty) return null;
    return _ref.read(groqClientProvider).extract(
          apiKey: key,
          title: n.title,
          body: n.body,
        );
  }
}
