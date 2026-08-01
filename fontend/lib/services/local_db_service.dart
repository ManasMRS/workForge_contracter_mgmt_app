import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// A single locally-cached record. [pendingAction] is null when the record
/// is fully synced with the server; otherwise it's 'create', 'update', or
/// 'delete', meaning this change still needs to be pushed once we're online.
class LocalRecord {
  final String endpoint;
  final String id;
  final Map<String, dynamic> data;
  final String? pendingAction;

  LocalRecord({
    required this.endpoint,
    required this.id,
    required this.data,
    this.pendingAction,
  });
}

/// Generic local cache: one SQLite table holds every entity type
/// (employees, sites, machines, attendance, salary), keyed by
/// (endpoint, id). Each row stores the record as a JSON blob plus a
/// `pending_action` flag used to queue offline writes for later sync.
///
/// IMPORTANT for multi-user privacy: [clearAll] is called from
/// AuthService.logout(), wiping this cache completely so a second
/// person signing in on the same device never sees the previous
/// user's offline data.
class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'contractor_app_cache.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            endpoint TEXT NOT NULL,
            id TEXT NOT NULL,
            data TEXT NOT NULL,
            pending_action TEXT,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (endpoint, id)
          )
        ''');
      },
    );
    return _db!;
  }

  /// Replaces the full local snapshot for [endpoint] with fresh server
  /// data — used right after a successful GET. Records still queued
  /// with a pending write are preserved so we don't lose offline edits
  /// that haven't synced yet.
  Future<void> replaceAll(String endpoint, List<Map<String, dynamic>> items) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete(
        'records',
        where: 'endpoint = ? AND pending_action IS NULL',
        whereArgs: [endpoint],
      );
      for (final item in items) {
        final id = item['_id']?.toString();
        if (id == null) continue;
        await txn.insert(
          'records',
          {
            'endpoint': endpoint,
            'id': id,
            'data': jsonEncode(item),
            'pending_action': null,
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAll(String endpoint) async {
    final db = await _database;
    final rows = await db.query(
      'records',
      where: 'endpoint = ? AND pending_action IS NOT "delete"',
      whereArgs: [endpoint],
    );
    return rows.map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>).toList();
  }

  Future<void> upsert(
    String endpoint,
    String id,
    Map<String, dynamic> data, {
    String? pendingAction,
  }) async {
    final db = await _database;
    await db.insert(
      'records',
      {
        'endpoint': endpoint,
        'id': id,
        'data': jsonEncode(data),
        'pending_action': pendingAction,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markPendingDelete(String endpoint, String id) async {
    final db = await _database;
    await db.update(
      'records',
      {'pending_action': 'delete', 'updated_at': DateTime.now().toIso8601String()},
      where: 'endpoint = ? AND id = ?',
      whereArgs: [endpoint, id],
    );
  }

  Future<void> delete(String endpoint, String id) async {
    final db = await _database;
    await db.delete('records', where: 'endpoint = ? AND id = ?', whereArgs: [endpoint, id]);
  }

  Future<List<LocalRecord>> getPending() async {
    final db = await _database;
    final rows = await db.query('records', where: 'pending_action IS NOT NULL');
    return rows
        .map((r) => LocalRecord(
              endpoint: r['endpoint'] as String,
              id: r['id'] as String,
              data: jsonDecode(r['data'] as String) as Map<String, dynamic>,
              pendingAction: r['pending_action'] as String?,
            ))
        .toList();
  }

  /// Wipes the entire local cache. Called on logout so a different user
  /// signing in next never sees this user's offline-cached records.
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('records');
  }
}
