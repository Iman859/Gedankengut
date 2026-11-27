#!/usr/bin/env python3
"""
Gedankengut-Helfer – macht aus einem Rohtext die Buch-Fassung.

WAS DIESES PROGRAMM TUT
-----------------------
Die App auf dem Handy schickt dem Helfer einen Rohtext (so, wie er getippt
wurde) und die Liste der vorhandenen Kapitel. Der Helfer ruft damit das
Kommandozeilenprogramm `claude` auf (Claude von Anthropic, Modell Opus) und
schickt das Ergebnis zurück:

    {"buchFassung": "...", "titel": "...", "kapitel": "...",
     "kapitelNeu": true/false, "hinweis": "..."}

Die Anweisungen an das Sprachmodell (der „Prompt“) stehen in `prompt.txt`
neben dieser Datei.

GRUNDSÄTZE
----------
- Nur Python-Standardbibliothek: nichts muss installiert werden außer Python
  selbst und `claude`.
- Der Helfer SPEICHERT NICHTS. Der Text ist nur während der Anfrage im
  Arbeitsspeicher.
- Das Protokoll enthält nur Uhrzeit, Dauer, Textlänge und Ergebnis – nie
  Inhalte.
- Jede Anfrage muss einen geheimen Schlüssel mitschicken.
- Es läuft immer nur EIN `claude`-Aufruf gleichzeitig (der Server hat wenig
  Arbeitsspeicher). Weitere Anfragen warten in einer kurzen Schlange.

NEUE KONZEPTE, KURZ ERKLÄRT
---------------------------
- HTTP-Server: Ein Programm, das auf einem „Port“ (hier 8765) lauscht. Ein
  anderes Programm (die App) verbindet sich, schickt eine Anfrage
  (z. B. `POST /buchfassung` mit JSON im Rumpf) und bekommt eine Antwort mit
  Statuscode (200 = ok, 401 = nicht berechtigt, 503 = gerade nicht möglich …).
  Python bringt dafür `http.server` mit.
- Threads: `ThreadingHTTPServer` bearbeitet jede Verbindung in einem eigenen
  Thread (parallel laufender Programmfaden). So kann `/status` antworten,
  während nebenan ein `claude`-Aufruf läuft.
- Lock (Schloss): `threading.Lock` sorgt dafür, dass immer nur ein Thread den
  `claude`-Aufruf macht. Die anderen warten, bis das Schloss frei ist.
- subprocess: Startet ein anderes Programm (hier `claude`), gibt ihm Text über
  die Standardeingabe (stdin) und liest seine Ausgabe (stdout).
- Umgebungsvariablen: Einstellungen, die von außen gesetzt werden
  (z. B. `GEDANKENGUT_SCHLUESSEL=...`). So steht der geheime Schlüssel nie im
  Code oder im Repo.
- Bearer-Schlüssel: Die App schickt im Kopf der Anfrage die Zeile
  `Authorization: Bearer <schlüssel>`. Der Helfer vergleicht sie mit seinem
  Schlüssel.

EINSTELLUNGEN (Umgebungsvariablen)
----------------------------------
    GEDANKENGUT_SCHLUESSEL   Pflicht. Geheimer Schlüssel, mindestens 32 Zeichen.
    GEDANKENGUT_ADRESSE      Wo gelauscht wird. Standard 127.0.0.1 (nur dieser
                             Rechner). Auf dem Server: die Tailscale-Adresse.
    GEDANKENGUT_PORT         Standard 8765.
    GEDANKENGUT_CLAUDE       Pfad zu `claude`. Standard: im PATH suchen.
    GEDANKENGUT_MODELL       Standard opus.
    GEDANKENGUT_ZEITLIMIT    Sekunden pro claude-Aufruf, Standard 120.

Starten:  GEDANKENGUT_SCHLUESSEL=... python3 gedankengut_helfer.py
"""

from __future__ import annotations

import hmac
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from dataclasses import dataclass, field
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

# ---------------------------------------------------------------------------
# Grenzen – schützen den kleinen Server vor zu großen oder unsinnigen Anfragen
# ---------------------------------------------------------------------------

