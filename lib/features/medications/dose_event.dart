import '../../../data/models/medication.dart';

class DoseEvent {
  final Medication medication;
  final DateTime scheduledTime;
  final int dose;
  final bool isTaken;

  const DoseEvent({
    required this.medication,
    required this.scheduledTime,
    required this.dose,
    required this.isTaken,
  });
}
