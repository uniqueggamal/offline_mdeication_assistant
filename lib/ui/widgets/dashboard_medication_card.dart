import 'package:flutter/material.dart';
import 'dart:io';
import '../../../ui/theme/app_theme.dart';

class DashboardMedicationCard extends StatelessWidget {
  final String name;
  final String? imagePath;
  final String mealRelation;
  final String dosage;
  final String time;
  final bool isTaken;
  final VoidCallback onTap;
  final VoidCallback onTake;
  final int? remainingTabs;
  final int tabletsPerDay;

  const DashboardMedicationCard({
    super.key,
    required this.name,
    this.imagePath,
    required this.mealRelation,
    required this.dosage,
    this.remainingTabs,
    required this.tabletsPerDay,
    required this.time,
    required this.isTaken,
    required this.onTap,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.7;
    final scrollWidth = cardWidth * 1.4;

    final daysLeft = remainingTabs != null && tabletsPerDay > 0
        ? (remainingTabs! / tabletsPerDay)
        : 0;

    Color stockColor;
    String stockMessage = "";

    if (remainingTabs == 0) {
      stockColor = Colors.red;
      stockMessage = "Out of stock";
    } else if (daysLeft <= 3) {
      stockColor = Colors.red.shade400;
      stockMessage = "Low stock";
    } else if (daysLeft <= 7) {
      stockColor = Colors.orange;
    } else {
      stockColor = Colors.green;
    }

    return SizedBox(
      width: cardWidth,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  height: screenWidth * 0.5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(imagePath!),
                            fit: BoxFit.cover,
                            height: screenWidth * 0.5,
                            width: double.infinity,
                          ),
                        )
                      : Icon(
                          Icons.medication_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                ),
                const SizedBox(height: 8),
                // Name scroll
                SizedBox(
                  height: 24,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: scrollWidth,
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Meal + Dosage (separate)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mealRelation,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dosage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Stock
                if (remainingTabs != null) ...[
                  Text(
                    "${remainingTabs!} tabs left${stockMessage.isNotEmpty ? " • $stockMessage" : ""}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: stockColor,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Time & Take
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Material(
                      color: isTaken ? Colors.grey.shade200 : AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: onTake,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            isTaken ? 'TAKEN' : 'TAKE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isTaken ? Colors.grey : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

