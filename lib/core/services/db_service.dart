import 'package:sqflite/sqflite.dart';

import '../../data/local/sqlite_db.dart';
import '../../data/models/log.dart';
import '../../data/models/medication.dart';

class DbService {
  final SqliteDb _sqliteDb;

  DbService(this._sqliteDb);

  Future<Database> get _db => _sqliteDb.database;

  // ---------- Medications ----------
  Future<List<Medication>> listMedications({required String userId}) async {
    final db = await _db;
    final rows = await db.query(
      'medications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Medication.fromMap).toList(growable: false);
  }

  Future<Medication?> getMedication(String id) async {
    final db = await _db;
    final rows = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Medication.fromMap(rows.first);
  }

  Future<void> upsertMedication(Medication med) async {
    final db = await _db;
    await db.insert(
      'medications',
      med.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMedication(String id) async {
    final db = await _db;
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Logs ----------
  Future<void> addLog(MedicationLog log) async {
    final db = await _db;
    await db.insert(
      'logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MedicationLog>> listLogs({String? medId, int limit = 200}) async {
    final db = await _db;
    final rows = await db.query(
      'logs',
      where: medId == null ? null : 'med_id = ?',
      whereArgs: medId == null ? null : [medId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(MedicationLog.fromMap).toList(growable: false);
  }

  Future<List<MedicationLog>> listUnsyncedLogs({int limit = 500}) async {
    final db = await _db;
    final rows = await db.query(
      'logs',
      where: 'synced = 0',
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return rows.map(MedicationLog.fromMap).toList(growable: false);
  }

  Future<void> markLogSynced(String logId) async {
    final db = await _db;
    await db.update('logs', {'synced': 1}, where: 'id = ?', whereArgs: [logId]);
  }

  /// Decrements remaining inventory when a dose is logged as taken.
  /// Any `taken` log for this medication on the local calendar day (duplicate guard).
  Future<bool> hasTakenLogToday(String medId) async {
    final db = await _db;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      'SELECT 1 FROM logs WHERE med_id = ? AND status = ? AND timestamp >= ? AND timestamp <= ? LIMIT 1',
      [medId, 'taken', start, end],
    );
    return rows.isNotEmpty;
  }

  /// Distinct medication ids that already have a `taken` log today (for list UI).
  Future<Set<String>> medIdsWithTakenLogToday() async {
    final db = await _db;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      'SELECT DISTINCT med_id FROM logs WHERE status = ? AND timestamp >= ? AND timestamp <= ?',
      ['taken', start, end],
    );
    return rows.map((r) => r['med_id'] as String).toSet();
  }

  Future<void> applyTakenInventoryDecrement(
    String medId, {
    int tablets = 1,
  }) async {
    final m = await getMedication(medId);
    if (m == null) return;
    final t = tablets < 1 ? 1 : tablets;
    final nextRem = (m.inventory.remainingTablets - t).clamp(0, 0x7fffffff);
    final updated = m.copyWith(
      inventory: m.inventory.copyWith(remainingTablets: nextRem),
    );
    await upsertMedication(updated);
  }

  Future<void> ensureLogsSchema() async {
    final db = await _db;
    final info = await db.rawQuery("PRAGMA table_info(logs)");
    final hasSlot = info.any((row) => row["name"] == "scheduled_slot");
    if (!hasSlot) {
      await db.execute("ALTER TABLE logs ADD COLUMN scheduled_slot TEXT;");
    }
  }

  Future<bool> hasTakenLogForSlot(String medId, String slotHHmm) async {
    final db = await _db;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = start + 86400000 - 1;
    final rows = await db.rawQuery(
      """SELECT 1 FROM logs WHERE med_id=? AND status='taken' AND scheduled_slot=? AND timestamp >= ? AND timestamp <= ? LIMIT 1""",
      [medId, slotHHmm, start, end],
    );
    return rows.isNotEmpty;
  }

  Future<Map<String, Set<String>>> medSlotsTakenToday() async {
    final db = await _db;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = start + 86400000 - 1;
    final rows = await db.rawQuery(
      """SELECT med_id, scheduled_slot FROM logs WHERE status='taken' AND timestamp >= ? AND timestamp <= ? AND scheduled_slot IS NOT NULL""",
      [start, end],
    );
    final map = <String, Set<String>>{};
    for (final row in rows) {
      final mid = row['med_id'] as String;
      final slot = row['scheduled_slot'] as String?;
      if (slot != null) {
        map.putIfAbsent(mid, () => <String>{}).add(slot);
      }
    }
    return map;
  }
}
