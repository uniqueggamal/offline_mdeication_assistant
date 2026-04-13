import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/db_service.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/log.dart';
import '../../data/models/medication.dart';
import '../../data/models/medication_editor_result.dart';
import 'med_list_helpers.dart';

enum MarkTakenResult { ok, duplicate, insufficientStock, error }

class MedicationViewState {
  final bool loading;
  final MedViewMode mode;
  final List<Medication> medications;
  final Set<String> takenMedIdsToday;

  const MedicationViewState({
    required this.loading,
    required this.mode,
    required this.medications,
    this.takenMedIdsToday = const {},
  });
}

class MedicationViewController extends ChangeNotifier {
  final DbService _db;
  final NotificationService _notifications;
  final String _userId;
  final Uuid _uuid = const Uuid();

  MedicationViewState _state = const MedicationViewState(
    loading: true,
    mode: MedViewMode.today,
    medications: <Medication>[],
    takenMedIdsToday: {},
  );

  MedicationViewController({
    required DbService db,
    required NotificationService notifications,
    required String userId,
  }) : _db = db,
       _notifications = notifications,
       _userId = userId;

  MedicationViewState get state => _state;

  void setMode(MedViewMode mode) {
    if (_state.mode == mode) return;
    _state = MedicationViewState(
      loading: _state.loading,
      mode: mode,
      medications: _state.medications,
      takenMedIdsToday: _state.takenMedIdsToday,
    );
    notifyListeners();
  }

  void toggleViewMode() {
    setMode(
      _state.mode == MedViewMode.today         ? MedViewMode.all          : MedViewMode.today,
    );
  }

  Future<void> refresh() async {
    _state = MedicationViewState(
      loading: true,
      mode: _state.mode,
      medications: _state.medications,
      takenMedIdsToday: _state.takenMedIdsToday,
    );
    notifyListeners();

    final meds = await _db.listMedications(userId: _userId);
    final takenIds = await _db.medIdsWithTakenLogToday();

    _state = MedicationViewState(
      loading: false,
      mode: _state.mode,
      medications: meds,
      takenMedIdsToday: takenIds,
    );
    notifyListeners();
  }

  final Set<String> _markingTaken = {};

  bool isMarkingTaken(String medId) => _markingTaken.contains(medId);

  /// Logs one `taken` dose for today (one per medication per calendar day),
  /// decrements inventory by tablets for the **closest upcoming** scheduled slot.
  Future<MarkTakenResult> markMedicationTaken(Medication med) async {
    if (_markingTaken.contains(med.id)) {
      return MarkTakenResult.duplicate;
    }
    _markingTaken.add(med.id);
    notifyListeners();
    try {
      if (await _db.hasTakenLogToday(med.id)) {
        return MarkTakenResult.duplicate;
      }
      final fresh = await _db.getMedication(med.id);
      if (fresh == null) return MarkTakenResult.error;

      final tablets = tabletsForMarkTaken(fresh);
      if (fresh.inventory.remainingTablets < tablets) {
        return MarkTakenResult.insufficientStock;
      }

      final log = MedicationLog(
        id: _uuid.v4(),
        medId: fresh.id,
        status: 'taken',
        timestamp: DateTime.now(),
        synced: false,
      );
      await _db.addLog(log);
      await _db.applyTakenInventoryDecrement(fresh.id, tablets: tablets);
      await refresh();
      return MarkTakenResult.ok;
    } finally {
      _markingTaken.remove(med.id);
      notifyListeners();
    }
  }

  Future<void> upsertMedicationFromEditor({
    Medication? existing,
    required MedicationEditorResult r,
  }) async {
    final id = existing?.id ?? _uuid.v4();

    final mergedRaw = Map<String, dynamic>.from(existing?.scheduleRaw ?? {});
    final hasGroup = r.groupId != null && r.groupId!.trim().isNotEmpty;
    if (hasGroup &&
        r.groupDisplayName != null &&
        r.groupDisplayName!.trim().isNotEmpty) {
      mergedRaw['group_name'] = r.groupDisplayName!.trim();
    } else {
      mergedRaw.remove('group_name');
    }
    if (hasGroup && r.groupColorArgb != null) {
      mergedRaw['group_color'] = r.groupColorArgb;
    } else {
      mergedRaw.remove('group_color');
    }

    final times = r.doseSlots.map((e) => e.time).toList(growable: false);

    final next = Medication(
      id: id,
      name: r.name.trim(),
      dosage: r.dosage.trim(),
      userId: _userId,
      scheduleTimes: times,
      dosePerDay: r.dosePerDay,
      firstDoseTime: r.firstDoseTime,
      doseSlots: r.doseSlots,
      inventory: r.inventory,
      status: r.status,
      mealRelation: r.mealRelation,
      imagePath: r.imagePath ?? existing?.imagePath,
      groupId: r.groupId?.trim().isNotEmpty == true ? r.groupId!.trim() : null,
      scheduleRaw: mergedRaw,
      instructions: r.instructions,
      doctorNotes: r.doctorNotes,
      patientNotes: r.patientNotes,
      manualSlotTimes: r.manualSlotTimes,
    );

    await _db.upsertMedication(next);

    await _rescheduleAll();
    await refresh();
  }

  Future<void> deleteMedication(Medication med) async {
    await _db.deleteMedication(med.id);
    await _rescheduleAll();
    await refresh();
  }

  Future<void> _rescheduleAll() async {
    await _notifications.cancelAll();
    final all = await _db.listMedications(userId: _userId);
    for (final m in all) {
      await _notifications.scheduleMedicationReminders(med: m);
    }
  }
}