MAX_ZEICHEN = 20_000          # Länge eines Eintrags (ca. 3000 Wörter)
MAX_KAPITEL = 200             # Anzahl Kapitel in der Liste
MAX_KAPITEL_ZEICHEN = 100     # Länge eines Kapitelnamens
MAX_ANFRAGE_BYTES = 256 * 1024  # Größe des gesamten Anfrage-Rumpfs
MIN_SCHLUESSEL_ZEICHEN = 32

PROMPT_DATEI = Path(__file__).with_name("prompt.txt")

# JSON-Schema: zwingt `claude`, genau in dieser Form zu antworten.
# (Dieselbe Form wie im Probelauf mit Prompt v4.)
ANTWORT_SCHEMA = {
    "type": "object",
    "properties": {
        "buchFassung": {"type": "string"},
        "titel": {"type": "string"},
        "kapitel": {"type": "string"},
        "kapitelNeu": {"type": "boolean"},
        "hinweis": {"type": "string"},
    },
    "required": ["buchFassung", "titel", "kapitel", "kapitelNeu", "hinweis"],
    "additionalProperties": False,
}


# ---------------------------------------------------------------------------
# Einstellungen
# ---------------------------------------------------------------------------

@dataclass
class Einstellungen:
    """Alle Einstellungen an einem Ort.

    `@dataclass` erzeugt automatisch einen Konstruktor aus den Feldern –
    ähnlich wie eine Klasse mit nur `final`-Feldern in Dart.
    """

    schluessel: str
    # Der Befehl als Liste, z. B. ["/opt/homebrew/bin/claude"]. Eine Liste
    # statt eines Textes, damit die Tests eine Attrappe einsetzen können
    # (["python3", "attrappe_claude.py"]).
    claude_befehl: list[str]
    adresse: str = "127.0.0.1"
    port: int = 8765
    modell: str = "opus"
    zeitlimit: float = 120.0
    # Wie viele Anfragen höchstens warten dürfen, während eine läuft.
    max_wartend: int = 5
    prompt: str = field(default_factory=lambda: PROMPT_DATEI.read_text(encoding="utf-8"))


def einstellungen_aus_umgebung() -> Einstellungen:
    """Liest die Einstellungen aus den Umgebungsvariablen und prüft sie."""
    schluessel = os.environ.get("GEDANKENGUT_SCHLUESSEL", "")
    if len(schluessel) < MIN_SCHLUESSEL_ZEICHEN:
        raise SystemExit(
            f"GEDANKENGUT_SCHLUESSEL fehlt oder ist kürzer als {MIN_SCHLUESSEL_ZEICHEN} Zeichen.\n"
            "Einen neuen erzeugen:  python3 -c 'import secrets; print(secrets.token_urlsafe(32))'"
        )

    claude = os.environ.get("GEDANKENGUT_CLAUDE") or shutil.which("claude")
    if not claude or not Path(claude).exists():
        raise SystemExit("`claude` nicht gefunden. Pfad über GEDANKENGUT_CLAUDE angeben.")

    return Einstellungen(
        schluessel=schluessel,
        claude_befehl=[claude],
        adresse=os.environ.get("GEDANKENGUT_ADRESSE", "127.0.0.1"),
        port=int(os.environ.get("GEDANKENGUT_PORT", "8765")),
        modell=os.environ.get("GEDANKENGUT_MODELL", "opus"),
        zeitlimit=float(os.environ.get("GEDANKENGUT_ZEITLIMIT", "120")),
    )


# ---------------------------------------------------------------------------
# Protokoll – NUR Metadaten, nie Inhalte
# ---------------------------------------------------------------------------

def protokoll(text: str) -> None:
    """Schreibt eine Zeile ins Protokoll (Standardausgabe).

    Auf dem Server sammelt systemd diese Ausgabe (ansehen mit `journalctl`).
    WICHTIG: Hier landet nie ein Eintragstext, nur Zahlen und Statuscodes.
    `flush=True` schreibt sofort, statt zu puffern.
    """
    zeit = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"{zeit}  {text}", file=sys.stdout, flush=True)


