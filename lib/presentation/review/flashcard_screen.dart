import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/deck.dart';
import '../providers.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key, required this.deck});

  final Deck deck;

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  int _index = 0;
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final vocabsAsync = ref.watch(vocabsForDeckProvider(widget.deck.id));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.deck.name} – Karten')),
      body: vocabsAsync.when(
        data: (vocabs) {
          if (vocabs.isEmpty) {
            return const Center(
              child: Text('Keine Vokabeln in diesem Deck.'),
            );
          }
          if (_index >= vocabs.length) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Geschafft! Alle Karten durch.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _index = 0;
                      _flipped = false;
                    }),
                    child: const Text('Nochmal'),
                  ),
                ],
              ),
            );
          }

          final vocab = vocabs[_index];
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('${_index + 1} / ${vocabs.length}'),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
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
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                              if (_flipped &&
                                  vocab.exampleSentence != null) ...[
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
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _index++;
                    _flipped = false;
                  }),
                  child: const Text('Weiter'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
      ),
    );
  }
}
