import 'package:flutter/material.dart';
import '../../data/models/medication.dart';
import '../../data/models/medication_editor_result.dart';
import '../../features/medications/med_list_helpers.dart';
import '../../features/medications/medication_view_controller.dart';
import '../widgets/app_scope.dart';
import '../widgets/meds/card_med_list.dart';
import '../widgets/meds/grouped_med_list.dart';
import 'medication_editor_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  MedicationViewController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    _controller ??= MedicationViewController(
      db: scope.services.db,
      notifications: scope.services.notifications,
      userId: scope.userId,
    )..refresh();
  }

  Future<void> _openEditor({Medication? existing}) async {
    final outcome = await Navigator.push<MedicationEditorOutcome?>(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationEditorScreen(existing: existing),
      ),
    );
    if (outcome == null) return;
    if (outcome.deleted) {
      if (existing != null) await _controller!.deleteMedication(existing);
      return;
    }
    final saved = outcome.saved;
    if (saved != null) {
      await _controller!.upsertMedicationFromEditor(
        existing: existing,
        r: saved,
      );
    }
  }

  Future<void> _delete(Medication med) async {
    await _controller!.deleteMedication(med);
  }

  Future<void> _markTaken(Medication med) async {
    final r = await _controller!.markMedicationTaken(med);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (r) {
      case MarkTakenResult.ok:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Marked as taken'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case MarkTakenResult.duplicate:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Already marked taken today'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case MarkTakenResult.insufficientStock:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Not enough tablets remaining'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case MarkTakenResult.error:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not update medication'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  List<Medication> _sorted(List<Medication> meds) {
    final copy = List<Medication>.from(meds);
    copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return copy;
  }

  Widget _buildBody(
    MedicationViewState state,
    MedicationViewController controller,
  ) {
    if (state.medications.isEmpty) {
      return const Center(
        child: Text('No medications yet.\nTap + to add one.'),
      );
    }

    final meds = _sorted(state.medications);
    if (state.mode == MedViewMode.all) { return GroupedMedList(       meds: meds,
        onOpen: (m) => _openEditor(existing: m),
        onDelete: _delete,
        isTakenToday: (m) => state.takenMedIdsToday.contains(m.id),
        isMarkingTaken: (m) => controller.isMarkingTaken(m.id),
        onMarkTaken: _markTaken,
      );
    }
    return CardMedList(
      meds: meds,
      onOpen: (m) => _openEditor(existing: m),
      onDelete: _delete,
      isTakenToday: (m) => state.takenMedIdsToday.contains(m.id),
      isMarkingTaken: (m) => controller.isMarkingTaken(m.id),
      onMarkTaken: _markTaken,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: MedListColors.background,
      appBar: AppBar(
        title: const Text('Medications'),
        backgroundColor: MedListColors.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final isAllMode = controller.state.mode == MedViewMode.all;
                           return IconButton(
                                            tooltip: isAllMode ? 'Today' : 'All',
                                                            onPressed: controller.toggleViewMode,
                                                            icon: Icon(isAllMode ? Icons.timeline : Icons.view_list),
                                                                          );
            },
          ),
          IconButton(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
            tooltip: 'Add medication',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final state = controller.state;
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBody(state, controller);
        },
      ),
    );
  }
}
