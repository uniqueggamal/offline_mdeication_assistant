import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/remote/firebase_service.dart';
import 'db_service.dart';

class SyncService {
  final DbService _db;
  final FirebaseService _firebase;
  final Connectivity _connectivity = Connectivity();

  SyncService({
    required DbService db,
    required FirebaseService firebase,
  })  : _db = db,
        _firebase = firebase;

  Future<SyncResult> syncUnsyncedLogs({required String userId}) async {
    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return const SyncResult(ok: false, pushed: 0, reason: 'offline');
    }

    final logs = await _db.listUnsyncedLogs();
    var pushed = 0;

    for (final log in logs) {
      try {
        await _firebase.pushLog(userId: userId, log: log);
        await _db.markLogSynced(log.id);
        pushed++;
      } catch (_) {
        // Stop early on failure; try again later.
        break;
      }
    }

    return SyncResult(ok: true, pushed: pushed, reason: 'done');
  }
}

class SyncResult {
  final bool ok;
  final int pushed;
  final String reason;

  const SyncResult({
    required this.ok,
    required this.pushed,
    required this.reason,
  });
}

