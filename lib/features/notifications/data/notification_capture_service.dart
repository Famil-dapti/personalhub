import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the Android `NotificationArchiverService` (Phase 2B). Every method
/// is a safe no-op on web and non-Android platforms, where capture does not
/// apply and the native channel has no handler.
class NotificationCaptureService {
  static const MethodChannel _channel =
      MethodChannel('personalhub/notifications');

  // Notification capture only exists on Android.
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isPermissionGranted() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isPermissionGranted') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openSettings() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on PlatformException {
      // ignore — nothing the user can do from here
    }
  }

  /// Human-readable model of this phone (e.g. "Xiaomi 22101316G"), used to
  /// attribute captured notifications to a device. Null off-Android.
  Future<String?> deviceModel() async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<String>('getDeviceModel');
    } on PlatformException {
      return null;
    }
  }

  /// Pulls and clears the native capture buffer. Returns decoded payload maps
  /// (newest appended last, matching capture order).
  Future<List<Map<String, dynamic>>> drainPending() async {
    if (!supported) return const [];
    try {
      final raw = await _channel.invokeMethod<String>('drainPending') ?? '[]';
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } on PlatformException {
      return const [];
    }
  }
}
