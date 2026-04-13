import 'package:flutter/material.dart';

import '../../features/medications/medication_grouping.dart';

/// One selectable group in the picker (including synthetic ungrouped).
class MedicationGroupOption {
  final String id;
  final String title;
  final int? colorArgb;

  const MedicationGroupOption({
    required this.id,
    required this.title,
    this.colorArgb,
  });

  bool get isUngrouped => id == MedicationGrouping.ungroupedId;
}

/// Compact “Group ▾” control that opens a modal bottom sheet.
class MedicationGroupSelectorChip extends StatelessWidget {
  final String? selectedGroupId;
  final String displayLabel;
  final VoidCallback onTap;

  const MedicationGroupSelectorChip({
    super.key,
    required this.selectedGroupId,
    required this.displayLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Group',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                ' ▾',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showMedicationGroupPicker({
  required BuildContext context,
  required List<MedicationGroupOption> options,
  required String? selectedGroupId,
  required void Function(MedicationGroupOption option) onPick,
  required Future<void> Function() onCreateNew,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final effectiveSelected = (selectedGroupId == null || selectedGroupId.isEmpty)
      ? MedicationGrouping.ungroupedId
      : selectedGroupId;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Select group',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in options)
                    Builder(
                      builder: (context) {
                        final selected = o.id == effectiveSelected;
                        return ListTile(
                          selected: selected,
                          selectedTileColor:
                              scheme.primaryContainer.withValues(alpha: 0.35),
                          leading: o.colorArgb != null
                              ? CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Color(o.colorArgb!),
                                )
                              : Icon(
                                  o.isUngrouped
                                      ? Icons.folder_off_outlined
                                      : Icons.folder_outlined,
                                ),
                          title: Text(o.title),
                          trailing: selected
                              ? Icon(Icons.check_circle, color: scheme.primary)
                              : null,
                          onTap: () {
                            onPick(o);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.add, color: scheme.primary),
                    title: Text(
                      'Create new group',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await onCreateNew();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
