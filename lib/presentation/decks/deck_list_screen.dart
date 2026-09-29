import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/deck.dart';
import '../common/run_guarded.dart';
import '../providers.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import 'deck_detail_screen.dart';

typedef _DeckFormResult = ({String name, String sourceLang, String targetLang});

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Decks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistik',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: decksAsync.when(
        data: (decks) {
          if (decks.isEmpty) {
            return const Center(
              child: Text('Noch keine Decks. Leg eins an!'),
            );
          }
          return ListView.builder(
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return ListTile(
                title: Text(deck.name),
                subtitle: Text('${deck.sourceLang} → ${deck.targetLang}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DeckDetailScreen(deck: deck),
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'rename') {
                      await _showRenameDialog(context, ref, deck);
                    } else if (value == 'delete') {
                      await runGuarded(
                        context,
                        () => ref.read(deckRepositoryProvider).deleteDeck(deck.id),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Umbenennen')),
                    PopupMenuItem(value: 'delete', child: Text('Löschen')),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_DeckFormResult>(
      context: context,
      builder: (_) => const _DeckFormDialog(title: 'Neues Deck', confirmLabel: 'Anlegen'),
    );
    if (result == null) return;

    if (!context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(deckRepositoryProvider).createDeck(
            name: result.name,
            sourceLang: result.sourceLang,
            targetLang: result.targetLang,
          ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Deck deck,
  ) async {
    final result = await showDialog<_DeckFormResult>(
      context: context,
      builder: (_) => _DeckFormDialog(
        initialName: deck.name,
        initialSourceLang: deck.sourceLang,
        initialTargetLang: deck.targetLang,
        title: 'Deck umbenennen',
        confirmLabel: 'Speichern',
        showLanguageFields: false,
      ),
    );
    if (result == null) return;

    if (!context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(deckRepositoryProvider).renameDeck(deck.id, result.name),
    );
  }
}

/// Eigenes StatefulWidget statt lokal erzeugter TextEditingController im
/// Dialog-Aufrufer: showDialog liefert sein Ergebnis bereits waehrend die
/// Schliess-Animation noch laeuft, ein manuelles dispose() direkt danach
/// wuerde die Controller vorzeitig entsorgen ("used after being disposed").
/// Als State-Feld uebernimmt Flutter das Timing korrekt.
class _DeckFormDialog extends StatefulWidget {
  const _DeckFormDialog({
    required this.title,
    required this.confirmLabel,
    this.initialName = '',
    this.initialSourceLang = 'de',
    this.initialTargetLang = 'en',
    this.showLanguageFields = true,
  });

  final String title;
  final String confirmLabel;
  final String initialName;
  final String initialSourceLang;
  final String initialTargetLang;
  final bool showLanguageFields;

  @override
  State<_DeckFormDialog> createState() => _DeckFormDialogState();
}

class _DeckFormDialogState extends State<_DeckFormDialog> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _sourceController = TextEditingController(text: widget.initialSourceLang);
  late final _targetController = TextEditingController(text: widget.initialTargetLang);

  @override
  void dispose() {
    _nameController.dispose();
    _sourceController.dispose();
    _targetController.dispose();
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
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          if (widget.showLanguageFields) ...[
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(labelText: 'Ausgangssprache'),
            ),
            TextField(
              controller: _targetController,
              decoration: const InputDecoration(labelText: 'Zielsprache'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((
              name: name,
              sourceLang: _sourceController.text.trim(),
              targetLang: _targetController.text.trim(),
            ));
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
