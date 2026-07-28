import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  String? _currentLanguage;

  Future<void> init() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
    } catch (e) {
      // TTS init may fail on some platforms
    }
  }

  Future<void> speak(String text, String languageCode) async {
    try {
      final langMap = {
        'en': 'en-US',
        'tw': 'tw-GH',
        'ga': 'gaa-GH',
        'ew': 'ewe-GH',
        'ha': 'ha-NG',
        'da': 'dag-GH',
      };

      final ttsLang = langMap[languageCode] ?? 'en-US';
      await _tts.setLanguage(ttsLang);
      _currentLanguage = languageCode;
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      // TTS may not be available on all platforms
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      // ignore
    }
  }

  bool get isSpeaking => _isSpeaking;
  String? get currentLanguage => _currentLanguage;

  Future<void> dispose() async {
    await stop();
  }
}
