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

typedef _VocabFormResult = ({String term, String translation, String? exampleSentence});

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
    final result = await showDialog<_VocabFormResult>(
      context: context,
      builder: (_) => _VocabFormDialog(
        deck: deck,
        title: 'Neue Vokabel',
        confirmLabel: 'Anlegen',
      ),
    );
    if (result == null) return;

    if (!context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(vocabRepositoryProvider).addVocab(
            deckId: deck.id,
            term: result.term,
            translation: result.translation,
            exampleSentence: result.exampleSentence,
          ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Vocab vocab,
  ) async {
    final result = await showDialog<_VocabFormResult>(
      context: context,
      builder: (_) => _VocabFormDialog(
        deck: deck,
        initialTerm: vocab.term,
        initialTranslation: vocab.translation,
        initialExample: vocab.exampleSentence ?? '',
        title: 'Vokabel bearbeiten',
        confirmLabel: 'Speichern',
      ),
    );
    if (result == null) return;

    if (!context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(vocabRepositoryProvider).updateVocab(
            Vocab(
              id: vocab.id,
              deckId: vocab.deckId,
              term: result.term,
              translation: result.translation,
              exampleSentence: result.exampleSentence,
              imageUrl: vocab.imageUrl,
              createdAt: vocab.createdAt,
            ),
          ),
    );
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

      await ref.read(vocabRepositoryProvider).addVocabsBatch(
            deck.id,
            [
              for (final draft in drafts)
                (
                  term: draft.term,
                  translation: draft.translation,
                  exampleSentence: draft.exampleSentence,
                ),
            ],
          );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${drafts.length} Vokabeln importiert')),
      );
    });
  }
}

/// Eigenes StatefulWidget statt lokal erzeugter TextEditingController im
/// Dialog-Aufrufer: showDialog liefert sein Ergebnis bereits waehrend die
/// Schliess-Animation noch laeuft, ein manuelles dispose() direkt danach
/// wuerde die Controller vorzeitig entsorgen ("used after being disposed").
/// Als State-Feld uebernimmt Flutter das Timing korrekt.
class _VocabFormDialog extends ConsumerStatefulWidget {
  const _VocabFormDialog({
    required this.deck,
    required this.title,
    required this.confirmLabel,
    this.initialTerm = '',
    this.initialTranslation = '',
    this.initialExample = '',
  });

  final Deck deck;
  final String title;
  final String confirmLabel;
  final String initialTerm;
  final String initialTranslation;
  final String initialExample;

  @override
  ConsumerState<_VocabFormDialog> createState() => _VocabFormDialogState();
}

class _VocabFormDialogState extends ConsumerState<_VocabFormDialog> {
  late final _termController = TextEditingController(text: widget.initialTerm);
  late final _translationController =
      TextEditingController(text: widget.initialTranslation);
  late final _exampleController = TextEditingController(text: widget.initialExample);

  @override
  void dispose() {
    _termController.dispose();
    _translationController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _termController,
            decoration: const InputDecoration(labelText: 'Wort'),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _translationController,
                  decoration: const InputDecoration(labelText: 'Übersetzung'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.translate),
                tooltip: 'Automatisch übersetzen',
                onPressed: _autoTranslate,
              ),
            ],
          ),
          TextField(
            controller: _exampleController,
            decoration: const InputDecoration(labelText: 'Beispielsatz (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            final term = _termController.text.trim();
            final translation = _translationController.text.trim();
            if (term.isEmpty || translation.isEmpty) return;
            Navigator.of(context).pop((
              term: term,
              translation: translation,
              exampleSentence: _exampleController.text.trim().isEmpty
                  ? null
                  : _exampleController.text.trim(),
            ));
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  Future<void> _autoTranslate() async {
    final term = _termController.text.trim();
    if (term.isEmpty) return;

    await runGuarded(context, () async {
      final result = await ref.read(translationServiceProvider).translate(
            term,
            sourceLang: widget.deck.sourceLang,
            targetLang: widget.deck.targetLang,
          );
      if (result != null) {
        _translationController.text = result;
      }
    });
  }
}
