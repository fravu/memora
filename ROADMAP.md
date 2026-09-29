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
**Status:** ✅ Debug-APK-Build erfolgreich (`flutter build apk --debug`), nach RAM-Erhöhung
auf ~4.7GB und Reduzierung von `org.gradle.jvmargs` auf 2G/1G. `flutter analyze` und alle
Unit-Tests laufen grün. **Phase 0 abgeschlossen.**

---

## Phase 1 – MVP Kernfunktionen ✅
**Features:** #1 Flashcards, #3 eigene Decks, #11 Offline, #14 Kontextsätze
**Ziel:** Nutzer kann eigene Vokabellisten anlegen und als Karteikarten durchgehen.

- ✅ Deck-CRUD (anlegen, umbenennen, löschen)
- ✅ Vokabel-CRUD innerhalb eines Decks (Wort, Übersetzung, optional Beispielsatz)
- ✅ Flashcard-Screen: Karte anzeigen → umdrehen → nächste Karte
- ✅ Alles rein lokal (Drift), keine Netzwerkabhängigkeit

**Deliverable:** App ist ohne Internet nutzbar, eigene Listen erstellbar und abfragbar.
**Aufwand:** 🟢 Niedrig–Mittel
**Status:** Auf echtem Android-Gerät getestet (APK per lokalem HTTP-Server übertragen,
kein USB/Emulator nötig) — Deck anlegen, Vokabeln pflegen und Flashcards durchgehen
funktionieren. Cascade-Delete (Deck löschen → Vokabeln + Lernstand mitgelöscht) ist
per SQLite-Foreign-Keys abgesichert und getestet.

---

## Phase 2 – Lern-Engine (Spaced Repetition) ✅
**Feature:** #2 SRS (SM-2)
**Ziel:** Karten werden nach Erfolgsquote intelligent wiederholt statt zufällig.

- ✅ `SrsScheduler` (SM-2) als reine Dart-Klasse implementiert + 16 Unit-Tests
- ✅ `CardProgress`-Update nach jeder Bewertung (wieder/schwer/gut/leicht)
- ✅ "Fällige Karten"-Abfrage (Join Vocabs+CardProgresses, dueDate <= jetzt)
- ✅ Review-Session-Flow: Flashcard-Screen zeigt jeweils die fälligste Karte,
  4 Bewertungsknöpfe, Liste aktualisiert sich reaktiv nach jeder Bewertung

**Deliverable:** Tägliche Lern-Session mit spaced repetition funktioniert nachweisbar
(Testfall: Karte "leicht" bewertet → Intervall wächst; "wieder" → Intervall sinkt).
**Aufwand:** 🟡 Mittel (Algorithmus-Logik + Testabdeckung)

---

## Phase 3 – Engagement & Gewohnheit ✅
**Features:** #6 TTS-Aussprache, #9 Gamification, #13 Push-Erinnerungen
**Ziel:** Nutzer bleibt dran (Motivation, Habit-Building).

- ✅ TTS-Integration (`flutter_tts`) auf dem Flashcard-Screen (Lautsprecher-Icon,
  spricht Vorder-/Rückseite in der jeweiligen Deck-Sprache)
- ✅ Streak-Zähler + `StatsSnapshot`-Fortschreibung (pro Review, mit Tages-Upsert)
- ✅ XP/Level-System (10 XP richtig / 2 XP falsch, alle 100 XP ein Level)
- ✅ Statistik-Screen mit Streak, Level/XP-Fortschritt, Erfolgsquote, 7-Tage-Balkendiagramm (fl_chart)
- ✅ Lokale Erinnerung (`flutter_local_notifications`) mit wählbarer Uhrzeit in den Einstellungen

**Deliverable:** App fühlt sich nach täglicher Lerngewohnheit an, nicht nur nach Tool.
**Aufwand:** 🟡 Mittel
**Status:** Debug-APK-Build erfolgreich (musste `isCoreLibraryDesugaringEnabled`
für `flutter_local_notifications` aktivieren). 18 zusätzliche Tests (Unit + Widget)
für XP-Formel, Streak-Logik und die drei neuen/geänderten Screens.

