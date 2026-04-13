import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/models/medication.dart';
import '../../../data/models/medication_dose_slot.dart';
import '../../../features/medications/med_list_helpers.dart';
import 'mark_taken_action.dart';

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
        return _MedCard(
          med: m,
          onOpen: () => onOpen(m),
          onDelete: () => onDelete(m),
          takenToday: isTakenToday(m),
          markingTaken: isMarkingTaken(m),
          onMarkTaken: () => onMarkTaken(m),
        );
      },
    );
  }
}

class _MedCard extends StatelessWidget {
  final Medication med;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final bool takenToday;
  final bool markingTaken;
  final Future<void> Function() onMarkTaken;

  const _MedCard({
    required this.med,
    required this.onOpen,
    required this.onDelete,
    required this.takenToday,
    required this.markingTaken,
    required this.onMarkTaken,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stock = getStockStatus(med);
    final path = med.imagePath;

    return Material(
      color: MedListColors.card,
      elevation: 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: path == null
                      ? ColoredBox(
                          color: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.medication_outlined,
                            color: scheme.outline,
                          ),
                        )
                      : Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: scheme.outline,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            med.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _StatusPill(status: med.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      med.dosage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: MedListColors.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nextDoseLine(med),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: MedListColors.primaryColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: stockStatusColor(stock),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          stockStatusLabel(stock),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: stockStatusColor(stock),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        MarkTakenAction(
                          takenToday: takenToday,
                          busy: markingTaken,
                          onPressed: takenToday || markingTaken
                              ? null
                              : () => onMarkTaken(),
                        ),
                        TextButton(
                          onPressed: onDelete,
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.error,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = medicationStatusColor(status);
    final label = status == MedicationStatus.active
        ? 'Active'
        : status == MedicationStatus.hold
        ? 'Hold'
        : status == MedicationStatus.completed
        ? 'Done'
        : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w700),
      ),
    );
  }
}
