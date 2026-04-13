import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/medication.dart';
import '../../data/models/medication_dose_slot.dart';
import '../../data/models/medication_editor_result.dart';
import '../../features/medications/med_list_helpers.dart';
import '../../features/medications/medication_grouping.dart';
import '../widgets/app_scope.dart';
import '../widgets/medication_group_selector.dart';

class MedicationEditorScreen extends StatefulWidget {
  final Medication? existing;

  const MedicationEditorScreen({super.key, this.existing});

  @override
  State<MedicationEditorScreen> createState() => _MedicationEditorScreenState();
}

class _MedicationEditorScreenState extends State<MedicationEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  late final TextEditingController _name;
  late final TextEditingController _dosage;
  late final TextEditingController _instructions;
  late final TextEditingController _doctorNotes;
  late final TextEditingController _patientNotes;
  late final TextEditingController _totalTablets;

  int _dosePerDay = 1;
  TimeOfDay _firstDoseTime = const TimeOfDay(hour: 6, minute: 0);
  List<MedicationDoseSlot> _slots = [];
  bool _manualSlotTimes = false;

  String _defaultMeal = 'none';
  String _status = MedicationStatus.active;

  String? _imagePath;
  String? _groupId;
  String? _groupDisplayName;
  int? _groupColorArgb;

  int _total = 0;
  int _remaining = 0;

  bool _saving = false;
  bool _loadingGroups = true;
  List<MedicationGroupOption> _groupOptions = const [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _dosage = TextEditingController(
      text: e?.dosage.isNotEmpty == true ? e!.dosage : '1 tablet',
    );
    _instructions = TextEditingController(text: e?.instructions ?? '');
    _doctorNotes = TextEditingController(text: e?.doctorNotes ?? '');
    _patientNotes = TextEditingController(text: e?.patientNotes ?? '');

    _defaultMeal = e?.mealRelation ?? 'none';
    _status = e?.status ?? MedicationStatus.active;
    _dosePerDay = e?.dosePerDay ?? 1;
    if (_dosePerDay < 1) _dosePerDay = 1;
    _total = e?.inventory.totalTablets ?? 0;
    _remaining = e?.inventory.remainingTablets ?? _total;
    _totalTablets = TextEditingController(text: _total > 0 ? '$_total' : '');

    _imagePath = e?.imagePath;
    _groupId = e?.groupId?.trim().isNotEmpty == true ? e!.groupId : null;
    _groupDisplayName = (e?.scheduleRaw['group_name'] as String?)?.trim();
    if (_groupDisplayName != null && _groupDisplayName!.isEmpty) {
      _groupDisplayName = null;
    }
    final gc = e?.scheduleRaw['group_color'];
    if (gc is int) _groupColorArgb = gc;

    _slots = e != null && e.doseSlots.isNotEmpty
        ? List<MedicationDoseSlot>.from(e.doseSlots)
        : _generateEvenSlots(
            _dosePerDay,
            _dosage.text.trim().isEmpty ? '1 tablet' : _dosage.text.trim(),
          );

    _dosePerDay = _slots.length;

    _dosage.addListener(_onDosageTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingGroups) {
      _loadGroupOptions();
    }
  }

  Future<void> _loadGroupOptions() async {
    final scope = AppScope.of(context);
    try {
      final meds = await scope.services.db.listMedications(
        userId: scope.userId,
      );
      final groups = MedicationGrouping.group(meds);
      final opts = <MedicationGroupOption>[
        const MedicationGroupOption(
          id: MedicationGrouping.ungroupedId,
          title: 'Ungrouped',
        ),
        ...groups
            .where((g) => g.id != MedicationGrouping.ungroupedId)
            .map(
              (g) => MedicationGroupOption(
                id: g.id,
                title: g.title,
                colorArgb: _colorToArgb(g.color),
              ),
            ),
      ];
      if (!mounted) return;
      setState(() {
        _groupOptions = opts;
        _loadingGroups = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _groupOptions = const [
          MedicationGroupOption(
            id: MedicationGrouping.ungroupedId,
            title: 'Ungrouped',
          ),
        ];
        _loadingGroups = false;
      });
    }
  }

  int _colorToArgb(Color c) {
    final a = (c.a * 255.0).round() & 0xff;
    final r = (c.r * 255.0).round() & 0xff;
    final g = (c.g * 255.0).round() & 0xff;
    final b = (c.b * 255.0).round() & 0xff;
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  void _onDosageTextChanged() {
    if (_manualSlotTimes) return;
    final label = _dosage.text.trim().isEmpty
        ? '1 tablet'
        : _dosage.text.trim();
    setState(() {
      _slots = _slots
          .map((s) => s.copyWith(doseLabel: label))
          .toList(growable: false);
    });
  }

  @override
  void dispose() {
    _dosage.removeListener(_onDosageTextChanged);
    _name.dispose();
    _dosage.dispose();
    _instructions.dispose();
    _doctorNotes.dispose();
    _patientNotes.dispose();
    _totalTablets.dispose();
    _nameFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _regenerateFromEngine() {
    final label = _dosage.text.trim().isEmpty
        ? '1 tablet'
        : _dosage.text.trim();
    setState(() {
      _slots = _generateEvenSlots(_dosePerDay, label);
    });
  }

  List<MedicationDoseSlot> _generateEvenSlots(
    int dosesPerDay,
    String doseLabel,
  ) {
    final slots = <MedicationDoseSlot>[];
    final minutesPerDay = 24 * 60;
    final interval = minutesPerDay ~/ dosesPerDay;
    for (int i = 0; i < dosesPerDay; i++) {
      final offsetMinutes = i * interval;
      final hour = (360 + offsetMinutes) ~/ 60 % 24; // Start from 6AM (360 min)
      final minute = (360 + offsetMinutes) % 60;
      final timeStr =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      slots.add(
        MedicationDoseSlot(
          time: timeStr,
          doseLabel: doseLabel,
          mealRelation: _defaultMeal,
        ),
      );
    }
    return slots;
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parseTimeOfDay(String s) {
    final m = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(s.trim());
    if (m == null) return const TimeOfDay(hour: 8, minute: 0);
    return TimeOfDay(
      hour: int.parse(m.group(1)!),
      minute: int.parse(m.group(2)!),
    );
  }

  String _groupChipLabel() {
    if (_groupId == null || _groupId!.isEmpty) {
      return 'Ungrouped';
    }
    return (_groupDisplayName != null && _groupDisplayName!.isNotEmpty)
        ? _groupDisplayName!
        : _groupId!;
  }

  Future<void> _openGroupPicker() async {
    await showMedicationGroupPicker(
      context: context,
      options: _groupOptions,
      selectedGroupId: _groupId,
      onPick: (option) {
        setState(() {
          if (option.isUngrouped) {
            _groupId = null;
            _groupDisplayName = null;
            _groupColorArgb = null;
          } else {
            _groupId = option.id;
            _groupDisplayName = option.title;
            _groupColorArgb = option.colorArgb;
          }
        });
      },
      onCreateNew: _createNewGroup,
    );
  }

  Future<void> _createNewGroup() async {
    final nameCtrl = TextEditingController();
    final id = _uuid.v4();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New group'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Group name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final title = nameCtrl.text.trim();
      if (title.isEmpty) return;
      final color =
          Colors.primaries[id.hashCode.abs() % Colors.primaries.length];
      setState(() {
        _groupId = id;
        _groupDisplayName = title;
        _groupColorArgb = _colorToArgb(color);
        _groupOptions = [
          ..._groupOptions,
          MedicationGroupOption(
            id: id,
            title: title,
            colorArgb: _groupColorArgb,
          ),
        ];
      });
    } finally {
      nameCtrl.dispose();
    }
  }

  int _tabletsPerDay() => tabletsPerDayFromSlots(_slots);

  int _daysRemaining() {
    final tpd = _tabletsPerDay();
    if (tpd < 1 || _remaining < 1) return 0;
    return _remaining ~/ tpd;
  }

  Color _stockColor(ThemeData theme) {
    final days = _daysRemaining();
    if (days <= 1) return MedListColors.stockCritical;
    if (days <= 3) return MedListColors.stockLow;
    return MedListColors.stockSafe;
  }

  String _stockLabel() {
    final days = _daysRemaining();
    if (days <= 1) return 'Critical';
    if (days <= 3) return 'Low';
    return 'OK';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null) return;

    setState(() => _saving = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(dir.path, 'med_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ext = p.extension(xfile.path).isEmpty
          ? '.jpg'
          : p.extension(xfile.path);
      final id = widget.existing?.id ?? 'new';
      final outPath = p.join(
        imagesDir.path,
        'med_${id}_${DateTime.now().millisecondsSinceEpoch}$ext',
      );

      final copied = await File(xfile.path).copy(outPath);
      if (mounted) setState(() => _imagePath = copied.path);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _removeImage() => setState(() => _imagePath = null);

  Future<void> _pickFirstDoseTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _firstDoseTime,
    );
    if (t == null) return;
    setState(() {
      _firstDoseTime = t;
      if (!_manualSlotTimes) {
        _regenerateFromEngine();
      }
    });
  }

  Future<void> _confirmDelete() async {
    if (widget.existing == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medication?'),
        content: Text(
          'Remove "${widget.existing!.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, const MedicationEditorOutcome.deleted());
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    final dosage = _dosage.text.trim().isEmpty
        ? '1 tablet'
        : _dosage.text.trim();
    final total = int.tryParse(_totalTablets.text.trim()) ?? 0;
    var remaining = _remaining.clamp(0, total > 0 ? total : 0x7fffffff);
    if (widget.existing == null && total > 0 && remaining == 0) {
      remaining = total;
    }
    if (total > 0 && remaining > total) remaining = total;

    final inv = MedicationInventory(
      totalTablets: total < 0 ? 0 : total,
      remainingTablets: remaining < 0 ? 0 : remaining,
    );

    Navigator.pop(
      context,
      MedicationEditorOutcome.saved(
        MedicationEditorResult(
          name: name,
          dosage: dosage,
          dosePerDay: _slots.isEmpty ? 1 : _slots.length,
          firstDoseTime: _fmtTime(_firstDoseTime),
          doseSlots: List<MedicationDoseSlot>.from(_slots),
          manualSlotTimes: _manualSlotTimes,
          groupId: _groupId,
          groupDisplayName: _groupDisplayName,
          groupColorArgb: _groupColorArgb,
          imagePath: _imagePath,
          inventory: inv,
          status: _status,
          mealRelation: _defaultMeal,
          instructions: _instructions.text.trim(),
          doctorNotes: _doctorNotes.text.trim(),
          patientNotes: _patientNotes.text.trim(),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Material(
      color: MedListColors.card,
      elevation: 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isNew = widget.existing == null;

    return Scaffold(
      backgroundColor: MedListColors.background,
      appBar: AppBar(
        title: Text(isNew ? 'New Medication' : 'Edit Medication'),
        backgroundColor: MedListColors.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
          if (!isNew)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') _confirmDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Delete'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _buildHeader(theme, scheme, isNew),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _loadingGroups
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : MedicationGroupSelectorChip(
                              selectedGroupId: _groupId,
                              displayLabel: _groupChipLabel(),
                              onTap: _openGroupPicker,
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildDoseEngineCard(theme),
                    _buildInventoryCard(theme),
                    _sectionCard(
                      title: 'Default meal relation',
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'before_meal',
                              label: Text('Before food'),
                            ),
                            ButtonSegment(
                              value: 'after_meal',
                              label: Text('After food'),
                            ),
                            ButtonSegment(value: 'none', label: Text('None')),
                          ],
                          selected: {_defaultMeal},
                          onSelectionChanged: (s) {
                            final v = s.first;
                            setState(() {
                              _defaultMeal = v;
                              if (!_manualSlotTimes) {
                                _regenerateFromEngine();
                              } else {
                                _slots = _slots
                                    .map((e) => e.copyWith(mealRelation: v))
                                    .toList(growable: false);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    _sectionCard(
                      title: 'Notes & instructions',
                      children: [
                        TextFormField(
                          controller: _instructions,
                          decoration: const InputDecoration(
                            labelText: 'Instructions',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _doctorNotes,
                          decoration: const InputDecoration(
                            labelText: 'Doctor notes',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _patientNotes,
                          decoration: const InputDecoration(
                            labelText: 'Patient notes',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              Material(
                color: MedListColors.card,
                elevation: 1,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: MedListColors.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _saving ? null : _save,
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme scheme, bool isNew) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Material(
              color: MedListColors.card,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _saving ? null : _pickImage,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: _imagePath == null
                      ? Icon(
                          Icons.add_a_photo_outlined,
                          color: scheme.outline,
                          size: 48,
                        )
                      : ClipOval(
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: scheme.outline,
                              size: 48,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            if (_imagePath != null)
              Positioned(
                right: 0,
                top: 0,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _saving ? null : _removeImage,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    focusNode: _nameFocus,
                    controller: _name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Medication name',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit name',
                  onPressed: () => _nameFocus.requestFocus(),
                  icon: const Icon(Icons.edit_outlined),
                ),
                if (!isNew)
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    onSelected: (v) {
                      if (v == 'delete') _confirmDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: MedicationStatus.active,
                  label: const Text('Active'),
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: MedListColors.active,
                    size: 18,
                  ),
                ),
                ButtonSegment(
                  value: MedicationStatus.hold,
                  label: const Text('Hold'),
                  icon: Icon(
                    Icons.pause_circle_outline,
                    color: MedListColors.hold,
                    size: 18,
                  ),
                ),
                ButtonSegment(
                  value: MedicationStatus.completed,
                  label: const Text('Done'),
                  icon: Icon(
                    Icons.flag_outlined,
                    color: MedListColors.completed,
                    size: 18,
                  ),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoseEngineCard(ThemeData theme) {
    return _sectionCard(
      title: 'Dosage schedule',
      children: [
        Row(
          children: [
            Text('Doses per day', style: theme.textTheme.bodyLarge),
            const Spacer(),
            IconButton.filledTonal(
              onPressed: _dosePerDay <= 1 || _saving
                  ? null
                  : () {
                      setState(() {
                        _dosePerDay--;
                        _manualSlotTimes = false;
                        _regenerateFromEngine();
                      });
                    },
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$_dosePerDay',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: _dosePerDay >= 12 || _saving
                  ? null
                  : () {
                      setState(() {
                        _dosePerDay++;
                        _manualSlotTimes = false;
                        _regenerateFromEngine();
                      });
                    },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('First dose time'),
          subtitle: Text(_fmtTime(_firstDoseTime)),
          trailing: const Icon(Icons.schedule),
          onTap: _saving ? null : _pickFirstDoseTime,
        ),
        const Divider(height: 24),
        Text('Preview', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...List.generate(_slots.length, (i) {
          final slot = _slots[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      slot.time,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Dose: ${slot.doseLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      slot.mealRelation == 'before_meal'
                          ? 'Before'
                          : slot.mealRelation == 'after_meal'
                          ? 'After'
                          : 'None',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Edit individual times'),
          subtitle: Text(
            _manualSlotTimes
                ? 'Manual overrides on'
                : 'Uses auto spacing from doses per day',
            style: theme.textTheme.bodySmall,
          ),
          children: [
            ...List.generate(_slots.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                final initial = _parseTimeOfDay(_slots[i].time);
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: initial,
                                );
                                if (t == null) return;
                                setState(() {
                                  _manualSlotTimes = true;
                                  final nt = _fmtTime(t);
                                  _slots = List<MedicationDoseSlot>.from(_slots)
                                    ..[i] = _slots[i].copyWith(time: nt);
                                });
                              },
                        child: Text('Time ${_slots[i].time}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('meal_${i}_${_slots[i].mealRelation}'),
                        initialValue: _slots[i].mealRelation,
                        decoration: const InputDecoration(
                          labelText: 'Meal',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'before_meal',
                            child: Text('Before'),
                          ),
                          DropdownMenuItem(
                            value: 'after_meal',
                            child: Text('After'),
                          ),
                          DropdownMenuItem(value: 'none', child: Text('None')),
                        ],
                        onChanged: _saving
                            ? null
                            : (v) {
                                if (v == null) return;
                                setState(() {
                                  _manualSlotTimes = true;
                                  _slots = List<MedicationDoseSlot>.from(_slots)
                                    ..[i] = _slots[i].copyWith(mealRelation: v);
                                });
                              },
                      ),
                    ),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                        setState(() {
                          _manualSlotTimes = false;
                          _regenerateFromEngine();
                        });
                      },
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Reset to auto schedule'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dosage,
          decoration: const InputDecoration(
            labelText: 'Dose label (e.g. 1 tablet)',
            border: OutlineInputBorder(),
            helperText: 'Used in reminders and each schedule row',
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Dose label is required' : null,
        ),
      ],
    );
  }

  Widget _buildInventoryCard(ThemeData theme) {
    final days = _daysRemaining();
    final tpd = _tabletsPerDay();
    return _sectionCard(
      title: 'Inventory',
      children: [
        TextFormField(
          controller: _totalTablets,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Total tablets',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            final n = int.tryParse(_totalTablets.text.trim()) ?? 0;
            setState(() {
              final prev = _total;
              _total = n < 0 ? 0 : n;
              final delta = _total - prev;
              if (widget.existing == null && prev == 0 && _total > 0) {
                _remaining = _total;
              } else {
                _remaining = (_remaining + delta).clamp(
                  0,
                  _total > 0 ? _total : 0x7fffffff,
                );
              }
            });
          },
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '') ?? 0;
            if (n < 0) return 'Invalid';
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Remaining tablets',
                  border: OutlineInputBorder(),
                  helperText: 'Updates when doses are marked taken',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '$_remaining',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: _stockColor(theme),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Days remaining (est.): $days  ($tpd tab${tpd == 1 ? '' : 's'}/day)',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _stockColor(theme).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _stockColor(theme).withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _stockLabel(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _stockColor(theme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
