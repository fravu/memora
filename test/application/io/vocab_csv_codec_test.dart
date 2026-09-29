import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/io/vocab_csv_codec.dart';
import 'package:memora/domain/entities/vocab.dart';

void main() {
  group('encode', () {
    test('writes a header row followed by one row per vocab', () {
      final vocabs = [
        Vocab(
          id: 1,
          deckId: 1,
          term: 'Haus',
          translation: 'house',
          createdAt: DateTime(2026),
        ),
        Vocab(
          id: 2,
          deckId: 1,
          term: 'Katze',
          translation: 'cat',
          exampleSentence: 'Die Katze schläft.',
          createdAt: DateTime(2026),
        ),
      ];

      final csv = VocabCsvCodec.encode(vocabs);
      final decoded = VocabCsvCodec.decode(csv);

      expect(decoded, hasLength(2));
      expect(decoded[0].term, 'Haus');
      expect(decoded[0].translation, 'house');
      expect(decoded[0].exampleSentence, isNull);
      expect(decoded[1].exampleSentence, 'Die Katze schläft.');
    });
  });

  group('decode', () {
    test('skips a header row when present', () {
      final drafts = VocabCsvCodec.decode('term,translation,exampleSentence\nHaus,house,\n');
      expect(drafts, hasLength(1));
      expect(drafts.single.term, 'Haus');
    });

    test('works without a header row', () {
      final drafts = VocabCsvCodec.decode('Haus,house\nKatze,cat\n');
      expect(drafts, hasLength(2));
    });

    test('ignores rows missing a term or translation', () {
      final drafts = VocabCsvCodec.decode('Haus,house\n,missing term\nKatze,\n');
      expect(drafts, hasLength(1));
      expect(drafts.single.term, 'Haus');
    });

    test('returns an empty list for empty input', () {
      expect(VocabCsvCodec.decode(''), isEmpty);
      expect(VocabCsvCodec.decode('   '), isEmpty);
    });

    test('treats a blank example sentence as null', () {
      final drafts = VocabCsvCodec.decode('Haus,house,');
      expect(drafts.single.exampleSentence, isNull);
    });
  });
}
