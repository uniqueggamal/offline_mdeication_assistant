import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqliteDb {
  static const _dbName = 'offline_medication_assistant.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await _open();
    _db = opened;
    return opened;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE medications(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  schedule TEXT NOT NULL,
  user_id TEXT NOT NULL
)
''');

        await db.execute('''
CREATE TABLE logs(
  id TEXT PRIMARY KEY,
  med_id TEXT NOT NULL,
  status TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  synced INTEGER NOT NULL DEFAULT 0,
  scheduled_slot TEXT
)
''');

        await db.execute('CREATE INDEX idx_logs_synced ON logs(synced)');
        await db.execute('CREATE INDEX idx_logs_med_id ON logs(med_id)');
        await db.execute('CREATE INDEX idx_logs_timestamp ON logs(timestamp)');
      },
    );
  }
}
