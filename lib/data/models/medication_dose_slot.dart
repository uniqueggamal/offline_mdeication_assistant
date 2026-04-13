/// One scheduled dose row (time + dose label + meal relation).
class MedicationDoseSlot {
  final String time; // HH:mm
  final String doseLabel;
  final String mealRelation; // before_meal | after_meal | none

  const MedicationDoseSlot({
    required this.time,
    this.doseLabel = '1 tablet',
    this.mealRelation = 'none',
  });

  Map<String, dynamic> toJson() => {
        'time': time,
        'dose': doseLabel,
        'meal_relation': mealRelation,
      };

  static String normalizeMeal(String? v) {
    if (v == 'before_meal' || v == 'after_meal') return v!;
    return 'none';
  }

  static MedicationDoseSlot fromJson(Map<String, dynamic> j) {
    return MedicationDoseSlot(
      time: (j['time'] as String?)?.trim().isNotEmpty == true
          ? j['time'] as String
          : '08:00',
      doseLabel: (j['dose'] as String?)?.trim().isNotEmpty == true
          ? j['dose'] as String
          : '1 tablet',
      mealRelation: normalizeMeal(j['meal_relation'] as String?),
    );
  }

  MedicationDoseSlot copyWith({
    String? time,
    String? doseLabel,
    String? mealRelation,
  }) {
    return MedicationDoseSlot(
      time: time ?? this.time,
      doseLabel: doseLabel ?? this.doseLabel,
      mealRelation: mealRelation ?? this.mealRelation,
    );
  }
}

class MedicationInventory {
  final int totalTablets;
  final int remainingTablets;

  const MedicationInventory({
    this.totalTablets = 0,
    this.remainingTablets = 0,
  });

  Map<String, dynamic> toJson() => {
        'total': totalTablets,
        'remaining': remainingTablets,
      };

  static MedicationInventory fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return const MedicationInventory();
    }
    final total = (j['total'] as num?)?.toInt() ?? 0;
    final rem = (j['remaining'] as num?)?.toInt() ?? total;
    return MedicationInventory(
      totalTablets: total < 0 ? 0 : total,
      remainingTablets: rem < 0 ? 0 : rem,
    );
  }

  MedicationInventory copyWith({
    int? totalTablets,
    int? remainingTablets,
  }) {
    return MedicationInventory(
      totalTablets: totalTablets ?? this.totalTablets,
      remainingTablets: remainingTablets ?? this.remainingTablets,
    );
  }
}

class MedicationStatus {
  static const active = 'active';
  static const hold = 'hold';
  static const completed = 'completed';

  static bool isKnown(String s) =>
      s == active || s == hold || s == completed;
}

/// Evenly spaces [dosePerDay] doses across 24h, starting at [firstHHmm].
List<String> generateDoseTimeStrings({
  required int dosePerDay,
  required String firstHHmm,
}) {
  final n = dosePerDay < 1 ? 1 : dosePerDay;
  final first = _parseMinutes(firstHHmm) ?? 8 * 60;
  final intervalMinutes = ((24 * 60) / n).round();
  final out = <String>[];
  for (var i = 0; i < n; i++) {
    final m = (first + i * intervalMinutes) % (24 * 60);
    out.add(_formatMinutes(m));
  }
  return out;
}

List<MedicationDoseSlot> buildAutoSlots({
  required int dosePerDay,
  required String firstHHmm,
  required String defaultMeal,
  required String doseLabel,
}) {
  final times = generateDoseTimeStrings(
    dosePerDay: dosePerDay,
    firstHHmm: firstHHmm,
  );
  return times
      .map(
        (t) => MedicationDoseSlot(
          time: t,
          doseLabel: doseLabel,
          mealRelation: defaultMeal,
        ),
      )
      .toList(growable: false);
}

int? _parseMinutes(String hhmm) {
  final m = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(hhmm.trim());
  if (m == null) return null;
  return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
}

String _formatMinutes(int totalMinutes) {
  final h = (totalMinutes % (24 * 60)) ~/ 60;
  final min = (totalMinutes % (24 * 60)) % 60;
  return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

/// Rough tablets per day from dose labels (e.g. "1 tablet" -> 1).
int tabletsPerDayFromSlots(List<MedicationDoseSlot> slots) {
  if (slots.isEmpty) return 1;
  var sum = 0;
  for (final s in slots) {
    sum += parseTabletCount(s.doseLabel);
  }
  return sum < 1 ? 1 : sum;
}

int parseTabletCount(String label) {
  final m = RegExp(r'^(\d+)').firstMatch(label.trim());
  if (m != null) return int.tryParse(m.group(1)!) ?? 1;
  return 1;
}

/// Parses "HH:mm" into minutes from midnight; null if invalid.
int? parseHHmmToMinutes(String hhmm) => _parseMinutes(hhmm);

String formatMinutesToHHmm(int totalMinutes) => _formatMinutes(totalMinutes);
