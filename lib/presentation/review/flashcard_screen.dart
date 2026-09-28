import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/deck.dart';
import '../../domain/entities/review_rating.dart';
import '../../domain/entities/vocab.dart';
import '../providers.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key, required this.deck});

  final Deck deck;

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  bool _flipped = false;
  int? _lastVocabId;

  @override
  Widget build(BuildContext context) {
    final vocabsAsync = ref.watch(dueVocabsForDeckProvider(widget.deck.id));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.deck.name} – Karten')),
      body: vocabsAsync.when(
        data: (vocabs) {
          if (vocabs.isEmpty) {
            return const Center(
              child: Text('Keine fälligen Karten. Gut gemacht!'),
            );
          }

          final vocab = vocabs.first;
          if (vocab.id != _lastVocabId) {
            _lastVocabId = vocab.id;
            _flipped = false;
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('${vocabs.length} fällig'),
                const SizedBox(height: 16),
                Expanded(child: _buildCard(context, vocab)),
                const SizedBox(height: 16),
                if (_flipped) _buildRatingButtons(vocab) else _buildFlipButton(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Vocab vocab) {
    return GestureDetector(
      onTap: () => setState(() => _flipped = !_flipped),
      child: Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _flipped ? vocab.translation : vocab.term,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                if (_flipped && vocab.exampleSentence != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    vocab.exampleSentence!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Tippen zum Umdrehen',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlipButton() {
    return ElevatedButton(
      onPressed: () => setState(() => _flipped = true),
      child: const Text('Umdrehen'),
    );
  }

  Widget _buildRatingButtons(Vocab vocab) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ratingButton('Wieder', Colors.red, () => _rate(vocab, ReviewRating.again)),
        _ratingButton('Schwer', Colors.orange, () => _rate(vocab, ReviewRating.hard)),
        _ratingButton('Gut', Colors.green, () => _rate(vocab, ReviewRating.good)),
        _ratingButton('Leicht', Colors.blue, () => _rate(vocab, ReviewRating.easy)),
      ],
    );
  }

  Widget _ratingButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Future<void> _rate(Vocab vocab, ReviewRating rating) async {
    await ref.read(reviewVocabUseCaseProvider).call(vocab.id, rating);
  }
}
