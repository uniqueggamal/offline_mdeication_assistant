import 'dart:math';

class IntentResult {
  final String intent; // mark_taken | missed | ask_schedule | unknown
  final double confidence;
  final Map<String, String?> entities; // time, med_id (optional)

  const IntentResult({
    required this.intent,
    required this.confidence,
    required this.entities,
  });

  Map<String, Object?> toJson() => {
        'intent': intent,
        'confidence': confidence,
        'entities': entities,
      };
}

class IntentParser {
  String normalize(String input) {
    var s = input.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');

    // Common Nepali/English variants (MVP: simple replacement list).
    const replacements = <String, String>{
      'ausadhi': 'ausadi',
      'aushadhi': 'ausadi',
      'ausadi': 'ausadi',
      'khaye': 'khayo',
      'khaiyo': 'khayo',
      'khayen': 'khayo',
      'maile': 'ma',
      'i took': 'took',
      'taken': 'took',
      'missed it': 'missed',
    };
    for (final e in replacements.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    return s;
  }

  IntentResult detect(String raw) {
    final text = normalize(raw);

    // Very small fuzzy helper: match by "contains" plus token overlap score.
    double scoreContains(List<String> keywords) {
      if (keywords.any((k) => text.contains(k))) return 0.9;
      final tokens = text.split(' ').where((t) => t.isNotEmpty).toSet();
      if (tokens.isEmpty) return 0.0;
      final hits = keywords.where(tokens.contains).length;
      return min(0.8, hits / max(1, keywords.length));
    }

    final takenScore = scoreContains([
      'khayo',
      'took',
      'liye',
      'khai',
      'medicine taken',
      'ausadi khayo',
    ]);
    final missedScore = scoreContains([
      'missed',
      'chutyo',
      'birsiye',
      'skip',
      'chhutyo',
    ]);
    final scheduleScore = scoreContains([
      'schedule',
      'time',
      'kahile',
      'kaile',
      'talika',
      'table',
      'when',
    ]);

    final best = <String, double>{
      'mark_taken': takenScore,
      'missed': missedScore,
      'ask_schedule': scheduleScore,
    }.entries.reduce((a, b) => a.value >= b.value ? a : b);

    if (best.value < 0.45) {
      return const IntentResult(
        intent: 'unknown',
        confidence: 0.2,
        entities: {'time': null, 'med_id': null},
      );
    }

    return IntentResult(
      intent: best.key,
      confidence: best.value,
      entities: {'time': _extractTime(text), 'med_id': null},
    );
  }

  String? _extractTime(String text) {
    // MVP time extraction: 08:30 style.
    final m = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b').firstMatch(text);
    if (m == null) return null;
    return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}';
  }
}

