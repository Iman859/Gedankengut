# Gedankengut-Helfer

Ein kleines Python-Programm, das aus einem Rohtext die **Buch-Fassung** macht: korrigiert, geordnet und lesbar, mit Titel- und Kapitelvorschlag. Die App schickt ihm den Text, der Helfer ruft das Kommandozeilenprogramm `claude` (Claude Code von Anthropic, Modell Opus) mit den Anweisungen aus [`prompt.txt`](prompt.txt) auf und gibt das Ergebnis zurück.

- Nur Python-Standardbibliothek (ab Python 3.11), keine weiteren Pakete
- Speichert nichts; das Protokoll enthält nur Uhrzeit, Dauer, Textlänge und Ergebnis, nie Inhalte
- Jede Anfrage braucht einen geheimen Schlüssel
- Es läuft immer nur ein `claude`-Aufruf gleichzeitig; bis zu 5 weitere Anfragen warten

## Starten

```sh
# Einmalig einen Schlüssel erzeugen (gut aufbewahren, nie ins Repo):
python3 -c 'import secrets; print(secrets.token_urlsafe(32))'

GEDANKENGUT_SCHLUESSEL=<schlüssel> python3 helfer/gedankengut_helfer.py
```

| Umgebungsvariable | Bedeutung | Standard |
|---|---|---|
| `GEDANKENGUT_SCHLUESSEL` | geheimer Schlüssel, mindestens 32 Zeichen | – (Pflicht) |
| `GEDANKENGUT_ADRESSE` | Adresse, auf der gelauscht wird (auf dem Server: die Tailscale-Adresse) | `127.0.0.1` |
| `GEDANKENGUT_PORT` | Port | `8765` |
| `GEDANKENGUT_CLAUDE` | Pfad zu `claude` | im `PATH` suchen |
| `GEDANKENGUT_MODELL` | Modell | `opus` |
| `GEDANKENGUT_ZEITLIMIT` | Sekunden pro Aufruf | `120` |

`claude` muss angemeldet sein (auf einem Server: `claude setup-token`).

## Schnittstelle

Alle Anfragen brauchen den Kopf `Authorization: Bearer <schlüssel>`.

**`GET /status`** → `{"ok": true, "modell": "opus"}`

**`POST /buchfassung`**

```json
{"inhalt": "der Rohtext …", "kapitel": ["Uni & Alltag", "Musik"]}
```

Antwort (200):

```json
{"buchFassung": "…", "titel": "…", "kapitel": "…", "kapitelNeu": false, "hinweis": ""}
```

- `buchFassung`: Absätze sind durch eine Leerzeile getrennt, eine Zeile `⁂` markiert einen Szenenwechsel.
- `kapitelNeu`: `true`, wenn das Kapitel nicht in der Liste stand (neuer Vorschlag).
- `hinweis`: meist leer; sonst steht dort, was bewusst weggelassen wurde (z. B. Tastatur-Kauderwelsch).

Fehler kommen als `{"fehler": "<code>", "meldung": "…", "wiederholen": true|false}`:

| Status | `fehler` | `wiederholen` | Bedeutung |
|---|---|---|---|
| 400 | `ungueltige_anfrage` | nein | Rumpf fehlt, ist kein JSON oder hat die falsche Form |
| 401 | `nicht_angemeldet` | nein | Schlüssel fehlt oder ist falsch |
| 413 | `zu_lang` | nein | Eintrag über 20 000 Zeichen oder Anfrage zu groß |
| 503 | `limit` | ja | Nutzungslimit des Abos erreicht |
| 503 | `beschaeftigt` | ja | zu viele Anfragen gleichzeitig |
| 504 | `zeitlimit` | ja | `claude` hat zu lange gebraucht |
| 502 | `claude_fehler`, `antwort_ungueltig` | ja | `claude` hat einen Fehler gemeldet oder unpassend geantwortet |

## Tests

```sh
python3 -m unittest discover -s helfer -v
```

Die Tests verwenden statt `claude` die Attrappe [`attrappe_claude.py`](attrappe_claude.py). Sie verbrauchen also kein Kontingent und verschicken keine Texte.
