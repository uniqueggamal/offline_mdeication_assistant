class SpeechService {
  Future<void> init({String? modelPath}) async {
    // MVP: voice input is temporarily disabled on Android builds because
    // `vosk_flutter` fails with newer Android Gradle Plugin (missing namespace).
    // We'll re-enable voice with either a compatible Vosk plugin or a platform
    // channel wrapper in the next step.
    return;
  }

  Future<String?> listenOnce() async {
    // Not yet implemented.
    return null;
  }
}

