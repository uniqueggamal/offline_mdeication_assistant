import 'package:uuid/uuid.dart';

import '../../core/services/db_service.dart';
import '../../core/services/intent_engine.dart';
import '../../core/services/tts_service.dart';
import '../../data/models/log.dart';
import '../../data/models/medication.dart';
import '../../data/models/medication_dose_slot.dart';
import 'response_generator.dart';

class AssistantController {
  final DbService _db;
  final IntentEngine _intentEngine;
  final ResponseGenerator _responses;
  final TtsService _tts;
  final Uuid _uuid = const Uuid();

  AssistantController({
    required DbService db,
    required IntentEngine intentEngine,
    required ResponseGenerator responses,
    required TtsService tts,
  })  : _db = db,
        _intentEngine = intentEngine,
        _responses = responses,
        _tts = tts;

  Future<AssistantTurn> handleText({
    required String userId,
    required String text,
  }) async {
    final intent = _intentEngine.process(text);

    String? schedulePreview;
    if (intent.intent == 'ask_schedule') {
      final meds = await _db.listMedications(userId: userId);
      schedulePreview = _formatSchedulePreview(meds);
    }

    if (intent.intent == 'mark_taken' || intent.intent == 'missed') {
      final meds = await _db.listMedications(userId: userId);
      final Medication? target = meds.isEmpty ? null : meds.first;
      if (target != null) {
        final log = MedicationLog(
          id: _uuid.v4(),
          medId: target.id,
          status: intent.intent == 'mark_taken' ? 'taken' : 'missed',
          timestamp: DateTime.now(),
          synced: false,
        );
        await _db.addLog(log);
        if (intent.intent == 'mark_taken') {
          final tablets = target.doseSlots.isNotEmpty
              ? parseTabletCount(target.doseSlots.first.doseLabel)
              : parseTabletCount(target.dosage);
          await _db.applyTakenInventoryDecrement(target.id, tablets: tablets);
        }
      }
    }

    final reply = _responses.generate(intent, schedulePreview: schedulePreview);
    await _tts.speak(reply);

    return AssistantTurn(
      userText: text,
      intentJson: intent.toJson(),
      assistantText: reply,
    );
  }

  String _formatSchedulePreview(List<Medication> meds) {
    if (meds.isEmpty) return '';
    final parts = <String>[];
    for (final m in meds.take(3)) {
      final times = (m.schedule['times'] as List?)?.cast<String>() ?? const [];
      parts.add('${m.name} (${times.join(', ')})');
    }
    final more = meds.length > 3 ? ' +${meds.length - 3} more' : '';
    return parts.join(' | ') + more;
  }
}

class AssistantTurn {
  final String userText;
  final Map<String, Object?> intentJson;
  final String assistantText;

  const AssistantTurn({
    required this.userText,
    required this.intentJson,
    required this.assistantText,
  });
}

