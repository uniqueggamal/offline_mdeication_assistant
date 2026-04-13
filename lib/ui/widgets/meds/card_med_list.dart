import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/models/medication.dart';
import '../../../data/models/medication_dose_slot.dart';
import '../../../features/medications/med_list_helpers.dart';
import '../interactive_medication_card.dart';

/// Flat list of rich medication cards (image + details + stock).
class CardMedList extends StatelessWidget {
  final List<Medication> meds;
  final void Function(Medication med) onOpen;
  final void Function(Medication med) onDelete;
  final bool Function(Medication med) isTakenToday;
  final bool Function(Medication med) isMarkingTaken;
  final Future<void> Function(Medication med) onMarkTaken;

  const CardMedList({
    super.key,
    required this.meds,
    required this.onOpen,
    required this.onDelete,
    required this.isTakenToday,
    required this.isMarkingTaken,
    required this.onMarkTaken,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: meds.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = meds[i];
        final nextDose = nextDoseLine(m);
        final doseStr = m.dosage;
        return InteractiveMedicationCard(
          name: m.name,
          dosage: doseStr,
          time: nextDose,
          isTaken: isTakenToday(m),
          isMarkingTaken: isMarkingTaken(m),
          onMarkTaken: () => onMarkTaken(m),
          onDelete: () => onDelete(m),
          onOpen: () => onOpen(m),
        );
      },
    );
  }
}
