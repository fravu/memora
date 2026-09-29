import 'package:csv/csv.dart';

import '../../domain/entities/vocab.dart';

/// Vokabel-Rohdaten aus einem CSV-Import, noch ohne deckId/id (die vergibt
/// erst das Repository beim Einfuegen).
class VocabDraft {
  const VocabDraft({
    required this.term,
    required this.translation,
    this.exampleSentence,
  });

  final String term;
  final String translation;
  final String? exampleSentence;
}

/// CSV-Format: term,translation,exampleSentence (mit Kopfzeile).
class VocabCsvCodec {
  static const header = ['term', 'translation', 'exampleSentence'];

  static String encode(List<Vocab> vocabs) {
    final rows = [
      header,
      for (final vocab in vocabs)
        [vocab.term, vocab.translation, vocab.exampleSentence ?? ''],
    ];
    return Csv().encode(rows);
  }

  static List<VocabDraft> decode(String csv) {
    if (csv.trim().isEmpty) return [];

    final rows = Csv().decode(csv);
    if (rows.isEmpty) return [];

    // Nur ueberspringen, wenn die ersten beiden Zellen exakt der Kopfzeile
    // entsprechen — sonst wuerde eine echte Vokabel "term" (z.B. Englisch
    // fuer "Begriff") faelschlich als Header erkannt und verworfen.
    var dataRows = rows;
    final firstRow = rows.first;
    final looksLikeHeader = firstRow.length >= 2 &&
        firstRow[0].toString().trim().toLowerCase() == 'term' &&
        firstRow[1].toString().trim().toLowerCase() == 'translation';
    if (looksLikeHeader) {
      dataRows = rows.skip(1).toList();
    }

    return [
      for (final row in dataRows)
        if (_isValidRow(row))
          VocabDraft(
            term: row[0].toString().trim(),
            translation: row[1].toString().trim(),
            exampleSentence: row.length > 2 && row[2].toString().trim().isNotEmpty
                ? row[2].toString().trim()
                : null,
          ),
    ];
  }

  static bool _isValidRow(List<dynamic> row) {
    return row.length >= 2 &&
        row[0].toString().trim().isNotEmpty &&
        row[1].toString().trim().isNotEmpty;
  }
}