# ---------------------------------------------------------------------------
# Fehler, die an die App zurückgehen
# ---------------------------------------------------------------------------

class HelferFehler(Exception):
    """Ein erwarteter Fehler mit allem, was die App wissen muss.

    - status:      HTTP-Statuscode
    - code:        kurzes Kennwort für die App (z. B. "limit")
    - meldung:     Erklärung für Menschen
    - wiederholen: Soll die App es später erneut versuchen?
    """

    def __init__(self, status: HTTPStatus, code: str, meldung: str, wiederholen: bool):
        super().__init__(meldung)
        self.status = status
        self.code = code
        self.meldung = meldung
        self.wiederholen = wiederholen


# ---------------------------------------------------------------------------
# Anfrage prüfen
# ---------------------------------------------------------------------------

def anfrage_pruefen(daten: object) -> tuple[str, list[str]]:
    """Prüft den JSON-Rumpf der App und gibt (inhalt, kapitel) zurück."""

    def ungueltig(meldung: str) -> HelferFehler:
        return HelferFehler(HTTPStatus.BAD_REQUEST, "ungueltige_anfrage", meldung, False)

    if not isinstance(daten, dict):
        raise ungueltig("Erwartet wird ein JSON-Objekt.")

    inhalt = daten.get("inhalt")
    if not isinstance(inhalt, str) or not inhalt.strip():
        raise ungueltig("„inhalt“ fehlt oder ist leer.")
    if len(inhalt) > MAX_ZEICHEN:
        raise HelferFehler(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, "zu_lang",
                           f"Der Eintrag ist länger als {MAX_ZEICHEN} Zeichen.", False)

    kapitel = daten.get("kapitel", [])
    if not isinstance(kapitel, list) or not all(isinstance(k, str) for k in kapitel):
        raise ungueltig("„kapitel“ muss eine Liste von Texten sein.")
    if len(kapitel) > MAX_KAPITEL or any(len(k) > MAX_KAPITEL_ZEICHEN for k in kapitel):
        raise ungueltig("Zu viele oder zu lange Kapitelnamen.")

    # Leere Namen weglassen, Leerzeichen am Rand entfernen.
    kapitel = [k.strip() for k in kapitel if k.strip()]
    return inhalt, kapitel


def nachricht_bauen(inhalt: str, kapitel: list[str]) -> str:
    """Baut die Nachricht an das Sprachmodell – genau wie im Probelauf."""
    if kapitel:
        liste = "\n".join(f"- {k}" for k in kapitel)
    else:
        liste = "(noch keine)"
    return (
        "Vorhandene Kapitel:\n"
        f"{liste}\n\n"
        "Rohtext des Eintrags:\n"
        "<<<\n"
        f"{inhalt}\n"
        ">>>"
    )


# ---------------------------------------------------------------------------
# claude aufrufen
# ---------------------------------------------------------------------------

def _ist_limit(ausgabe: dict) -> bool:
    """Erkennt, ob das Nutzungslimit des Abos erreicht ist.

    `claude` meldet das als Fehler mit einem Text wie „usage limit reached“
    oder „You've hit your limit“. Ein festes Kennwort dafür gibt es nicht,
    deshalb suchen wir nach typischen Wörtern (und nach Status 429 =
    „zu viele Anfragen“).
    """
    if ausgabe.get("api_error_status") == 429:
        return True
    text = str(ausgabe.get("result", "")).lower()
    return any(wort in text for wort in ("usage limit", "rate limit", "hit your limit", "limit reached"))


def antwort_pruefen(daten: object) -> dict:
    """Prüft, ob die Antwort von `claude` genau die erwartete Form hat."""
    if not isinstance(daten, dict):
        raise ValueError("keine Struktur")
    for schluessel in ("buchFassung", "titel", "kapitel", "hinweis"):
        if not isinstance(daten.get(schluessel), str):
            raise ValueError(f"{schluessel} fehlt")
    if not isinstance(daten.get("kapitelNeu"), bool):
        raise ValueError("kapitelNeu fehlt")
    if not daten["buchFassung"].strip() or not daten["titel"].strip() or not daten["kapitel"].strip():
        raise ValueError("leeres Feld")
    # Nur die bekannten Felder weitergeben, sauber getrimmt.
    return {
        "buchFassung": daten["buchFassung"].strip(),
        "titel": daten["titel"].strip(),
        "kapitel": daten["kapitel"].strip(),
        "kapitelNeu": daten["kapitelNeu"],
        "hinweis": daten["hinweis"].strip(),
    }


