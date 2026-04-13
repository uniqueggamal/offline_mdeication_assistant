import 'package:flutter/material.dart';

/// Mark-as-taken: outline + enabled when pending; filled + disabled after today’s log.
class MarkTakenAction extends StatelessWidget {
  final bool takenToday;
  final bool busy;
  final VoidCallback? onPressed;

  const MarkTakenAction({
    super.key,
    required this.takenToday,
    this.busy = false,
    this.onPressed,
  });

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _green),
        ),
      );
    }
    if (takenToday) {
      return IconButton(
        icon: const Icon(Icons.check_circle, color: _green),
        tooltip: 'Taken today',
        onPressed: null,
      );
    }
    return IconButton(
      icon: const Icon(Icons.check_circle_outline, color: _green),
      tooltip: 'Mark as taken',
      onPressed: onPressed,
    );
  }
}
