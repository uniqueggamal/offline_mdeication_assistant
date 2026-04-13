import 'intent_parser.dart';

class ResponseGenerator {
  String generate(IntentResult result, {String? schedulePreview}) {
    switch (result.intent) {
      case 'mark_taken':
        return 'ठिक छ, औषधि रेकर्ड गरियो';
      case 'missed':
        return 'औषधि छुट्यो, कृपया ध्यान दिनुहोस्';
      case 'ask_schedule':
        return schedulePreview == null || schedulePreview.isEmpty
            ? 'तपाईंको औषधि तालिका अनुसार...'
            : 'तपाईंको औषधि तालिका: $schedulePreview';
      default:
        return 'माफ गर्नुहोस्, मैले बुझिन। कृपया फेरि भन्नुहोस्।';
    }
  }
}

