import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/log.dart';

class FirebaseService {
  bool _initialized = false;

  Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    try {
      await Firebase.initializeApp();
      _initialized = true;
      return true;
    } catch (_) {
      // No Firebase config present yet (google-services.json etc.)
      return false;
    }
  }

  Future<void> pushLog({
    required String userId,
    required MedicationLog log,
  }) async {
    final ok = await ensureInitialized();
    if (!ok) return;

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('logs')
        .doc(log.id);

    await doc.set({
      'id': log.id,
      'med_id': log.medId,
      'status': log.status,
      'timestamp': log.timestamp.toUtc(),
    }, SetOptions(merge: true));
  }
}

