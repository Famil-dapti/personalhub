import 'package:drift/drift.dart';

/// Local mirror of the Supabase `transactions` table plus sync columns.
/// `updatedAt` is the delta-pull watermark; `deletedAt` is a soft-delete
/// tombstone (UI filters it out, sync propagates it).
class LocalTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('AZN'))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get notificationId => text().nullable()();
  // Phase 4: an SMS-derived draft awaiting user confirm. Excluded from the
  // balance and shown as "Taslak" until committed (pending = false).
  BoolColumn get pending => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of the Supabase `categories` table. `userId` null = system
/// preset (pull-only; never queued for push).
class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local mirror of the Supabase `notifications` table. Append-only and
/// immutable (captured on Android, browsed everywhere) — no `deletedAt` and
/// no `updatedAt`; the `createdAt` server insert time is the delta-pull
/// watermark. `rawJson` stores the full payload as an encoded JSON string.
class LocalNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get appPackage => text().nullable()();
  TextColumn get appName => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().nullable()();
  DateTimeColumn get postedAt => dateTime().nullable()();
  BoolColumn get isTransaction => boolean().withDefault(const Constant(false))();
  TextColumn get rawJson => text().nullable()();
  // Which phone captured this (two phones, one account). Null for older rows.
  TextColumn get deviceId => text().nullable()();
  TextColumn get deviceName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local-only index of every photo/video on this device (Phase 3 Media
/// Cleaner). Never synced to Supabase — `assetId` and file metadata are
/// device-specific. Rebuilt by a full scan on first run and kept current by a
/// per-launch delta. The working set the swipe deck draws from.
class LocalMediaAssets extends Table {
  TextColumn get assetId => text()(); // photo_manager AssetEntity.id
  TextColumn get deviceId => text()();
  TextColumn get type => text()(); // 'image' | 'video'
  TextColumn get albumId => text().nullable()();
  TextColumn get albumName => text().nullable()();
  TextColumn get relativePath => text().nullable()(); // for screenshot detection
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationSec => integer().nullable()(); // videos only
  DateTimeColumn get createdDate => dateTime().nullable()(); // asset capture time
  TextColumn get title => text().nullable()();
  DateTimeColumn get indexedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {assetId};
}

/// Local-only keep/delete/favorite/later decisions (Phase 3). Never synced as
/// individual rows (only per-device aggregates go to Supabase). Persists even
/// after the asset is deleted from the device so cumulative stats survive.
/// `decision`: 'keep' | 'delete' | 'favorite' | 'later'. `pendingDelete` is
/// true for a delete not yet executed against device storage.
class LocalMediaDecisions extends Table {
  TextColumn get assetId => text()();
  TextColumn get deviceId => text()();
  TextColumn get decision => text()();
  BoolColumn get pendingDelete => boolean().withDefault(const Constant(false))();
  DateTimeColumn get decidedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {assetId};
}

/// Mirror of the Supabase `media_stats` table — per-device aggregate counters
/// (total / decided / kept / deleted) so every device and the web app can show
/// each phone's cleanup progress. This is the ONLY media data that syncs.
class LocalMediaStats extends Table {
  TextColumn get id => text()(); // stable per-device uuid (push upsert key)
  TextColumn get userId => text()();
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text().nullable()();
  IntColumn get total => integer().withDefault(const Constant(0))();
  IntColumn get decided => integer().withDefault(const Constant(0))();
  IntColumn get kept => integer().withDefault(const Constant(0))();
  IntColumn get deleted => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror of the Supabase `user_settings` table — per-user app settings
/// (Phase 4). Holds the optional Groq API key for the AI fallback parser. One
/// row per user (id == user id) so both phones converge on the same row;
/// standard `updated_at` LWW sync.
class LocalUserSettings extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get groqApiKey => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pending local mutations to push to Supabase, drained oldest-first on sync.
/// `op` is 'upsert' or 'delete'; `payload` is a JSON row snapshot for upserts.
class SyncOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get entityTable => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()();
  TextColumn get payload => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-table delta-pull watermark: the max server `updated_at` already pulled.
class SyncState extends Table {
  TextColumn get entity => text()();
  DateTimeColumn get lastPulledAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {entity};
}
