import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/parsed_transaction.dart';

/// AI fallback parser using Groq's free-tier chat completions (OpenAI-compatible
/// API). Invoked ONLY when the device-side regex parser fails AND the account
/// has configured a key. Privacy: only the notification's title + body are
/// sent — never the package, device id, user id, or raw payload. Any failure
/// (timeout, non-200, malformed JSON, CORS on web) degrades to null; the regex
/// result, if any, was already used upstream.
class GroqClient {
  const GroqClient({this.client});

  /// Injectable for tests; defaults to a one-shot client per call.
  final http.Client? client;

  static final Uri _endpoint =
      Uri.parse('https://api.groq.com/openai/v1/chat/completions');
  static const String _model = 'llama-3.1-8b-instant';
  static const Duration _timeout = Duration(seconds: 8);

  static const String _systemPrompt =
      'You extract a single financial transaction from a bank or payment '
      'notification (often Azerbaijani). Reply with ONLY a JSON object: '
      '{"is_transaction": boolean, "amount": number, '
      '"direction": "income" | "expense", "currency": string}. '
      'amount is a positive number. direction is "income" for money received '
      '(medaxil, daxilolma, salary, refund) and "expense" for money spent '
      '(mexaric, odenis, payment, purchase). If the text is not a transaction, '
      'set is_transaction to false.';

  Future<ParsedTransaction?> extract({
    required String apiKey,
    required String? title,
    required String? body,
  }) async {
    final text = '${title ?? ''}\n${body ?? ''}'.trim();
    if (text.isEmpty) return null;
    final httpClient = client ?? http.Client();
    try {
      final res = await httpClient
          .post(
            _endpoint,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'temperature': 0,
              'response_format': {'type': 'json_object'},
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': text},
              ],
            }),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      return _parse(res.body);
    } on Exception {
      return null;
    } finally {
      if (client == null) httpClient.close();
    }
  }

  ParsedTransaction? _parse(String responseBody) {
    final outer = jsonDecode(responseBody) as Map<String, dynamic>;
    final choices = outer['choices'] as List?;
    final content =
        (choices?.firstOrNull as Map?)?['message']?['content'] as String?;
    if (content == null) return null;
    final data = jsonDecode(content) as Map<String, dynamic>;
    if (data['is_transaction'] != true) return null;
    final amount = (data['amount'] as num?)?.toDouble();
    if (amount == null || amount <= 0) return null;
    final direction = (data['direction'] as String?) == 'income'
        ? TxnDirection.income
        : TxnDirection.expense;
    return ParsedTransaction(
      amountMagnitude: amount.abs(),
      direction: direction,
      confidence: 0.8,
      source: ParseSource.ai,
    );
  }
}
