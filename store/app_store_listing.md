# Apple App Store – Eintragsentwurf

_Entwurf für App Store Connect. iOS-Builds erfordern einen Mac mit Xcode —
das konnte in dieser (Linux-)Entwicklungsumgebung nicht getestet werden._

## Name

Memora – Vokabeltrainer

## Untertitel (max. 30 Zeichen)

> Spaced-Repetition-Lernen

## Beschreibung

(gleicher Text wie `play_store_listing.md`, siehe dort)

## Schlüsselwörter (max. 100 Zeichen, kommagetrennt)

> vokabeln,sprachen lernen,flashcards,spaced repetition,vokabeltrainer,karteikarten

## Kategorie

Bildung (Primär), Produktivität (Sekundär)

## Datenschutz-Angaben (App Privacy / Nutritional Label)

Da Memora keine Analytics/Werbung einbindet und Daten nur lokal speichert:
- "Data Not Collected" für die meisten Kategorien
- Ausnahme ggf. angeben, falls die Auto-Übersetzungsfunktion (externe API,
  siehe `privacy_policy.md`) laut Apples Kategorien als Datenübertragung zählt
  — vor Einreichung im App-Privacy-Fragebogen prüfen.

## Offene Punkte vor Einreichung

- [ ] Mac + Xcode zum Bauen/Signieren besorgen (nicht von dieser Linux-VM aus möglich)
- [ ] Apple Developer Program Mitgliedschaft (kostenpflichtig, $99/Jahr)
- [ ] App Store Screenshots (mehrere Gerätegrößen)
- [ ] TestFlight-Beta vor Vollfreigabe
- [ ] Finales App-Icon ohne Alpha-Kanal (Platzhalter bereits alpha-frei generiert,
      s. `flutter_launcher_icons`-Konfig in `pubspec.yaml`)