def buchfassung_erzeugen(inhalt: str, kapitel: list[str], e: Einstellungen) -> dict:
    """Ruft `claude` auf und gibt die geprüfte Antwort zurück.

    Die Befehlszeile entspricht dem Probelauf:
    - `-p`                        nicht interaktiv: Nachricht rein, Antwort raus
    - `--model opus`              Modell
    - `--tools ""`                keine Werkzeuge (kein Dateizugriff, keine Befehle)
    - `--no-session-persistence`  das Gespräch wird nicht gespeichert
    - `--strict-mcp-config`       keine Zusatzdienste laden (schneller)
    - `--output-format json`      maschinenlesbare Antwort
    - `--system-prompt`           unsere Anweisungen (prompt.txt)
    - `--json-schema`             erzwingt die Antwortform
    """
    befehl = [
        *e.claude_befehl,
        "-p",
        "--model", e.modell,
        "--tools", "",
        "--no-session-persistence",
        "--strict-mcp-config",
        "--output-format", "json",
        "--system-prompt", e.prompt,
        "--json-schema", json.dumps(ANTWORT_SCHEMA),
    ]

    # `claude` läuft in einem frischen, leeren Ordner. So liest es keine
    # fremden Dateien (etwa eine CLAUDE.md) als Zusatz-Kontext ein.
    # `with` löscht den Ordner danach automatisch wieder.
    with tempfile.TemporaryDirectory(prefix="gedankengut-") as leer:
        try:
            ergebnis = subprocess.run(
                befehl,
                input=nachricht_bauen(inhalt, kapitel),  # über stdin, nicht als Argument
                capture_output=True,   # stdout/stderr auffangen statt anzeigen
                text=True,             # Text statt Bytes (UTF-8)
                encoding="utf-8",
                timeout=e.zeitlimit,
                cwd=leer,
            )
        except subprocess.TimeoutExpired:
            raise HelferFehler(HTTPStatus.GATEWAY_TIMEOUT, "zeitlimit",
                               f"claude hat länger als {e.zeitlimit:.0f} s gebraucht.", True)
        except OSError as fehler:
            raise HelferFehler(HTTPStatus.BAD_GATEWAY, "claude_fehler",
                               f"claude konnte nicht gestartet werden ({fehler.__class__.__name__}).", True)

    # Die Ausgabe ist ein einziges JSON-Objekt (auch im Fehlerfall, solange
    # claude selbst nicht abgestürzt ist).
    try:
        ausgabe = json.loads(ergebnis.stdout)
    except json.JSONDecodeError:
        protokoll(f"  claude: keine JSON-Ausgabe (Rückgabewert {ergebnis.returncode})")
        raise HelferFehler(HTTPStatus.BAD_GATEWAY, "claude_fehler",
                           "claude hat keine lesbare Antwort geliefert.", True)

    if not isinstance(ausgabe, dict):
        raise HelferFehler(HTTPStatus.BAD_GATEWAY, "claude_fehler",
                           "claude hat keine lesbare Antwort geliefert.", True)

    if ausgabe.get("is_error"):
        # Im Fehlerfall ist `result` eine Fehlermeldung von claude, kein
        # Eintragstext – deshalb darf ein kurzer Anfang davon ins Protokoll.
        protokoll(f"  claude meldet Fehler: {ausgabe.get('subtype')} – {str(ausgabe.get('result', ''))[:120]}")
        if _ist_limit(ausgabe):
            raise HelferFehler(HTTPStatus.SERVICE_UNAVAILABLE, "limit",
                               "Das Nutzungslimit ist gerade erreicht. Später erneut versuchen.", True)
        raise HelferFehler(HTTPStatus.BAD_GATEWAY, "claude_fehler",
                           "claude hat einen Fehler gemeldet.", True)

    try:
        return antwort_pruefen(ausgabe.get("structured_output"))
    except ValueError as grund:
        protokoll(f"  Antwort passt nicht zum Schema: {grund}")
        raise HelferFehler(HTTPStatus.BAD_GATEWAY, "antwort_ungueltig",
                           "Die Antwort hatte nicht die erwartete Form.", True)


