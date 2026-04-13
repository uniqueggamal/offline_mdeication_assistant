import 'package:flutter/material.dart';

import '../../../../data/models/medication.dart';
import 'package:intl/intl.dart';
import '../../../../features/medications/med_list_helpers.dart';

class TodayDoseList extends StatelessWidget {
  final List<DoseEvent> events;
  final Future<void> Function(DoseEvent event) onMarkTaken;

  const TodayDoseList({
    super.key,
    required this.events,
    required this.onMarkTaken,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = events[index];
        final med = event.medication;
        final timeStr = _formatTime(context, event.scheduledTime);
        final isPast = event.scheduledTime.isBefore(DateTime.now());
        final doseStr =
            '${event.dose} tablets • ${_mealLabel(event.medication)}';
        String buttonLabel = 'TAKE';
        IconData icon = Icons.check_circle_outline;
        if (event.isTaken) {
          buttonLabel = 'TAKEN';
          icon = Icons.check_circle;
        } else if (isPast) {
          buttonLabel = 'MISSED';
          icon = Icons.schedule;
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: MedListColors.cardBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MedListColors.primaryColor,
                          ),
                    ),
                    Text(
                      DateFormat('MMM dd').format(event.scheduledTime),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Med info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doseStr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action button
                if (!event.isTaken)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: SizedBox(
                      width: 100,
                      child: ElevatedButton.icon(
                        onPressed: isPast ? null : () => onMarkTaken(event),
                        icon: Icon(icon),
                        label: Text(buttonLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: event.isTaken
                              ? Colors.green
                              : isPast
                              ? Colors.grey
                              : MedListColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(BuildContext context, DateTime time) =>
      TimeOfDay.fromDateTime(time).format(context);

  String _mealLabel(Medication med) {
    if (med.doseSlots.isNotEmpty) {
      final slot = med.doseSlots.firstWhere(
        (s) => s.time == _timeFromDateTime(med.doseSlots.first.time),
        orElse: () => med.doseSlots.first,
      );
      if (slot.mealRelation == 'before_meal') return 'Before meal';
      if (slot.mealRelation == 'after_meal') return 'After meal';
    }
    return 'As scheduled';
  }

  String _timeFromDateTime(String hhmm) {
    return hhmm;
  }
}

class DoseEvent {
  final Medication medication;
  final DateTime scheduledTime;
  final int dose;
  final bool isTaken;

  DoseEvent({
    required this.medication,
    required this.scheduledTime,
    required this.dose,
    this.isTaken = false,
  });
}
