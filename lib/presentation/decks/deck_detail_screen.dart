import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/io/vocab_csv_codec.dart';
import '../../domain/entities/deck.dart';
import '../../domain/entities/vocab.dart';
import '../common/run_guarded.dart';
import '../providers.dart';
import '../review/flashcard_screen.dart';

class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabsAsync = ref.watch(vocabsForDeckProvider(deck.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportCsv(context, ref);
              } else if (value == 'import') {
                _importCsv(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Als CSV exportieren')),
              PopupMenuItem(value: 'import', child: Text('Aus CSV importieren')),
            ],
          ),
        ],
      ),
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
                  onPressed: () => runGuarded(
                    context,
                    () => ref.read(vocabRepositoryProvider).deleteVocab(vocab.id),
                  ),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: translationController,
                    decoration: const InputDecoration(labelText: 'Übersetzung'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.translate),
                  tooltip: 'Automatisch übersetzen',
                  onPressed: () => _autoTranslate(
                    context,
                    ref,
                    termController,
                    translationController,
                  ),
                ),
              ],
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
      if (!context.mounted) return;
      await runGuarded(
        context,
        () => ref.read(vocabRepositoryProvider).addVocab(
              deckId: deck.id,
              term: termController.text.trim(),
              translation: translationController.text.trim(),
              exampleSentence: exampleController.text.trim().isEmpty
                  ? null
                  : exampleController.text.trim(),
            ),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: translationController,
                    decoration: const InputDecoration(labelText: 'Übersetzung'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.translate),
                  tooltip: 'Automatisch übersetzen',
                  onPressed: () => _autoTranslate(
                    context,
                    ref,
                    termController,
                    translationController,
                  ),
                ),
              ],
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
      if (!context.mounted) return;
      await runGuarded(
        context,
        () => ref.read(vocabRepositoryProvider).updateVocab(
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
            ),
      );
    }
  }

  Future<void> _autoTranslate(
    BuildContext context,
    WidgetRef ref,
    TextEditingController termController,
    TextEditingController translationController,
  ) async {
    if (termController.text.trim().isEmpty) return;

    await runGuarded(context, () async {
      final result = await ref.read(translationServiceProvider).translate(
            termController.text.trim(),
            sourceLang: deck.sourceLang,
            targetLang: deck.targetLang,
          );
      if (result != null) {
        translationController.text = result;
      }
    });
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    await runGuarded(context, () async {
      final vocabs = await ref.read(vocabRepositoryProvider).watchVocabsForDeck(deck.id).first;
      final csv = VocabCsvCodec.encode(vocabs);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${deck.name}.csv');
      await file.writeAsString(csv);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Memora-Export: ${deck.name}'),
      );
    });
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    await runGuarded(context, () async {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      final path = files.isEmpty ? null : files.first.path;
      if (path == null) return;

      final content = await File(path).readAsString();
      final drafts = VocabCsvCodec.decode(content);

      final vocabRepository = ref.read(vocabRepositoryProvider);
      for (final draft in drafts) {
        await vocabRepository.addVocab(
          deckId: deck.id,
          term: draft.term,
          translation: draft.translation,
          exampleSentence: draft.exampleSentence,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${drafts.length} Vokabeln importiert')),
      );
    });
  }
}
