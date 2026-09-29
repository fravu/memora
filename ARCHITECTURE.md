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
| 2026-09-29 | Kein separates `application/usecases` für reines CRUD in Phase 1 | Vermeidet Pass-Through-Boilerplate (Usecase ruft nur 1:1 Repository auf); die Schicht bleibt für echte Logik (SM-2-Scheduler, Review-Session-Orchestrierung) in Phase 2 reserviert |
| 2026-09-29 | Foreign-Key-Cascade-Delete (`onDelete: KeyAction.cascade`) auf `Vocabs.deckId` und `CardProgresses.vocabId`, plus `PRAGMA foreign_keys = ON` in `MigrationStrategy.beforeOpen` | Deck löschen soll automatisch Vokabeln + Lernstand mitlöschen, ohne das manuell in jedem Repository nachzubauen |
| 2026-09-29 | `addVocab` legt sofort eine `CardProgress`-Zeile an | Jede Vokabel ist ab Erstellung SRS-fähig (Phase 2), ohne nachträgliche Backfill-Migration |
| 2026-09-29 | Review-Session zeigt immer nur `vocabs.first` aus dem reaktiven "fällige Karten"-Stream statt einen manuellen Index zu pflegen | Nach einer Bewertung verschwindet die Karte automatisch aus dem Due-Stream (dueDate in der Zukunft) — kein manuelles Queue-Management nötig, Drift-Reaktivität übernimmt das |
| 2026-09-29 | Vereinfachte SM-2-Variante mit 4 Stufen (wieder/schwer/gut/leicht) statt der klassischen 0–5-Skala | Anki-Style ist für Endnutzer verständlicher; Kernidee (Ease-Factor, wachsendes Intervall) bleibt identisch zu SM-2 |
| 2026-09-29 | XP/Level/Streak rein aus `StatsSnapshot`-Historie abgeleitet (keine eigene XP-Spalte/Tabelle) | Kein Overengineering — ein Aggregations-Query reicht, keine zusätzliche Migration nötig |
| 2026-09-29 | `shared_preferences` statt Drift-Tabelle für die Erinnerungszeit | Für 2 einfache Werte (Stunde/Minute) ist eine eigene DB-Tabelle unverhältnismäßig; SharedPreferences ist der Flutter-Standardweg für simple Key-Value-Einstellungen |
| 2026-09-29 | Zeitzone für `flutter_local_notifications` aus `DateTime.now().timeZoneOffset` abgeleitet statt eigenem Geräte-Zeitzone-Plugin | Vermeidet eine zusätzliche Abhängigkeit nur für die Erinnerungsfunktion; Einschränkung: `Etc/GMT`-Zonen kennen keine Sommerzeit — bei DST-Wechsel verschiebt sich die Erinnerung bis zum nächsten App-Start um 1h |
| 2026-09-29 | `isCoreLibraryDesugaringEnabled` in `android/app/build.gradle.kts` aktiviert | Pflicht-Voraussetzung von `flutter_local_notifications`; ohne das schlägt der Android-Build fehl |
| 2026-09-29 | Gemeinsamer `runGuarded`-Helper statt einzelner try/catch pro Aufrufstelle | Wird 8× identisch gebraucht (alle Dialog-Aktionen + Review + Erinnerung) — eine kleine Abstraktion ist hier gerechtfertigt, keine Premature Abstraction |
| 2026-09-29 | Platzhalter-App-Icon programmatisch generiert (PIL, teal + "M"-Flashcard-Motiv) statt echtes Branding zu erfinden | Ermöglicht `flutter_launcher_icons`/`flutter_native_splash`-Setup jetzt schon, ohne einen finalen Icon-Entwurf vorzutäuschen; muss vor echtem Store-Release durch richtiges Branding ersetzt werden |
| 2026-09-29 | Release-Signing liest optional `android/key.properties` (Vorlage: `key.properties.example`), fällt ohne Datei auf Debug-Signing zurück | Lokale Release-Builds funktionieren sofort ohne Setup; echter Upload-Key kommt erst kurz vor Store-Submission dazu |
| 2026-09-29 | MyMemory Translation API (kostenlos, kein Key) statt DeepL/Google Translate | Nutzer-Entscheidung: kein API-Key-Setup nötig, App bleibt sofort nutzbar; Qualität/Rate-Limits sind der bewusste Kompromiss, später gegen DeepL tauschbar (Interface `TranslationService` entkoppelt das) |
| 2026-09-29 | `csv`-Package statt Handrolling für Import/Export | Robustes Escaping/Quoting (Kommas, Anführungszeichen in Vokabeln) ohne eigene Parser-Bugs |
| 2026-09-29 | Export nutzt `share_plus` (System-Share-Sheet) statt direktem Dateisystem-Schreibzugriff | Keine Storage-Permission-Komplexität; Nutzer entscheidet selbst, wohin die CSV-Datei geht |
| 2026-09-29 | `http`-Paket als direkte (nicht nur transitive) Abhängigkeit ergänzt | Wird direkt in `MyMemoryTranslationService` importiert — sollte nicht nur zufällig über eine andere Abhängigkeit verfügbar sein |
| 2026-09-29 | Vollständiges Code-Review über Phase 0–5 (per `/code-review --level high`), 7 Befunde behoben: `dueVocabsForDeckProvider` auf `autoDispose` umgestellt (eingefrorener Zeitpunkt), `recordReview` in eine Transaktion gewrappt + Unique-Constraint auf `StatsSnapshots.date` (Race Condition bei Doppel-Tap), CSV-Header-Erkennung verlangt jetzt beide Zellen statt nur `term` (Kollision mit echter Vokabel "term"), Erinnerungs-Zeitzone baut jetzt eine exakte Fixed-Offset-`Location` statt ganzstündiger `Etc/GMT`-Zone (Halbstunden-Zonen wie Indien UTC+5:30 vorher falsch), CSV-Import läuft jetzt über `addVocabsBatch` in einer Transaktion statt N Einzel-Inserts, `mounted`-Checks in `settings_screen.dart` vor jedem `setState` nach einem `await` ergänzt | Review-Prompt in der Session dokumentiert die konkreten Fehlerszenarien; alle Fixes durch Tests + Debug-Build verifiziert |
| 2026-09-29 | Dialog-Formulare (Deck/Vokabel anlegen/bearbeiten) zu eigenen `StatefulWidget`s (`_DeckFormDialog`, `_VocabFormDialog`) umgebaut statt TextEditingController lokal im aufrufenden Callback zu verwalten | Selbst verursachte Regression beim ersten Dispose-Fix: `showDialog` liefert sein Ergebnis bereits während die Schliess-Animation noch läuft, ein `finally { controller.dispose() }` direkt danach traf die Controller noch während des laufenden Closing-Frames ("used after being disposed", vom Testlauf aufgedeckt). Als State-Feld übernimmt Flutter das korrekte Dispose-Timing; reduziert nebenbei Duplikation zwischen Anlegen-/Bearbeiten-Dialogen |

*(Dieses Log wird bei jeder weiteren architektonisch relevanten Entscheidung ergänzt.)*