# ---------------------------------------------------------------------------
# Warteschlange: immer nur ein claude-Aufruf gleichzeitig
# ---------------------------------------------------------------------------

class Warteschlange:
    """Lässt genau eine Anfrage arbeiten; höchstens `max_wartend` warten.

    Benutzung:  with schlange.platz():  ... arbeiten ...
    """

    def __init__(self, max_wartend: int):
        self._max_im_haus = 1 + max_wartend   # 1 arbeitet + die Wartenden
        self._im_haus = 0
        self._zaehler_schloss = threading.Lock()  # schützt `_im_haus`
        self._arbeits_schloss = threading.Lock()  # nur einer arbeitet

    def platz(self):
        schlange = self

        class _Platz:
            def __enter__(self):
                with schlange._zaehler_schloss:
                    if schlange._im_haus >= schlange._max_im_haus:
                        raise HelferFehler(HTTPStatus.SERVICE_UNAVAILABLE, "beschaeftigt",
                                           "Zu viele Anfragen gleichzeitig. Später erneut versuchen.", True)
                    schlange._im_haus += 1
                schlange._arbeits_schloss.acquire()  # warten, bis wir dran sind

            def __exit__(self, *_):
                schlange._arbeits_schloss.release()
                with schlange._zaehler_schloss:
                    schlange._im_haus -= 1
                return False  # Ausnahmen nicht verschlucken

        return _Platz()


# ---------------------------------------------------------------------------
# HTTP-Teil
# ---------------------------------------------------------------------------

