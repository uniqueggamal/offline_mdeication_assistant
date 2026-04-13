import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OverflowSafeCard extends StatelessWidget {
  final String name;
  final String dosage;
  final String time;
  final String? mealRelation; // Optional, to save space if null
  final int currentStock;
  final int totalStock;
  final bool isTaken;
  final VoidCallback onTap;
  final VoidCallback onTake;

  final String? imagePath;

  const OverflowSafeCard({
    super.key,
    required this.name,
    required this.dosage,
    required this.time,
    this.mealRelation,
    required this.currentStock,
    required this.totalStock,
    required this.isTaken,
    required this.onTap,
    required this.onTake,
    this.imagePath,
  });

  Color get _stockColor {
    final ratio = currentStock / totalStock;
    if (ratio < 0.2) return AppTheme.error;
    if (ratio < 0.5) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ROW 1: Time and Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isTaken
                          ? AppTheme.primaryLight
                          : AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Interaction Button
                  Material(
                    color: isTaken ? Colors.grey.shade200 : AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: onTake,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTaken
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isTaken ? Colors.grey : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isTaken ? 'TAKEN' : 'TAKE',
                              style: TextStyle(
                                color: isTaken
                                    ? Colors.grey.shade600
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Image + Name/Details Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: imagePath == null
                        ? Colors.grey[300]!
                        : Colors.transparent,
                    backgroundImage: imagePath != null
                        ? AssetImage(imagePath!)
                        : null,
                    child: imagePath == null
                        ? const Icon(
                            Icons.medication_outlined,
                            color: Colors.grey,
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChip(dosage, Icons.medication),
                            if (mealRelation != null)
                              _buildChip(mealRelation!, Icons.restaurant),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ROW 4: Inventory Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '$currentStock / $totalStock left',
                        style: TextStyle(
                          fontSize: 12,
                          color: _stockColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalStock > 0 ? currentStock / totalStock : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_stockColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
