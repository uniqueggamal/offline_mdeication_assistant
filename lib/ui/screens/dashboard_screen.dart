import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/medication.dart';
import '../../features/medications/med_list_helpers.dart';
import '../../features/medications/medication_view_controller.dart';
import '../widgets/app_scope.dart';
import '../widgets/meds/overflow_safe_card.dart';
import '../widgets/dashboard_medication_card.dart';
import '../theme/app_theme.dart';
import 'medication_editor_screen.dart';
import 'all_medications_screen.dart';
import 'assistant_screen.dart';
import 'caretaker_screen.dart';
import 'logs_screen.dart';

class DoseEvent {
  final Medication med;
  final DateTime time;
  final int dose;

  DoseEvent({
    required this.med,
    required this.time,
    required this.dose,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MedicationViewController? _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DoseEvent> buildTodayDoseEvents(List<Medication> meds) {
    final now = DateTime.now();
    final List<DoseEvent> events = [];

    for (final med in meds) {
      if (med.status != 'active') continue;

      for (final slot in med.doseSlots) {
        final parts = slot.time.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final eventTime = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          );
          events.add(DoseEvent(
            med: med,
            time: eventTime,
            dose: parseTabletCount(slot.doseLabel),
          ));
        }
      }
    }

    events.sort((a, b) => a.time.compareTo(b.time));
    return events;
  }

  int findCurrentIndex(List<DoseEvent> events) {
    final now = DateTime.now();
    for (int i = 0; i < events.length; i++) {
      if (events[i].time.isAfter(now)) {
        return i;
      }
    }
    return events.length - 1;
  }

  int parseTabletCount(String label) {
    final m = RegExp(r'^(\d+)').firstMatch(label.trim());
    return m != null ? int.tryParse(m.group(1)!) ?? 1 : 1;
  }

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

  Future<void> _markTaken(Medication med) async {
    await _controller!.markMedicationTaken(med);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AssistantScreen()),
        ),
        backgroundColor: AppTheme.primary,
        child: const Icon(
          Icons.chat_bubble_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.account_circle, size: 32),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CaretakerScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 32),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LogsScreen()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      "How you feeling today?",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Search Bar
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
                    const SizedBox(height: 32),

                    // Upcoming Appointment Section
                    

                    // Today's Medicine Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Medicine",
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
                    const SizedBox(height: 16),

                    // Meds List
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, child) {
                        final state = controller.state;
                        if (state.loading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final stateMeds = state.medications;
                        if (stateMeds.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text('No medicines added'),
                              ],
                            ),
                          );
                        }

                        final events = buildTodayDoseEvents(state.medications);
                        print(events.map((e) => e.time).toList());

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final index = findCurrentIndex(events);
                          _scrollController.animateTo(
                            index * 180.0,
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        });

                        return Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.width ,
                              child: ListView.builder(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                itemCount: events.length,
                                itemBuilder: (context, index) {
                                  final event = events[index];
                                  final now = DateTime.now();
                                  final isPast = event.time.isBefore(now);

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Stack(
                                      children: [
                                        Opacity(
                                          opacity: isPast ? 0.6 : 1.0,
                                          child: DashboardMedicationCard(
                                            name: event.med.name,
                                            imagePath: event.med.imagePath,
                                            mealRelation: event.med.mealRelation,
                                            dosage: event.med.dosage ?? "${event.dose} tab",
                                            time: DateFormat('hh:mm a').format(event.time),
                                            isTaken: false,
                                            onTap: () => _openEditor(existing: event.med),
                                            onTake: () => _markTaken(event.med),
                                            remainingTabs: event.med.inventory.remainingTablets,
                                            tabletsPerDay: 1,
                                          ),
                                        ),
                                        if (isPast)
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                "Past",
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryLight,
                                  foregroundColor: AppTheme.primary,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AllMedicationsScreen(),
                                    ),
                                  );
                                },
                                child: const Text('See All'),
                              ),
                            ),
                            const Text(
                      "Upcoming Appointment",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dr. Danial Negi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Physiotherapist',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '11:30 AM',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: null, // View action
                                child: const Text('View'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