class HelferAnfrage(BaseHTTPRequestHandler):
    """Bearbeitet eine einzelne HTTP-Anfrage.

    `http.server` erzeugt für jede Anfrage ein neues Objekt dieser Klasse und
    ruft je nach Methode `do_GET` oder `do_POST` auf.
    """

    # Werden beim Start gesetzt (siehe `server_erzeugen`).
    einstellungen: Einstellungen
    schlange: Warteschlange

    server_version = "GedankengutHelfer/1"
    sys_version = ""      # Python-Version nicht verraten
    timeout = 30          # Sekunden: hängende Verbindungen beim Lesen beenden

    # --- Hilfsfunktionen -------------------------------------------------

    def log_message(self, format, *args):  # noqa: A002 (Name von http.server vorgegeben)
        """Das eingebaute Protokoll abschalten – wir schreiben unser eigenes."""

    def _antworten(self, status: HTTPStatus, daten: dict) -> None:
        rumpf = json.dumps(daten, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(rumpf)))
        self.end_headers()
        self.wfile.write(rumpf)

    def _fehler_antworten(self, fehler: HelferFehler) -> None:
        self._antworten(fehler.status, {
            "fehler": fehler.code,
            "meldung": fehler.meldung,
            "wiederholen": fehler.wiederholen,
        })

    def _angemeldet(self) -> bool:
        """Prüft die Zeile `Authorization: Bearer <schlüssel>`.

        `hmac.compare_digest` vergleicht in konstanter Zeit. Ein normales `==`
        bricht beim ersten falschen Zeichen ab – ein Angreifer könnte daran,
        wie lange die Antwort dauert, den Schlüssel Zeichen für Zeichen erraten.
        """
        kopf = self.headers.get("Authorization", "")
        erwartet = f"Bearer {self.einstellungen.schluessel}"
        return hmac.compare_digest(kopf.encode("utf-8"), erwartet.encode("utf-8"))

    # --- Endpunkte -------------------------------------------------------

    def do_GET(self):  # noqa: N802 (Name von http.server vorgegeben)
        if self.path != "/status":
            return self._fehler_antworten(HelferFehler(HTTPStatus.NOT_FOUND, "unbekannt", "Unbekannte Adresse.", False))
        if not self._angemeldet():
            protokoll("GET /status → 401")
            return self._fehler_antworten(HelferFehler(HTTPStatus.UNAUTHORIZED, "nicht_angemeldet", "Falscher Schlüssel.", False))
        self._antworten(HTTPStatus.OK, {"ok": True, "modell": self.einstellungen.modell})

    def do_POST(self):  # noqa: N802
        if self.path != "/buchfassung":
            return self._fehler_antworten(HelferFehler(HTTPStatus.NOT_FOUND, "unbekannt", "Unbekannte Adresse.", False))

        start = time.monotonic()
        laenge = 0
        try:
            # Erst anmelden, dann erst den Rumpf lesen – Fremde bekommen gar
            # nicht die Gelegenheit, uns große Datenmengen zu schicken.
            if not self._angemeldet():
                raise HelferFehler(HTTPStatus.UNAUTHORIZED, "nicht_angemeldet", "Falscher Schlüssel.", False)

            try:
                groesse = int(self.headers.get("Content-Length", ""))
            except ValueError:
                raise HelferFehler(HTTPStatus.LENGTH_REQUIRED, "ungueltige_anfrage", "Content-Length fehlt.", False)
            if groesse < 0 or groesse > MAX_ANFRAGE_BYTES:
                raise HelferFehler(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, "zu_lang", "Die Anfrage ist zu groß.", False)

            try:
                daten = json.loads(self.rfile.read(groesse).decode("utf-8"))
            except (UnicodeDecodeError, json.JSONDecodeError):
                raise HelferFehler(HTTPStatus.BAD_REQUEST, "ungueltige_anfrage", "Kein gültiges JSON.", False)

            inhalt, kapitel = anfrage_pruefen(daten)
            laenge = len(inhalt)

            with self.schlange.platz():
                antwort = buchfassung_erzeugen(inhalt, kapitel, self.einstellungen)

            self._antworten(HTTPStatus.OK, antwort)
            protokoll(f"POST /buchfassung → 200  {laenge} Zeichen  {time.monotonic() - start:.1f} s")

        except HelferFehler as fehler:
            self._fehler_antworten(fehler)
            protokoll(f"POST /buchfassung → {fehler.status.value} {fehler.code}  {laenge} Zeichen  "
                      f"{time.monotonic() - start:.1f} s")
        except Exception as fehler:  # unerwartet: nie Details nach außen geben
            protokoll(f"POST /buchfassung → 500 unerwartet ({fehler.__class__.__name__})")
            self._fehler_antworten(HelferFehler(HTTPStatus.INTERNAL_SERVER_ERROR, "intern",
                                                "Unerwarteter Fehler im Helfer.", True))


def server_erzeugen(e: Einstellungen) -> ThreadingHTTPServer:
    """Erzeugt den Server (startet ihn aber noch nicht).

    Mit `type(...)` bauen wir eine Unterklasse, an der die Einstellungen
    hängen. So kann jedes Anfrage-Objekt `self.einstellungen` lesen, ohne
    globale Variablen. Port 0 heißt „irgendein freier Port“ (für Tests).
    """
    anfrage_klasse = type("Anfrage", (HelferAnfrage,), {
        "einstellungen": e,
        "schlange": Warteschlange(e.max_wartend),
    })
    server = ThreadingHTTPServer((e.adresse, e.port), anfrage_klasse)
    server.daemon_threads = True  # offene Verbindungen blockieren das Beenden nicht
    return server


def main() -> None:
    e = einstellungen_aus_umgebung()
    server = server_erzeugen(e)
    adresse, port = server.server_address[:2]
    protokoll(f"Gedankengut-Helfer lauscht auf {adresse}:{port} (Modell {e.modell})")
    try:
        server.serve_forever()
    except KeyboardInterrupt:  # Strg+C
        pass
    finally:
        server.server_close()
        protokoll("Gedankengut-Helfer beendet")


if __name__ == "__main__":
    main()
