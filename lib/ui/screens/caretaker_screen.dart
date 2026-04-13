import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CaretakerScreen extends StatefulWidget {
  const CaretakerScreen({super.key});

  @override
  State<CaretakerScreen> createState() => _CaretakerScreenState();
}

class _CaretakerScreenState extends State<CaretakerScreen> {
  final _patientId = TextEditingController();
  String _linkedPatientId = '';
  bool _firebaseReady = false;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
      if (!mounted) return;
      setState(() => _firebaseReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _firebaseReady = false);
    }
  }

  @override
  void dispose() {
    _patientId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Caretaker (read-only)')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Link to a patient by user_id (invite code can be added next).',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _patientId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Patient user_id',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => setState(
                    () => _linkedPatientId = _patientId.text.trim(),
                  ),
                  child: const Text('View'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_firebaseReady)
              const Text(
                'Firebase is not configured yet on this device/build.\n'
                'Caretaker dashboard will work once Firebase config is added.',
              )
            else if (_linkedPatientId.isEmpty)
              const Text('Enter a patient user_id to view logs.')
            else
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_linkedPatientId)
                      .collection('logs')
                      .orderBy('timestamp', descending: true)
                      .limit(200)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Text('Error: ${snap.error}');
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('No logs found.'));
                    }
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final d = docs[i].data();
                        final ts = d['timestamp'];
                        DateTime? dt;
                        if (ts is Timestamp) dt = ts.toDate();
                        final title =
                            '${d['med_id'] ?? ''} • ${d['status'] ?? ''}';
                        final subtitle =
                            dt == null ? '' : fmt.format(dt.toLocal());
                        return ListTile(
                          title: Text(title.trim()),
                          subtitle: Text(subtitle),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

