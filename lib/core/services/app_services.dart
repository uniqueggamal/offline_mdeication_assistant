import '../../data/local/sqlite_db.dart';
import '../../data/remote/firebase_service.dart';
import '../../features/assistant/intent_parser.dart';
import '../../features/assistant/response_generator.dart';
import 'db_service.dart';
import 'intent_engine.dart';
import 'notification_service.dart';
import 'sync_service.dart';
import 'tts_service.dart';

class AppServices {
  final SqliteDb sqliteDb = SqliteDb();
  late final DbService db = DbService(sqliteDb);

  final TtsService tts = TtsService();
  final NotificationService notifications = NotificationService();

  final IntentParser intentParser = IntentParser();
  late final IntentEngine intentEngine = IntentEngine(intentParser);
  final ResponseGenerator responses = ResponseGenerator();

  final FirebaseService firebase = FirebaseService();
  late final SyncService sync = SyncService(db: db, firebase: firebase);
}

