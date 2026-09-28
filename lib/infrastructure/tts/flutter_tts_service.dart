import 'package:flutter_tts/flutter_tts.dart';

import 'tts_service.dart';

/// Mappt die simplen 2-Buchstaben-Sprachcodes aus dem Datenmodell
/// (z.B. "de", "en") auf volle TTS-Locales.
const _localeByLanguageCode = <String, String>{
  'de': 'de-DE',
  'en': 'en-US',
  'es': 'es-ES',
  'fr': 'fr-FR',
  'it': 'it-IT',
  'pt': 'pt-PT',
  'nl': 'nl-NL',
  'pl': 'pl-PL',
  'tr': 'tr-TR',
  'ru': 'ru-RU',
};

class FlutterTtsService implements TtsService {
  FlutterTtsService([FlutterTts? flutterTts]) : _tts = flutterTts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    final locale = _localeByLanguageCode[languageCode] ?? 'en-US';
    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }
}
