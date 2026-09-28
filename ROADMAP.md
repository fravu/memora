# Memora – Roadmap

Basierend auf der Feature-Bewertung (siehe Chat-Verlauf / `ARCHITECTURE.md`) fokussiert
sich die Roadmap zuerst auf die Features mit **hohem Nutzen bei geringem–mittlerem
Aufwand**. Aufwändige Features (Cloud-Sync, Sprecherkennung, Community-Decks) sind
bewusst in eine spätere Phase verschoben.

Status-Legende: ⬜ offen · 🟨 in Arbeit · ✅ erledigt

## Phase 0 – Setup & Architektur (Fundament)
**Ziel:** Projekt lauffähig, Architektur & Datenmodell stehen.

- ✅ Flutter-Projekt anlegen (Android + iOS Target)
- ✅ Ordnerstruktur gemäß `ARCHITECTURE.md` aufsetzen
- ✅ Drift-DB einrichten, Tabellen `Deck`, `Vocab`, `CardProgress`, `StatsSnapshot`
- ✅ CI-Grundgerüst (Lint + Unit-Tests) einrichten
- ✅ Git-Repo initialisieren

**Deliverable:** Leere App startet auf Emulator/Simulator, DB-Migration läuft.
**Status:** Android-Build musste wegen zu geringem RAM (2.8GB) pausiert werden;
`org.gradle.jvmargs` wurde auf 2G/1G reduziert und Swap wird vom Nutzer vergrößert.
Ein tatsächlicher Geräte-/Emulator-Testlauf steht noch aus.

---

## Phase 1 – MVP Kernfunktionen
**Features:** #1 Flashcards, #3 eigene Decks, #11 Offline, #14 Kontextsätze
**Ziel:** Nutzer kann eigene Vokabellisten anlegen und als Karteikarten durchgehen.

- ⬜ Deck-CRUD (anlegen, umbenennen, löschen)
- ⬜ Vokabel-CRUD innerhalb eines Decks (Wort, Übersetzung, optional Beispielsatz)
- ⬜ Flashcard-Screen: Karte anzeigen → umdrehen → nächste Karte
- ⬜ Alles rein lokal (Drift), keine Netzwerkabhängigkeit

**Deliverable:** App ist ohne Internet nutzbar, eigene Listen erstellbar und abfragbar.
**Aufwand:** 🟢 Niedrig–Mittel

---

## Phase 2 – Lern-Engine (Spaced Repetition)
**Feature:** #2 SRS (SM-2)
**Ziel:** Karten werden nach Erfolgsquote intelligent wiederholt statt zufällig.

- ⬜ `SrsScheduler` (SM-2) als reine Dart-Klasse implementieren + Unit-Tests
- ⬜ `CardProgress`-Update nach jeder Bewertung (wieder/schwer/gut/leicht)
- ⬜ "Heute fällige Karten"-Abfrage als Haupt-Screen
- ⬜ Review-Session-Flow (Warteschlange fälliger Karten abarbeiten)

**Deliverable:** Tägliche Lern-Session mit spaced repetition funktioniert nachweisbar
(Testfall: Karte "leicht" bewertet → Intervall wächst; "wieder" → Intervall sinkt).
**Aufwand:** 🟡 Mittel (Algorithmus-Logik + Testabdeckung)

---

## Phase 3 – Engagement & Gewohnheit
**Features:** #6 TTS-Aussprache, #9 Gamification, #13 Push-Erinnerungen
**Ziel:** Nutzer bleibt dran (Motivation, Habit-Building).

- ⬜ TTS-Integration (`flutter_tts`) auf Flashcard- und Review-Screen
- ⬜ Streak-Zähler + `StatsSnapshot`-Fortschreibung
- ⬜ XP/Level-System für abgeschlossene Reviews (einfache Formel, kein Overengineering)
- ⬜ Statistik-Screen mit Streak, gelernten Wörtern, Erfolgsquote (fl_chart)
- ⬜ Lokale Push-Notification "Zeit zum Lernen" (konfigurierbare Uhrzeit)

**Deliverable:** App fühlt sich nach täglicher Lerngewohnheit an, nicht nur nach Tool.
**Aufwand:** 🟡 Mittel

---

## Phase 4 – Polish & Store-Release
**Ziel:** Veröffentlichungsreife für Play Store & App Store.

- ⬜ Onboarding-Flow (erstes Deck anlegen, kurze Erklärung SRS)
- ⬜ App-Icon, Splash Screen, Dark Mode
- ⬜ Fehlerbehandlung / Empty States (kein Deck, keine fälligen Karten)
- ⬜ Store-Metadaten (Screenshots, Beschreibung), Privacy-Policy (lokal-only → einfach)
- ⬜ Beta-Test (TestFlight / Play Internal Testing)

**Deliverable:** App ist im Play Store & App Store live.
**Aufwand:** 🟡 Mittel (viel Detailarbeit, wenig technisches Risiko)

---

## Phase 5 – Post-MVP-Erweiterungen (später, nicht im MVP-Scope)

| Feature | Aufwand | Voraussetzung |
|---|---|---|
| Cloud-Sync über Geräte (#12) | 🔴 Hoch | Backend + Auth nötig |
| Sprecherkennung/Pronunciation-Scoring (#7) | 🔴 Hoch | Speech-API/ML-Modell |
| Community/geteilte Decks (#17) | 🔴 Hoch | Backend, Moderation, Suche |
| Homescreen-Widget "Wort des Tages" (#16) | 🟡 Mittel | Native Widget-APIs pro Plattform |
| Auto-Übersetzung beim Anlegen (#18) | 🟡 Mittel | Externe Translate-API, Kosten/Limits |
| Import/Export (CSV, Anki-Format) (#10) | 🟡 Mittel | Parser pro Format |
| Bilder/Mnemonics (#8) | 🟡 Mittel | Bildquelle + Speicherverwaltung |

Diese werden erst nach validiertem MVP priorisiert, um Aufwand nicht in Features zu
stecken, bevor Kernnutzen (täglich Vokabeln lernen) bewiesen ist.

---

## Dokumentationsprinzip

Ab sofort gilt für dieses Projekt:
- Architektur- und Datenmodell-Änderungen → `ARCHITECTURE.md` (inkl. Decision Log)
- Fortschritt/Scope-Änderungen an der Roadmap → dieses Dokument, Status-Häkchen pflegen
- Diese Datei wird bei jedem Fortschritt aktualisiert (Status ⬜ → 🟨 → ✅), nicht nur am Ende
