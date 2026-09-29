import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memora/infrastructure/translation/my_memory_translation_service.dart';

void main() {
  test('sends the term and language pair, returns the translated text', () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'responseData': {'translatedText': 'house'},
        }),
        200,
      );
    });

    final service = MyMemoryTranslationService(client);
    final result = await service.translate('Haus', sourceLang: 'de', targetLang: 'en');

    expect(result, 'house');
    expect(requestedUri.host, 'api.mymemory.translated.net');
    expect(requestedUri.queryParameters['q'], 'Haus');
    expect(requestedUri.queryParameters['langpair'], 'de|en');
  });

  test('returns null on a non-200 response', () async {
    final client = MockClient((request) async => http.Response('error', 500));
    final service = MyMemoryTranslationService(client);

    final result = await service.translate('Haus', sourceLang: 'de', targetLang: 'en');

    expect(result, isNull);
  });

  test('returns null when the response has no translatedText', () async {
    final client = MockClient((request) async => http.Response(jsonEncode({}), 200));
    final service = MyMemoryTranslationService(client);

    final result = await service.translate('Haus', sourceLang: 'de', targetLang: 'en');

    expect(result, isNull);
  });
}