---

## Phase 4 – Polish & Store-Release-Vorbereitung 🟨
**Ziel:** Veröffentlichungsreife für Play Store & App Store.

- ✅ Onboarding-Flow (3 Seiten: Begrüßung, SRS-Erklärung, Los geht's → Deck-Liste)
- ✅ App-Icon (Platzhalter, generiert), Splash Screen (`flutter_native_splash`), Dark Mode (`ThemeMode.system`)
- ✅ Fehlerbehandlung: alle Repository-Aufrufe aus der UI laufen über `runGuarded`
  (zeigt Fehler als SnackBar statt Absturz); Empty States waren bereits seit
  Phase 1–3 auf allen Screens vorhanden
- ✅ Store-Metadaten-Entwürfe (`store/play_store_listing.md`, `store/app_store_listing.md`,
  `store/privacy_policy.md`) und Signing-Config-Vorlage (`android/key.properties.example`)
- ⬜ **Bewusst nicht erledigt:** Beta-Test (TestFlight/Play Internal Testing) und
  tatsächliche Store-Submission — erfordert deine Play-Console-/Apple-Developer-Accounts,
  Zahlungsdaten und für iOS einen Mac mit Xcode (nicht von dieser Linux-Umgebung aus möglich).
  Bleibt ein expliziter, gemeinsamer Schritt.

**Deliverable:** App ist im Play Store & App Store live.
**Aufwand:** 🟡 Mittel (viel Detailarbeit, wenig technisches Risiko)
**Offene TODOs vor echter Veröffentlichung:** echtes App-Icon/Branding statt
Platzhalter, Screenshots, gehostete Privacy-Policy-URL, iOS-Build auf einem Mac,
Upload-Keystore erzeugen (`android/key.properties.example` → `key.properties`).

---

## Phase 5 – Post-MVP-Erweiterungen

| Feature | Aufwand | Status |
|---|---|---|
| Auto-Übersetzung beim Anlegen (#18) | 🟡 Mittel | ✅ Erledigt — MyMemory API (kostenlos, kein Key), Button im Anlegen-/Bearbeiten-Dialog |
| Import/Export (CSV) (#10) | 🟡 Mittel | ✅ Erledigt — CSV-Export via Share-Sheet, Import via Dateiauswahl, im Deck-Menü |
| Cloud-Sync über Geräte (#12) | 🔴 Hoch | Offen — Backend + Auth nötig |
| Sprecherkennung/Pronunciation-Scoring (#7) | 🔴 Hoch | Offen — Speech-API/ML-Modell |
| Community/geteilte Decks (#17) | 🔴 Hoch | Offen — Backend, Moderation, Suche |
| Homescreen-Widget "Wort des Tages" (#16) | 🟡 Mittel | Offen — Native Widget-APIs pro Plattform |
| Anki-Format-Import (statt nur CSV) | 🟡 Mittel | Offen — .apkg ist ein SQLite-in-ZIP-Format, eigener Parser nötig |
| Bilder/Mnemonics (#8) | 🟡 Mittel | Offen — Bildquelle + Speicherverwaltung |

**CSV-Format:** `term,translation,exampleSentence` mit Kopfzeile (Kopfzeile beim
Import optional — wird automatisch erkannt). Export nutzt das System-Share-Sheet,
damit der Nutzer selbst wählt, wohin die Datei geht (Downloads, Cloud, andere App).

Die verbleibenden Punkte werden erst bei Bedarf priorisiert.

---

## Dokumentationsprinzip

Ab sofort gilt für dieses Projekt:
- Architektur- und Datenmodell-Änderungen → `ARCHITECTURE.md` (inkl. Decision Log)
- Fortschritt/Scope-Änderungen an der Roadmap → dieses Dokument, Status-Häkchen pflegen
- Diese Datei wird bei jedem Fortschritt aktualisiert (Status ⬜ → 🟨 → ✅), nicht nur am Ende
