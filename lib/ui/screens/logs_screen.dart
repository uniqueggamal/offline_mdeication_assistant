import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/log.dart';
import '../../data/models/medication.dart';
import '../widgets/app_scope.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  bool _loading = true;
  List<MedicationLog> _logs = const [];
  Map<String, Medication> _medById = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    setState(() => _loading = true);
    final meds = await scope.services.db.listMedications(userId: scope.userId);
    final logs = await scope.services.db.listLogs(limit: 300);
    if (!mounted) return;
    setState(() {
      _medById = {for (final m in meds) m.id: m};
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs (offline)'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(child: Text('No logs yet.'))
          : ListView.separated(
              itemCount: _logs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final l = _logs[i];
                final medName = _medById[l.medId]?.name ?? l.medId;
                return ListTile(
                  title: Text('$medName • ${l.status}'),
                  subtitle: Text(fmt.format(l.timestamp)),
                  trailing: l.synced
                      ? const Icon(Icons.cloud_done, size: 18)
                      : const Icon(Icons.cloud_off, size: 18),
                );
              },
            ),
    );
  }
}

