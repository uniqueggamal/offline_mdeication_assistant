import 'package:flutter/material.dart';

import '../../data/models/medication.dart';

class MedicationGroup {
  final String id; // group_id or 'ungrouped'
  final String title;
  final Color color;
  final List<Medication> medications;

  const MedicationGroup({
    required this.id,
    required this.title,
    required this.color,
    required this.medications,
  });
}

class MedicationGrouping {
  static const String ungroupedId = 'ungrouped';

  /// Groups by `group_id` stored inside `Medication.schedule` for now, so we
  /// don't require schema changes.
  ///
  /// Expected (optional) keys inside schedule JSON:
  /// - group_id: String
  /// - group_name: String
  /// - group_color: int (ARGB)
  static List<MedicationGroup> group(List<Medication> meds) {
    final map = <String, List<Medication>>{};

    for (final m in meds) {
      final groupId = _asString(m.schedule['group_id'])?.trim();
      final key = (groupId == null || groupId.isEmpty) ? ungroupedId : groupId;
      (map[key] ??= <Medication>[]).add(m);
    }

    final groups = <MedicationGroup>[];
    for (final entry in map.entries) {
      final groupMeds = entry.value..sort((a, b) => a.name.compareTo(b.name));
      final sampleSchedule = groupMeds.first.schedule;
      final title = entry.key == ungroupedId
          ? 'Ungrouped'
          : (_asString(sampleSchedule['group_name']) ?? entry.key);
      final color = _colorFromScheduleOrHash(sampleSchedule, entry.key);

      groups.add(
        MedicationGroup(
          id: entry.key,
          title: title,
          color: color,
          medications: List<Medication>.unmodifiable(groupMeds),
        ),
      );
    }

    groups.sort((a, b) {
      if (a.id == ungroupedId && b.id != ungroupedId) return 1;
      if (b.id == ungroupedId && a.id != ungroupedId) return -1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return List<MedicationGroup>.unmodifiable(groups);
  }

  static String? _asString(Object? v) => v is String ? v : null;

  static Color _colorFromScheduleOrHash(Map<String, dynamic> schedule, String id) {
    final raw = schedule['group_color'];
    if (raw is int) return Color(raw);

    // Stable pastel-ish color based on id hash.
    final h = id.hashCode;
    final r = 120 + (h & 0x3F);
    final g = 120 + ((h >> 6) & 0x3F);
    final b = 120 + ((h >> 12) & 0x3F);
    return Color.fromARGB(255, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
  }
}

