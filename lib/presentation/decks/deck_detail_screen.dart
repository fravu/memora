import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/deck.dart';
import '../../domain/entities/vocab.dart';
import '../providers.dart';
import '../review/flashcard_screen.dart';

class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabsAsync = ref.watch(vocabsForDeckProvider(deck.id));

    return Scaffold(
      appBar: AppBar(title: Text(deck.name)),
      body: vocabsAsync.when(
        data: (vocabs) {
          if (vocabs.isEmpty) {
            return const Center(
              child: Text('Noch keine Vokabeln. Leg welche an!'),
            );
          }
          return ListView.builder(
            itemCount: vocabs.length,
            itemBuilder: (context, index) {
              final vocab = vocabs[index];
              return ListTile(
                title: Text(vocab.term),
                subtitle: Text(vocab.translation),
                onTap: () => _showEditDialog(context, ref, vocab),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      ref.read(vocabRepositoryProvider).deleteVocab(vocab.id),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'learn',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FlashcardScreen(deck: deck),
              ),
            ),
            icon: const Icon(Icons.school),
            label: const Text('Lernen'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showCreateDialog(context, ref),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final termController = TextEditingController();
    final translationController = TextEditingController();
    final exampleController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neue Vokabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: termController,
              decoration: const InputDecoration(labelText: 'Wort'),
            ),
            TextField(
              controller: translationController,
              decoration: const InputDecoration(labelText: 'Übersetzung'),
            ),
            TextField(
              controller: exampleController,
              decoration: const InputDecoration(
                labelText: 'Beispielsatz (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Anlegen'),
          ),
        ],
      ),
    );

    if (created == true &&
        termController.text.trim().isNotEmpty &&
        translationController.text.trim().isNotEmpty) {
      await ref.read(vocabRepositoryProvider).addVocab(
            deckId: deck.id,
            term: termController.text.trim(),
            translation: translationController.text.trim(),
            exampleSentence: exampleController.text.trim().isEmpty
                ? null
                : exampleController.text.trim(),
          );
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Vocab vocab,
  ) async {
    final termController = TextEditingController(text: vocab.term);
    final translationController =
        TextEditingController(text: vocab.translation);
    final exampleController =
        TextEditingController(text: vocab.exampleSentence ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vokabel bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: termController,
              decoration: const InputDecoration(labelText: 'Wort'),
            ),
            TextField(
              controller: translationController,
              decoration: const InputDecoration(labelText: 'Übersetzung'),
            ),
            TextField(
              controller: exampleController,
              decoration: const InputDecoration(
                labelText: 'Beispielsatz (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await ref.read(vocabRepositoryProvider).updateVocab(
            Vocab(
              id: vocab.id,
              deckId: vocab.deckId,
              term: termController.text.trim(),
              translation: translationController.text.trim(),
              exampleSentence: exampleController.text.trim().isEmpty
                  ? null
                  : exampleController.text.trim(),
              imageUrl: vocab.imageUrl,
              createdAt: vocab.createdAt,
            ),
          );
    }
  }
}
