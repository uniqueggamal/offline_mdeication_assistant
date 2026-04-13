import 'package:flutter/material.dart';

import '../../../data/models/medication.dart';
import '../../../data/models/medication_dose_slot.dart';
import '../../../features/medications/med_list_helpers.dart';
import 'mark_taken_action.dart';

/// Grouped sections with expand/collapse and compact medication rows.
class GroupedMedList extends StatelessWidget {
  final List<Medication> meds;
  final void Function(Medication med) onOpen;
  final void Function(Medication med) onDelete;
  final bool Function(Medication med) isTakenToday;
  final bool Function(Medication med) isMarkingTaken;
  final Future<void> Function(Medication med) onMarkTaken;

  const GroupedMedList({
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
    final grouped = groupMedications(meds);
    final entries = orderedGroupEntries(grouped);
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _GroupSection(
            title: entry.key,
            count: entry.value.length,
            children: [
              for (final m in entry.value)
                _GroupedMedRow(
                  med: m,
                  onOpen: () => onOpen(m),
                  onDelete: () => onDelete(m),
                  takenToday: isTakenToday(m),
                  markingTaken: isMarkingTaken(m),
                  onMarkTaken: () => onMarkTaken(m),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupSection extends StatelessWidget {
  final String title;
  final int count;
  final List<Widget> children;

  const _GroupSection({
    required this.title,
    required this.count,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: MedListColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: MedListColors.primaryColor,
                  ),
                ),
              ),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.medication_liquid,
                size: 18,
                color: MedListColors.primaryColor,
              ),
            ],
          ),
          children: children,
        ),
      ),
    );
  }
}

class _GroupedMedRow extends StatelessWidget {
  final Medication med;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final bool takenToday;
  final bool markingTaken;
  final Future<void> Function() onMarkTaken;

  const _GroupedMedRow({
    required this.med,
    required this.onOpen,
    required this.onDelete,
    required this.takenToday,
    required this.markingTaken,
    required this.onMarkTaken,
  });

  @override
  Widget build(BuildContext context) {
    final stock = getStockStatus(med);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: medicationStatusColor(med.status),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextDoseLine(med),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusDot(
                  label: med.status,
                  color: medicationStatusColor(med.status),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stockStatusColor(stock).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stockStatusLabel(stock),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: stockStatusColor(stock),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            MarkTakenAction(
              takenToday: takenToday,
              busy: markingTaken,
              onPressed: takenToday || markingTaken
                  ? null
                  : () => onMarkTaken(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final short = label == MedicationStatus.active
        ? 'Active'
        : label == MedicationStatus.hold
        ? 'Hold'
        : label == MedicationStatus.completed
        ? 'Done'
        : label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          short,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
