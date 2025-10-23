import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_speech/google_speech.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await testGoogleSTT();
}

Future<void> testGoogleSTT() async {
  try {
    // Load service account credentials
    final serviceAccountJson =
    await rootBundle.loadString('assets/credentials.json');
    final serviceAccount = ServiceAccount.fromString(serviceAccountJson);

    // Create the speech-to-text client using the new API
    final speechToText = SpeechToText.viaServiceAccount(serviceAccount);

    // Create a simple recognition config
    final config = RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      languageCode: 'en-US',
    );

    // Just test the configuration object — no audio needed
    print('✅ Google Speech API initialized successfully!');
    print('Language code: ${config.languageCode}');
  } catch (e) {
    print('❌ Error loading Google Speech credentials: $e');
  }
}
