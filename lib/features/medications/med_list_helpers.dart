import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/medication.dart';
import '../../data/models/medication_dose_slot.dart';

/// List layout for the medications screen.
enum MedViewMode { today, all }

/// Meds list palette (teal / slate) — complements Material 3 seed theme.
abstract class MedListColors { static const background = Color(0xFFFFF7ED);
  static const card = Colors.white;
  static const primaryColor = Color(0xFFEA580C);
  static const active = Color(0xFF22C55E);
  static const hold = Color(0xFFF59E0B);
  static const completed = Color(0xFF64748B);
  static const stockSafe = Color(0xFF16A34A);
  static const stockLow = Color(0xFFF97316);
  static const stockCritical = Color(0xFFDC2626);
  static const cardBorder = Color(0xFFFED7AA);
  static const lightOrange = Color(0xFFFB923C);}

/// Buckets medications by [Medication.groupId], using [scheduleRaw] `group_name`
/// when present. Ungrouped meds use the key `"Ungrouped"`.
Map<String, List<Medication>> groupMedications(List<Medication> meds) {
  final byGroupId = <String, List<Medication>>{};
  for (final m in meds) {
    final raw = m.groupId?.trim();
    final id = (raw == null || raw.isEmpty) ? '' : raw;
    (byGroupId[id] ??= []).add(m);
  }

  int cmp(Medication a, Medication b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  final out = <String, List<Medication>>{};
  final ungrouped = byGroupId.remove('');
  if (ungrouped != null && ungrouped.isNotEmpty) {
    ungrouped.sort(cmp);
    out['Ungrouped'] = ungrouped;
  }

  final sortedIds = byGroupId.keys.toList()..sort();
  for (final gid in sortedIds) {
    final list = byGroupId[gid]!;
    list.sort(cmp);
    var title = _displayTitleForGroup(gid, list);
    if (out.containsKey(title)) {
      title = '$title · ${gid.length <= 8 ? gid : '${gid.substring(0, 8)}…'}';
    }
    out[title] = list;
  }
  return out;
}

String _displayTitleForGroup(String groupId, List<Medication> meds) {
  for (final m in meds) {
    final n = m.scheduleRaw['group_name'] as String?;
    if (n != null && n.trim().isNotEmpty) return n.trim();
  }
  return groupId;
}

/// Ordered entries: Ungrouped first when present, then alphabetical by title.
List<MapEntry<String, List<Medication>>> orderedGroupEntries(
  Map<String, List<Medication>> grouped,
) {
  final e = grouped.entries.toList();
  e.sort((a, b) {
    if (a.key == 'Ungrouped') return -1;
    if (b.key == 'Ungrouped') return 1;
    return a.key.toLowerCase().compareTo(b.key.toLowerCase());
  });
  return e;
}

int _inventoryDaysLeft(Medication med) {
  final tpd = med.doseSlots.isEmpty ? 1 : tabletsPerDayFromSlots(med.doseSlots);
  final rem = med.inventory.remainingTablets;
  if (tpd < 1 || rem < 1) return 0;
  return rem ~/ tpd;
}

/// `critical` | `low` | `safe` — by estimated days of supply at current pace.
String getStockStatus(Medication med) {
  final days = _inventoryDaysLeft(med);
  if (days <= 1) return 'critical';
  if (days <= 3) return 'low';
  return 'safe';
}

Color stockStatusColor(String status) {
  switch (status) {
    case 'critical':
      return MedListColors.stockCritical;
    case 'low':
      return MedListColors.stockLow;
    default:
      return MedListColors.stockSafe;
  }
}

String stockStatusLabel(String status) {
  switch (status) {
    case 'critical':
      return 'Critical';
    case 'low':
      return 'Low';
    default:
      return 'OK';
  }
}

Color medicationStatusColor(String status) {
  switch (status) {
    case MedicationStatus.hold:
      return MedListColors.hold;
    case MedicationStatus.completed:
      return MedListColors.completed;
    default:
      return MedListColors.active;
  }
}

/// Next scheduled dose today, or first dose tomorrow — `Next: h:mm a`.
String nextDoseLine(Medication med) {
  final times = med.doseSlots.isNotEmpty
      ? med.doseSlots.map((e) => e.time).toList(growable: false)
      : List<String>.from(med.scheduleTimes);
  if (times.isEmpty) return 'Next: —';

  final now = DateTime.now();
  final todayMinutes = now.hour * 60 + now.minute;
  int? earliestAfterNow;

  for (final t in times) {
    final m = parseHHmmToMinutes(t);
    if (m == null) continue;
    if (m > todayMinutes) {
      final prev = earliestAfterNow;
      earliestAfterNow = prev == null ? m : (m < prev ? m : prev);
    }
  }

  final DateTime target;
  if (earliestAfterNow != null) {
    target = DateTime(
      now.year,
      now.month,
      now.day,
      earliestAfterNow ~/ 60,
      earliestAfterNow % 60,
    );
  } else {
    final first = parseHHmmToMinutes(times.first);
    if (first == null) return 'Next: —';
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    target = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      first ~/ 60,
      first % 60,
    );
  }

  return 'Next: ${DateFormat('h:mm a').format(target)}';
}

List<String> _doseTimeStrings(Medication med) {
  if (med.doseSlots.isNotEmpty) {
    return med.doseSlots.map((e) => e.time).toList(growable: false);
  }
  return List<String>.from(med.scheduleTimes);
}

/// Slot index for the upcoming dose ([nextDoseLine]); wraps to first slot for “tomorrow”.
int upcomingDoseSlotIndex(Medication med) {
  final slotTimes = _doseTimeStrings(med);
  if (slotTimes.isEmpty) return 0;

  final now = DateTime.now();
  final todayMinutes = now.hour * 60 + now.minute;
  int? earliestAfterNow;

  for (final t in slotTimes) {
    final m = parseHHmmToMinutes(t);
    if (m == null) continue;
    if (m > todayMinutes) {
      final prev = earliestAfterNow;
      earliestAfterNow = prev == null ? m : (m < prev ? m : prev);
    }
  }

  if (earliestAfterNow != null) {
    for (var i = 0; i < slotTimes.length; i++) {
      if (parseHHmmToMinutes(slotTimes[i]) == earliestAfterNow) return i;
    }
  }
  return 0;
}

/// Tablet count for the dose being marked (closest upcoming schedule row).
int tabletsForMarkTaken(Medication med) {
  if (med.doseSlots.isEmpty) {
    return parseTabletCount(med.dosage);
  }
  final i = upcomingDoseSlotIndex(med).clamp(0, med.doseSlots.length - 1);
  return parseTabletCount(med.doseSlots[i].doseLabel);
}
