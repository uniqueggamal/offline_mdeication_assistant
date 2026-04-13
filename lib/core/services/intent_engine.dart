import '../../features/assistant/intent_parser.dart';

class IntentEngine {
  final IntentParser _parser;

  IntentEngine(this._parser);

  IntentResult process(String text) => _parser.detect(text);
}

