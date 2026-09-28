import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/decks/deck_list_screen.dart';

void main() {
  runApp(const ProviderScope(child: MemoraApp()));
}

class MemoraApp extends StatelessWidget {
  const MemoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memora',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const DeckListScreen(),
    );
  }
}
