import 'package:flutter/material.dart';
import '../../data/models/medication.dart';
import '../../features/medications/med_list_helpers.dart';
import '../../features/medications/medication_view_controller.dart';
import '../widgets/app_scope.dart';
import '../widgets/meds/overflow_safe_card.dart';
import '../theme/app_theme.dart';
import 'medication_editor_screen.dart';

class AllMedicationsScreen extends StatefulWidget {
  const AllMedicationsScreen({super.key});

  @override
  State<AllMedicationsScreen> createState() => _AllMedicationsScreenState();
}

class _AllMedicationsScreenState extends State<AllMedicationsScreen> {
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
    final outcome = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationEditorScreen(existing: existing),
      ),
    );
    if (outcome != null) _controller!.refresh();
  }

  Future<void> _delete(Medication med) async {
    await _controller!.deleteMedication(med);
  }

  Future<void> _markTaken(Medication med) async {
    await _controller!.markMedicationTaken(med);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "All Medications",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: "Search medicine...",
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Your Medications",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openEditor(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final state = controller.state;
              if (state.loading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final meds = state.medications;
              if (meds.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No medicines added",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final med = meds[index];
                  final time = nextDoseLine(med);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: OverflowSafeCard(
                      name: med.name,
                      dosage: med.dosage,
                      time: time,
                      mealRelation: med.doseSlots.isNotEmpty
                          ? med.doseSlots.first.mealRelation
                          : null,
                      currentStock: med.inventory.remainingTablets,
                      totalStock: med.inventory.totalTablets,
                      isTaken: state.takenMedIdsToday.contains(med.id),
                      imagePath: med.imagePath,
                      onTap: () => _openEditor(existing: med),
                      onTake: () => _markTaken(med),
                    ),
                  );
                }, childCount: meds.length),
              );
            },
          ),
        ],
      ),
    );
  }
}
