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
