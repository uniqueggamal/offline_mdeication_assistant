import 'medication_dose_slot.dart';

/// Payload returned from the medication detail/editor screen when the user saves.
class MedicationEditorResult {
  final String name;
  final String dosage;
  final int dosePerDay;
  final String firstDoseTime;
  final List<MedicationDoseSlot> doseSlots;
  final bool manualSlotTimes;
  final String? groupId;
  final String? groupDisplayName;
  final int? groupColorArgb;
  final String? imagePath;
  final MedicationInventory inventory;
  final String status;
  final String mealRelation;
  final String instructions;
  final String doctorNotes;
  final String patientNotes;

  const MedicationEditorResult({
    required this.name,
    required this.dosage,
    required this.dosePerDay,
    required this.firstDoseTime,
    required this.doseSlots,
    required this.manualSlotTimes,
    required this.inventory,
    required this.status,
    required this.mealRelation,
    required this.instructions,
    required this.doctorNotes,
    required this.patientNotes,
    this.groupId,
    this.groupDisplayName,
    this.groupColorArgb,
    this.imagePath,
  });
}

/// Pop result: `null` = cancelled; otherwise saved or deleted.
class MedicationEditorOutcome {
  final bool deleted;
  final MedicationEditorResult? saved;

  const MedicationEditorOutcome.deleted()
      : deleted = true,
        saved = null;

  const MedicationEditorOutcome.saved(this.saved) : deleted = false;
}
