import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/notification_model.dart';
import '../../data/notification_capture_service.dart';
import 'notifications_provider.dart';

final notificationCaptureServiceProvider =
    Provider<NotificationCaptureService>((ref) => NotificationCaptureService());

// Persisted key for this install's stable device id.
const String _kDeviceIdKey = 'device_id';

/// Stable identity of the phone running this install, used to attribute each
/// captured notification (two phones share one account).
class DeviceIdentity {
  const DeviceIdentity({required this.id, required this.name});
  final String id;
  final String name;
}

/// Loads (and on first run generates + persists) this device's id, and reads a
/// human-readable model name (from the Android side). Cached by Riverpod.
final deviceIdentityProvider = FutureProvider<DeviceIdentity>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString(_kDeviceIdKey);
  if (id == null) {
    id = const Uuid().v4();
    await prefs.setString(_kDeviceIdKey, id);
  }
  final service = ref.read(notificationCaptureServiceProvider);
  final name = await _resolveDeviceName(service);
  return DeviceIdentity(id: id, name: name);
});

Future<String> _resolveDeviceName(NotificationCaptureService service) async {
  if (kIsWeb) return 'Web';
  if (defaultTargetPlatform == TargetPlatform.android) {
    final model = await service.deviceModel();
    return (model == null || model.isEmpty) ? 'Android' : model;
  }
  return defaultTargetPlatform.name;
}

// True only on Android (where capture exists). Drives permission gating.
final captureSupportedProvider = Provider<bool>(
    (ref) => ref.watch(notificationCaptureServiceProvider).supported);

// Whether the user has granted notification-listener access. Refresh after
// returning from the system settings screen by invalidating this provider.
final notificationPermissionProvider = FutureProvider<bool>((ref) {
  return ref.watch(notificationCaptureServiceProvider).isPermissionGranted();
});

final notificationCaptureControllerProvider =
    Provider<NotificationCaptureController>(
        (ref) => NotificationCaptureController(ref));

/// Drains the native capture buffer and feeds each notification through the
/// normal ingest path (Drift + outbox + sync). Called on app open / resume.
class NotificationCaptureController {
  NotificationCaptureController(this._ref);

  final Ref _ref;

  Future<int> drainAndIngest() async {
    final service = _ref.read(notificationCaptureServiceProvider);
    if (!service.supported) return 0;

    final pending = await service.drainPending();
    if (pending.isEmpty) return 0;

    final device = await _ref.read(deviceIdentityProvider.future);
    final controller = _ref.read(notificationsControllerProvider);
    var ingested = 0;
    for (final m in pending) {
      final item = _toItem(m, device);
      final error = await controller.ingest(item);
      if (error == null) ingested++;
    }
    return ingested;
  }

  NotificationItem _toItem(Map<String, dynamic> m, DeviceIdentity device) {
    final postedMs = m['posted_at'];
    final posted = postedMs is int
        ? DateTime.fromMillisecondsSinceEpoch(postedMs)
        : null;
    final title = m['title'] as String?;
    final body = m['body'] as String?;
    return NotificationItem(
      id: '', // ingest assigns a uuid
      userId: '', // ingest binds the real signed-in user
      createdAt: DateTime.now(),
      appPackage: m['app_package'] as String?,
      appName: m['app_name'] as String?,
      title: title,
      body: body,
      postedAt: posted,
      isTransaction: looksLikeTransaction(title, body),
      rawJson: jsonEncode(m),
      deviceId: device.id,
      deviceName: device.name,
    );
  }
}

// Rough first-pass payment detector (refined in Phase 4). Flags a notification
// as a transaction when it pairs a money amount with a currency or banking word.
bool looksLikeTransaction(String? title, String? body) {
  final text = '${title ?? ''} ${body ?? ''}'.toLowerCase().trim();
  if (text.isEmpty) return false;

  final hasAmount = RegExp(r'\d+[.,]\d{2}').hasMatch(text) ||
      RegExp(r'\d{2,}').hasMatch(text);
  const currency = ['azn', '₼', 'manat', 'usd', r'$', 'eur', '€'];
  const keywords = [
    'odeme', 'odendi', 'kart', 'hesab', 'transfer', 'balans', 'mebleg',
    'cixaris', 'medaxil', 'payment', 'paid', 'debit', 'credit',
  ];
  final hasCurrency = currency.any(text.contains);
  final hasKeyword = keywords.any(text.contains);
  return hasAmount && (hasCurrency || hasKeyword);
}
