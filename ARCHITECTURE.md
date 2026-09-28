# Memora – Architektur

Vokabeltrainer-App für Android & iOS. Dieses Dokument beschreibt Tech-Stack, Modulaufbau
und Datenmodell für die in der Roadmap definierten High-Value-Features:
Flashcards, Spaced Repetition (SRS), eigene Decks, TTS-Aussprache, Gamification,
Offline-Modus, Push-Erinnerungen, Kontextsätze.

## 1. Tech-Stack

| Bereich | Wahl | Begründung |
|---|---|---|
| Cross-Platform-Framework | **Flutter (Dart)** | Ein Codebase für Android+iOS, gute Offline-DB-Anbindung, native TTS/Notification-Plugins vorhanden, gutes Widget-Ökosystem für spätere Homescreen-Widgets |
| Lokale Datenbank | **Drift** (SQLite-Wrapper für Dart) | Typsicher, generiert Queries, gut für relationales Modell (Deck ↔ Vokabel ↔ Lernstand) |
| State Management | **Riverpod** | Testbar, wenig Boilerplate, gute Trennung UI/Logik |
| Text-to-Speech | **flutter_tts** | Nutzt native OS-TTS (Android/iOS), keine Cloud-Kosten, funktioniert offline |
| Notifications | **flutter_local_notifications** | Lokale Erinnerungen ohne Backend nötig |
| Charts/Statistiken | **fl_chart** | Für Fortschrittsgrafiken (Streak, Lernkurve) |
| Ordner/Bilder für Mnemonics (später) | lokaler Cache + optionale Bild-API | erst Phase 4+ |

**Alternative geprüft:** React Native – verworfen, da Flutters SQLite/Drift-Tooling und
native-Plugin-Reife (TTS, Notifications) für dieses Use-Case aktuell runder ist.

## 2. Architektur-Schichten (Clean Architecture, vereinfacht)

```
┌─────────────────────────────────────────┐
│  Presentation (Flutter Widgets, Screens) │  ← UI, Riverpod-Consumer
├─────────────────────────────────────────┤
│  Application (Use Cases)                 │  ← z.B. ReviewSessionUseCase,
│                                            │     CreateDeckUseCase, SrsScheduler
├─────────────────────────────────────────┤
│  Domain (Entities, Interfaces)            │  ← Deck, Vocab, CardProgress
├─────────────────────────────────────────┤
│  Data (Repositories, Drift DAOs)          │  ← DeckRepository, VocabRepository
├─────────────────────────────────────────┤
│  Infrastructure (Plattform-Services)      │  ← TtsService, NotificationService,
│                                            │     (später) SyncService
└─────────────────────────────────────────┘
```

Grundregel: Presentation kennt nur Use Cases, Use Cases kennen nur Domain-Interfaces.
Das hält den SRS-Algorithmus und das Datenmodell unabhängig vom UI-Framework testbar.

## 3. Datenmodell (lokal, SQLite via Drift)

```
Deck
├─ id (pk)
├─ name
├─ sourceLang        (z.B. "de")
├─ targetLang         (z.B. "en")
└─ createdAt

Vocab
├─ id (pk)
├─ deckId (fk → Deck)
├─ term                (Ausgangswort)
├─ translation
├─ exampleSentence     (nullable, Feature #14)
├─ imageUrl            (nullable, spätere Mnemonic-Funktion)
└─ createdAt

CardProgress            (SRS-Zustand pro Vokabel, Feature #2)
├─ id (pk)
├─ vocabId (fk → Vocab, unique)
├─ easeFactor           (SM-2, Start 2.5)
├─ intervalDays
├─ repetitions
├─ dueDate
└─ lastReviewedAt

StatsSnapshot            (Feature #5/#9, Gamification & Statistiken)
├─ id (pk)
├─ date
├─ cardsReviewed
├─ correctCount
└─ streakDay
```

Beziehungen: `Deck 1—n Vocab`, `Vocab 1—1 CardProgress`.
`StatsSnapshot` wird täglich fortgeschrieben (Streak-Berechnung).

## 4. SRS-Algorithmus (Feature #2)

Verwendet wird **SM-2** (SuperMemo-2), da gut dokumentiert und deterministisch testbar:

1. Nutzer bewertet Karte nach Anzeige: `wieder / schwer / gut / leicht` (analog Anki).
2. `easeFactor` wird je nach Bewertung angepasst (min. 1.3).
3. `intervalDays` wird aus `easeFactor` und `repetitions` neu berechnet.
4. `dueDate = heute + intervalDays`.
5. Abfrage täglich: `SELECT * FROM CardProgress WHERE dueDate <= heute`.

Die Implementierung liegt als reine Dart-Funktion in der Application-Schicht
(`SrsScheduler`), unabhängig von UI und DB → einfach unit-testbar.

## 5. Modul-/Ordnerstruktur (Vorschlag)

```
lib/
├─ domain/
│   ├─ entities/        (Deck, Vocab, CardProgress)
│   └─ repositories/    (Interfaces)
├─ application/
│   ├─ srs/             (SrsScheduler, SM-2 Logik)
│   └─ usecases/        (CreateDeck, ReviewSession, ...)
├─ data/
│   ├─ drift/           (Tables, DAOs, Migrations)
│   └─ repositories_impl/
├─ infrastructure/
│   ├─ tts/
│   └─ notifications/
└─ presentation/
    ├─ decks/
    ├─ review/           (Karten-Abfrage-Screen)
    ├─ stats/
    └─ settings/
```

## 6. Offline-first-Prinzip (Feature #11)

Alles läuft primär gegen die lokale SQLite-DB. Es gibt in der MVP-Phase **kein Backend**.
Das hält Architektur und Aufwand niedrig und erfüllt Offline-Fähigkeit automatisch.
Cloud-Sync (Feature #12) ist bewusst als spätere, optionale Erweiterung geplant (siehe
`ROADMAP.md`, Phase 5) und würde eine zusätzliche Sync-Schicht + Backend/Auth erfordern.

## 7. Decision Log

| Datum | Entscheidung | Begründung |
|---|---|---|
| 2026-09-28 | Flutter statt React Native | Bessere native TTS/Notification-Reife, typsicheres Drift-ORM |
| 2026-09-28 | Drift (SQLite) statt Cloud-DB für MVP | Offline-first, kein Backend-Aufwand in MVP nötig |
| 2026-09-28 | SM-2 als SRS-Algorithmus | Gut dokumentiert, deterministisch, einfach testbar |
| 2026-09-28 | Riverpod als State Management | Testbarkeit, geringe Boilerplate |

*(Dieses Log wird bei jeder weiteren architektonisch relevanten Entscheidung ergänzt.)*
