import 'api_service.dart';
import 'auth_service.dart';
import 'local_db_service.dart';

/// Drop-in replacement for calling ApiService directly from screens.
/// Same method names/signatures as ApiService (get/post/put/delete), but:
///  - get(): tries the network first, caches the fresh result locally,
///           and falls back to the local cache if offline or the request fails.
///  - post()/put()/delete(): try the network first; if it fails (offline),
///           the change is saved locally and queued as "pending" so it can
///           be pushed automatically once connectivity returns (see syncPending()).
///
/// Because LocalDbService.clearAll() is wiped on every logout, this cache
/// never leaks one user's offline data into a different user's session.
class Repository {
  final ApiService api;
  final LocalDbService db = LocalDbService.instance;

  Repository(AuthService auth) : api = ApiService(auth);

  String _endpointFromPath(String path) {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    return '/${parts.first}';
  }

  String _idFromPath(String path) {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    return parts.last;
  }

  Future<List<dynamic>> get(String endpoint) async {
    try {
      final data = await api.get(endpoint);
      final list = (data is List) ? List<Map<String, dynamic>>.from(data) : <Map<String, dynamic>>[];
      await db.replaceAll(endpoint, list);
      // Merge in any not-yet-synced local creates/updates for this endpoint
      // so the user still sees their offline edits even right after a refresh.
      final pending = await db.getPending();
      final localOnly = pending
          .where((r) => r.endpoint == endpoint && r.pendingAction != 'delete')
          .map((r) => r.data)
          .where((d) => !list.any((s) => s['_id'] == d['_id']))
          .toList();
      return [...list, ...localOnly];
    } catch (_) {
      // Offline (or request failed) — serve whatever we have cached.
      return db.getAll(endpoint);
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final result = await api.post(endpoint, body);
      await db.upsert(endpoint, result['_id'].toString(), result);
      return result;
    } catch (_) {
      final tempId = 'local_${DateTime.now().microsecondsSinceEpoch}';
      final localRecord = {...body, '_id': tempId};
      await db.upsert(endpoint, tempId, localRecord, pendingAction: 'create');
      return localRecord;
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final endpoint = _endpointFromPath(path);
    final id = _idFromPath(path);
    try {
      final result = await api.put(path, body);
      await db.upsert(endpoint, id, result);
      return result;
    } catch (_) {
      final merged = {...body, '_id': id};
      await db.upsert(endpoint, id, merged, pendingAction: 'update');
      return merged;
    }
  }

  Future<void> delete(String path) async {
    final endpoint = _endpointFromPath(path);
    final id = _idFromPath(path);
    try {
      await api.delete(path);
      await db.delete(endpoint, id);
    } catch (_) {
      if (id.startsWith('local_')) {
        // Never made it to the server in the first place — just drop it.
        await db.delete(endpoint, id);
      } else {
        await db.markPendingDelete(endpoint, id);
      }
    }
  }

  /// Pushes every queued offline change to the server. Call this on app
  /// start, on pull-to-refresh, or when connectivity comes back
  /// (see ConnectivitySyncListener).
  Future<void> syncPending() async {
    final pending = await db.getPending();
    for (final rec in pending) {
      try {
        switch (rec.pendingAction) {
          case 'create':
            final body = Map<String, dynamic>.from(rec.data)..remove('_id');
            final result = await api.post(rec.endpoint, body);
            await db.delete(rec.endpoint, rec.id); // drop the temp local id
            await db.upsert(rec.endpoint, result['_id'].toString(), result);
            break;
          case 'update':
            final body = Map<String, dynamic>.from(rec.data)..remove('_id');
            final result = await api.put('${rec.endpoint}/${rec.id}', body);
            await db.upsert(rec.endpoint, rec.id, result);
            break;
          case 'delete':
            await api.delete('${rec.endpoint}/${rec.id}');
            await db.delete(rec.endpoint, rec.id);
            break;
        }
      } catch (_) {
        // Still offline or server rejected it — leave it queued, try again later.
      }
    }
  }
}
