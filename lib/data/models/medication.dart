import 'dart:convert';

import 'medication_dose_slot.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;

  /// Local file path to an image (stored under app documents dir).
  final String? imagePath;

  /// Optional grouping identifier.
  final String? groupId;

  /// Default meal for new auto-generated slots (`before_meal` | `after_meal` | `none`).
  final String mealRelation;

  /// Legacy: flat HH:mm list; kept in sync with [doseSlots] when present.
  final List<String> scheduleTimes;

  final String userId;

  /// Backing schedule map stored in SQLite `medications.schedule` (JSON string).
  final Map<String, dynamic> scheduleRaw;

  final int dosePerDay;
  final String firstDoseTime; // HH:mm

  /// Per-dose schedule (time, dose label, meal override).
  final List<MedicationDoseSlot> doseSlots;

  final MedicationInventory inventory;

  /// `active` | `hold` | `completed`
  final String status;

  final String instructions;
  final String doctorNotes;
  final String patientNotes;

  /// When true, [doseSlots] times may differ from strict auto spacing.
  final bool manualSlotTimes;

  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.userId,
    required this.scheduleTimes,
    required this.dosePerDay,
    required this.firstDoseTime,
    required this.doseSlots,
    required this.inventory,
    required this.status,
    this.imagePath,
    this.groupId,
    this.mealRelation = 'none',
    this.scheduleRaw = const {},
    this.instructions = '',
    this.doctorNotes = '',
    this.patientNotes = '',
    this.manualSlotTimes = false,
  });

  /// JSON stored in SQLite (canonical keys for grouping, sync, notifications).
  Map<String, dynamic> get schedule {
    final s = Map<String, dynamic>.from(scheduleRaw);
    final times = doseSlots.isNotEmpty
        ? doseSlots.map((e) => e.time).toList(growable: false)
        : scheduleTimes;
    s['times'] = times;
    s['image_path'] = imagePath;
    s['group_id'] = groupId;
    s['meal_relation'] = mealRelation;
    s['dose_per_day'] = dosePerDay;
    s['first_dose_time'] = firstDoseTime;
    s['slots'] = doseSlots.map((e) => e.toJson()).toList(growable: false);
    s['inventory'] = inventory.toJson();
    s['status'] = status;
    s['manual_slot_times'] = manualSlotTimes;
    s['instructions'] = instructions;
    s['doctor_notes'] = doctorNotes;
    s['patient_notes'] = patientNotes;
    s.removeWhere((k, v) => v == null);
    return s;
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? imagePath,
    String? groupId,
    String? mealRelation,
    List<String>? scheduleTimes,
    String? userId,
    Map<String, dynamic>? scheduleRaw,
    int? dosePerDay,
    String? firstDoseTime,
    List<MedicationDoseSlot>? doseSlots,
    MedicationInventory? inventory,
    String? status,
    String? instructions,
    String? doctorNotes,
    String? patientNotes,
    bool? manualSlotTimes,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      imagePath: imagePath ?? this.imagePath,
      groupId: groupId ?? this.groupId,
      mealRelation: mealRelation ?? this.mealRelation,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      userId: userId ?? this.userId,
      scheduleRaw: scheduleRaw ?? this.scheduleRaw,
      dosePerDay: dosePerDay ?? this.dosePerDay,
      firstDoseTime: firstDoseTime ?? this.firstDoseTime,
      doseSlots: doseSlots ?? this.doseSlots,
      inventory: inventory ?? this.inventory,
      status: status ?? this.status,
      instructions: instructions ?? this.instructions,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      patientNotes: patientNotes ?? this.patientNotes,
      manualSlotTimes: manualSlotTimes ?? this.manualSlotTimes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'schedule': jsonEncode(schedule),
      'user_id': userId,
    };
  }

  static Medication fromMap(Map<String, Object?> map) {
    final raw = jsonDecode(map['schedule'] as String) as Map<String, dynamic>;
    final name = map['name'] as String;
    final dosage = map['dosage'] as String;
    final userId = map['user_id'] as String;

    final meal = (raw['meal_relation'] as String?) ?? 'none';
    final safeMeal =
        (meal == 'before_meal' || meal == 'after_meal') ? meal : 'none';

    final groupId = raw['group_id'] as String?;
    final imagePath = raw['image_path'] as String?;

    final statusRaw = raw['status'] as String?;
    final status = MedicationStatus.isKnown(statusRaw ?? '')
        ? statusRaw!
        : MedicationStatus.active;

    final instructions = (raw['instructions'] as String?) ?? '';
    final doctorNotes = (raw['doctor_notes'] as String?) ?? '';
    final patientNotes = (raw['patient_notes'] as String?) ?? '';

    final inv = MedicationInventory.fromJson(
      raw['inventory'] is Map<String, dynamic>
          ? raw['inventory'] as Map<String, dynamic>
          : null,
    );

    final manualSlotTimes = raw['manual_slot_times'] == true;

    final slotsJson = raw['slots'];
    List<MedicationDoseSlot> doseSlots;
    List<String> legacyTimes =
        (raw['times'] as List?)?.cast<String>() ?? const <String>[];

    if (slotsJson is List && slotsJson.isNotEmpty) {
      doseSlots = slotsJson
          .whereType<Map>()
          .map((e) => MedicationDoseSlot.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } else {
      doseSlots = legacyTimes
          .map(
            (t) => MedicationDoseSlot(
              time: t,
              doseLabel: dosage,
              mealRelation: safeMeal,
            ),
          )
          .toList(growable: false);
    }

    if (legacyTimes.isEmpty && doseSlots.isNotEmpty) {
      legacyTimes = doseSlots.map((e) => e.time).toList(growable: false);
    }

    final dosePerDay = (raw['dose_per_day'] as num?)?.toInt() ??
        (doseSlots.isNotEmpty
            ? doseSlots.length
            : (legacyTimes.isNotEmpty ? legacyTimes.length : 1));

    var firstDoseTime = (raw['first_dose_time'] as String?)?.trim();
    if (firstDoseTime == null || firstDoseTime.isEmpty) {
      firstDoseTime = legacyTimes.isNotEmpty ? legacyTimes.first : '08:00';
    }

    if (doseSlots.isEmpty) {
      doseSlots = buildAutoSlots(
        dosePerDay: dosePerDay < 1 ? 1 : dosePerDay,
        firstHHmm: firstDoseTime,
        defaultMeal: safeMeal,
        doseLabel: dosage,
      );
      legacyTimes = doseSlots.map((e) => e.time).toList(growable: false);
    }

    return Medication(
      id: map['id'] as String,
      name: name,
      dosage: dosage,
      userId: userId,
      scheduleTimes: legacyTimes,
      dosePerDay: dosePerDay < 1 ? 1 : dosePerDay,
      firstDoseTime: firstDoseTime,
      doseSlots: doseSlots,
      inventory: inv,
      status: status,
      mealRelation: safeMeal,
      groupId: groupId,
      imagePath: imagePath,
      scheduleRaw: raw,
      instructions: instructions,
      doctorNotes: doctorNotes,
      patientNotes: patientNotes,
      manualSlotTimes: manualSlotTimes,
    );
  }
}
