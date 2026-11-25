# Gedankengut

> Ein persönliches Journal, das rohe Gedanken in ein lesbares Buch verwandelt.

Gedankengut ist eine Journal-App für Android (und später macOS). Ziel ist es,
das Schreiben so einfach und angenehm zu machen, dass es zur Gewohnheit wird –
egal ob abends vor dem Schlafengehen oder spontan zwischendurch.

Schnell hingetippte, ungeordnete Gedanken werden ästhetisch formatiert,
korrigiert und in **Kapitel** sortiert, sodass mit der Zeit ein Buch über das
eigene Leben entsteht.

## Warum?

Schreiben ist eine der wirksamsten Methoden, um innere Ruhe zu finden, Gefühle
zu verstehen und bessere Entscheidungen zu treffen. Die App stützt sich auf
Erkenntnisse aus der Psychologie, unter anderem:

- **Expressives Schreiben** (Pennebaker) – über Gefühle schreiben und dabei Sinn finden
- **Gefühle benennen** (Affect Labeling, Lieberman) – präzise Worte für Emotionen beruhigen
- **Selbstdistanzierung** (Kross) – die eigene Situation aus Abstand betrachten
- **Narrative Identität** (McAdams) – das eigene Leben als Geschichte mit Kapiteln verstehen

## Geplante Funktionen

- [x] Schnelles, ablenkungsfreies Schreiben – komplett offline, Daten bleiben auf dem Gerät
- [x] Automatisches Speichern und Übersicht aller Einträge
- [ ] Buch-Design mit Kapiteln (dunkelblau, lila, ruhig, im Stil eines Notizbuchs)
- [ ] Schreibmodi: freies Schreiben, Gefühle benennen, Gedanken-Check, Entscheidungen
- [ ] Verschönern von Einträgen mit KI-Unterstützung (das Original bleibt immer erhalten)
- [ ] Wochenrückblick und Export als Buch (PDF)
- [ ] macOS-Version

## Status

✅ **Phase 1 – Kern abgeschlossen.** Die App startet direkt auf einer leeren
Seite, speichert automatisch in einer lokalen Datenbank und zeigt alle
Einträge in einer Übersicht (öffnen, weiterschreiben, löschen).

🚧 **Als Nächstes: Phase 2 – Design** (Buch-Look mit Kapiteln).

## Technik

- [Flutter](https://flutter.dev) (Programmiersprache Dart) – eine Codebasis für Android und macOS
- Der gesamte Code ist ausführlich auf Deutsch kommentiert

## Selbst bauen

Voraussetzungen: [Flutter](https://docs.flutter.dev/get-started/install) und das Android SDK.

```bash
# Abhängigkeiten herunterladen
flutter pub get

# App auf einem verbundenen Android-Gerät starten
flutter run

# Tests ausführen
flutter test
```

## Lizenz

[MIT](LICENSE) © 2026 Iman Sargin
