class MedicationLog {
  final String id;
  final String medId;
  final String status; // taken | missed
  final DateTime timestamp;
  final bool synced;
  final String? scheduledSlot;

  const MedicationLog({
    required this.id,
    required this.medId,
    required this.status,
    required this.timestamp,
    required this.synced,
    this.scheduledSlot,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'med_id': medId,
    'status': status,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'synced': synced ? 1 : 0,
    'scheduled_slot': scheduledSlot,
  };

  static MedicationLog fromMap(Map<String, Object?> map) {
    return MedicationLog(
      id: map['id'] as String,
      medId: map['med_id'] as String,
      status: map['status'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch((map['timestamp'] as int)),
      synced: (map['synced'] as int) == 1,
      scheduledSlot: map['scheduled_slot'] as String?,
    );
  }
}
