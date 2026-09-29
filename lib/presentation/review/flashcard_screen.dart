import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/deck.dart';
import '../../domain/entities/review_rating.dart';
import '../../domain/entities/vocab.dart';
import '../common/run_guarded.dart';
import '../providers.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key, required this.deck});

  final Deck deck;

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  bool _flipped = false;
  bool _rating = false;
  int? _lastVocabId;

  @override
  void initState() {
    super.initState();
    // Blendet die System-Navigationsleiste waehrend der Lern-Session aus,
    // damit sie die Bewertungsknoepfe am unteren Rand nicht mehr ueberdeckt.
    // Ein Wisch vom Rand holt sie bei Bedarf kurz zurueck.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vocabsAsync = ref.watch(dueVocabsForDeckProvider(widget.deck.id));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.deck.name} – Karten')),
      body: SafeArea(
        child: vocabsAsync.when(
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _flipped ? vocab.translation : vocab.term,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      tooltip: 'Vorlesen',
                      onPressed: () => _speak(vocab),
                    ),
                  ],
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
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: () => setState(() => _flipped = true),
        style: const ButtonStyle(
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 18)),
        ),
        child: const Text('Umdrehen'),
      ),
    );
  }

  Widget _buildRatingButtons(Vocab vocab) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ratingButton(
                'Wieder',
                Colors.red,
                () => _rate(vocab, ReviewRating.again),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ratingButton(
                'Schwer',
                Colors.orange,
                () => _rate(vocab, ReviewRating.hard),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ratingButton(
                'Gut',
                Colors.green,
                () => _rate(vocab, ReviewRating.good),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ratingButton(
                'Leicht',
                Colors.blue,
                () => _rate(vocab, ReviewRating.easy),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ratingButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: _rating ? null : onPressed,
        child: Text(label),
      ),
    );
  }

  Future<void> _rate(Vocab vocab, ReviewRating rating) async {
    // Verhindert, dass ein Doppel-Tap dieselbe Bewertung zweimal einreicht
    // (siehe Decision Log zur Stats-Race-Condition).
    if (_rating) return;
    setState(() => _rating = true);
    await runGuarded(
      context,
      () => ref.read(reviewVocabUseCaseProvider).call(vocab.id, rating),
    );
    if (!mounted) return;
    setState(() => _rating = false);
  }

  Future<void> _speak(Vocab vocab) async {
    final text = _flipped ? vocab.translation : vocab.term;
    final languageCode = _flipped ? widget.deck.targetLang : widget.deck.sourceLang;
    await runGuarded(
      context,
      () => ref.read(ttsServiceProvider).speak(text, languageCode: languageCode),
    );
  }
}
