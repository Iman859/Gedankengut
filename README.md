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
- [x] Buch-Design mit Kapiteln (dunkelblau, lila, ruhig, im Stil eines Notizbuchs)
- [ ] Schreibmodi: freies Schreiben, Gefühle benennen, Gedanken-Check, Entscheidungen
- [ ] Verschönern von Einträgen mit KI-Unterstützung (das Original bleibt immer erhalten)
- [ ] Wochenrückblick und Export als Buch (PDF)
- [ ] macOS-Version

## Status

✅ **Phase 1 – Kern abgeschlossen.** Die App startet direkt auf einer leeren
Seite, speichert automatisch in einer lokalen Datenbank und zeigt alle
Einträge in einer Übersicht (öffnen, weiterschreiben, löschen).

✅ **Phase 2 – Design „Neon-Eleganz“ abgeschlossen.** Nachtblaues Design mit
Neon-Akzenten und Sternenhimmel, Schreibseite mit Fokus-Leuchten, Übersicht als
Zeitstrahl, Buchansicht mit Kapiteln und 3D-Umblättern, eigenes App-Icon.

🚧 **Als Nächstes: KI-Unterstützung** – aus den rohen Einträgen entsteht eine
geordnete, korrigierte Buch-Fassung mit Titel- und Kapitelvorschlägen.

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

## App-Icon

Das Icon „Kopf voller Sterne“ liegt als bearbeitbare SVG-Quelle in
[`icon/quelle/`](icon/quelle/) – aufgeteilt in die Ebenen, die Android für ein
adaptives Icon braucht:

| Datei | Inhalt |
| --- | --- |
| `hintergrund.svg` | Nachthimmel-Verlauf |
| `vordergrund.svg` | Kopf mit Sternen und Leuchten |
| `monochrom.svg` | einfarbige Fassung für die „Designsymbole“ (Android 13+) |

Nach einer Änderung an den SVGs wird das Icon neu erzeugt mit:

```bash
# einmalig: Werkzeuge zum Umwandeln der SVGs installieren
brew install librsvg imagemagick

# SVG → PNG (icon/png/) → alle Android-Icon-Größen
bash icon/erzeugen.sh
```

Das Skript nutzt das Paket [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons);
dessen Einstellungen stehen in [`flutter_launcher_icons.yaml`](flutter_launcher_icons.yaml).

## Lizenz

[MIT](LICENSE) © 2026 Iman Sargin
