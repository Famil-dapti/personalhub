/// A single archived Android notification. Captured on the phone (Phase 2B
/// native listener) and browsed read-only everywhere else. Immutable: rows are
/// never edited or deleted once stored.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.appPackage,
    this.appName,
    this.title,
    this.body,
    this.postedAt,
    this.isTransaction = false,
    this.rawJson,
    this.deviceId,
    this.deviceName,
  });

  final String id;
  final String userId;
  final DateTime createdAt; // server insert time (delta-pull watermark)
  final String? appPackage;
  final String? appName;
  final String? title;
  final String? body;
  final DateTime? postedAt; // when Android posted it (preferred display time)
  final bool isTransaction; // heuristic: looks like a payment notification
  final String? rawJson; // full payload, encoded JSON string
  final String? deviceId; // stable id of the phone that captured this
  final String? deviceName; // human-readable model of that phone

  // Fall back to the insert time when the device did not stamp a posted time.
  DateTime get displayTime => postedAt ?? createdAt;

  // Human label for the source app; package name is the last resort.
  String get sourceLabel => appName ?? appPackage ?? 'Bilinmeyen uygulama';

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      appPackage: json['app_package'] as String?,
      appName: json['app_name'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      postedAt: json['posted_at'] == null
          ? null
          : DateTime.parse(json['posted_at'] as String),
      isTransaction: (json['is_transaction'] as bool?) ?? false,
      rawJson: json['raw_json']?.toString(),
      deviceId: json['device_id'] as String?,
      deviceName: json['device_name'] as String?,
    );
  }

  // Insert payload for the capture path (Phase 2B). `id` is client-generated
  // for stable offline ids; RLS binds `user_id`.
  Map<String, dynamic> toInsert(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'app_package': appPackage,
      'app_name': appName,
      'title': title,
      'body': body,
      'posted_at': postedAt?.toIso8601String(),
      'is_transaction': isTransaction,
      'raw_json': rawJson,
      'device_id': deviceId,
      'device_name': deviceName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
