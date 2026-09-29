import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../decks/deck_list_screen.dart';
import '../providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  const _OnboardingPage({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _OnboardingPage(
    icon: Icons.style_outlined,
    title: 'Willkommen bei Memora',
    body: 'Leg eigene Vokabellisten an und lerne sie als Karteikarten – '
        'komplett offline, ganz ohne Internet.',
  ),
  _OnboardingPage(
    icon: Icons.schedule,
    title: 'Klug wiederholen statt raten',
    body: 'Nach jeder Karte bewertest du, wie gut du sie kanntest. '
        'Memora zeigt dir jede Vokabel dann genau dann wieder, '
        'wenn du sie sonst vergessen würdest.',
  ),
  _OnboardingPage(
    icon: Icons.rocket_launch_outlined,
    title: 'Los geht\'s',
    body: 'Leg dein erstes Deck an und fang an zu lernen.',
  ),
];

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon, size: 96, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.body,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Container(
                    margin: const EdgeInsets.all(4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _page == _pages.length - 1 ? _finish : _next,
                  child: Text(_page == _pages.length - 1 ? 'Los geht\'s' : 'Weiter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).setOnboardingComplete();
    if (!mounted) return;
    ref.invalidate(onboardingCompleteProvider);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DeckListScreen()),
    );
  }
}
