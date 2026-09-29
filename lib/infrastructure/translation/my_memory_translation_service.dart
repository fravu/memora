import 'dart:convert';

import 'package:http/http.dart' as http;

import 'translation_service.dart';

/// Kostenloser Uebersetzungsdienst ohne API-Key (mymemory.translated.net).
/// Qualitaet/Rate-Limits sind eingeschraenkt, ausreichend fuer eine
/// unverbindliche Uebersetzungs-Vermutung beim Vokabel-Anlegen.
class MyMemoryTranslationService implements TranslationService {
  MyMemoryTranslationService([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String?> translate(
    String text, {
    required String sourceLang,
    required String targetLang,
  }) async {
    final uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': text,
      'langpair': '$sourceLang|$targetLang',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;

    final responseData = decoded['responseData'];
    if (responseData is! Map<String, dynamic>) return null;

    final translated = responseData['translatedText'];
    return translated is String && translated.isNotEmpty ? translated : null;
  }
}
