class Vocab {
  const Vocab({
    required this.id,
    required this.deckId,
    required this.term,
    required this.translation,
    this.exampleSentence,
    this.imageUrl,
    required this.createdAt,
  });

  final int id;
  final int deckId;
  final String term;
  final String translation;
  final String? exampleSentence;
  final String? imageUrl;
  final DateTime createdAt;
}
