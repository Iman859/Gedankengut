"""
Tests für den Gedankengut-Helfer.

Ausführen (im Projektordner):   python3 -m unittest discover -s helfer -v

WIE DIE TESTS FUNKTIONIEREN
---------------------------
- Jeder Test startet einen echten Helfer-Server auf einem freien Port
  (Port 0 = „such dir einen aus“) in einem eigenen Thread und schickt ihm
  echte HTTP-Anfragen – so, wie es später die App tut.
- Statt `claude` läuft die Attrappe `attrappe_claude.py`. Sie kostet kein
  Abo-Kontingent und sieht nie echte Einträge. Über ATTRAPPE_MODUS sagen wir
  ihr, welchen Fall (ok, limit, langsam …) sie vortäuschen soll.
- `unittest` gehört zur Python-Standardbibliothek: Jede Methode, die mit
  `test_` beginnt, ist ein Test; `setUp`/`tearDown` laufen davor/danach.
"""

from __future__ import annotations

import io
import json
import os
import sys
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

import gedankengut_helfer as helfer

ATTRAPPE = str(Path(__file__).with_name("attrappe_claude.py"))
SCHLUESSEL = "test-schluessel-der-lang-genug-ist-1234567890"


class HelferTestBasis(unittest.TestCase):
    """Startet für jeden Test einen frischen Helfer mit der Attrappe."""

    zeitlimit = 10.0
    max_wartend = 5

    def setUp(self):
        # Das Protokoll des Helfers während der Tests schlucken, damit die
        # Testausgabe übersichtlich bleibt (ProtokollTests fängt es gezielt ab).
        still = redirect_stdout(io.StringIO())
        still.__enter__()
        self.addCleanup(still.__exit__, None, None, None)

        self.einstellungen = helfer.Einstellungen(
            schluessel=SCHLUESSEL,
            claude_befehl=[sys.executable, ATTRAPPE],
            port=0,
            zeitlimit=self.zeitlimit,
            max_wartend=self.max_wartend,
        )
        self.server = helfer.server_erzeugen(self.einstellungen)
        self.port = self.server.server_address[1]
        self.faden = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.faden.start()
        # Die Attrappe soll mitschreiben, womit sie aufgerufen wurde.
        self.attrappen_protokoll = Path(tempfile.mkdtemp()) / "aufruf.json"
        self.umgebung = mock.patch.dict(os.environ, {"ATTRAPPE_PROTOKOLL": str(self.attrappen_protokoll)})
        self.umgebung.start()

    def tearDown(self):
        self.umgebung.stop()
        self.server.shutdown()
        self.server.server_close()

    def modus(self, modus: str, **weitere: str):
        """Setzt den Modus der Attrappe für diesen Test."""
        patch = mock.patch.dict(os.environ, {"ATTRAPPE_MODUS": modus, **weitere})
        patch.start()
        self.addCleanup(patch.stop)

    def anfrage(self, methode: str, pfad: str, daten=None, schluessel: str | None = SCHLUESSEL,
                roh: bytes | None = None) -> tuple[int, dict]:
        """Schickt eine HTTP-Anfrage und gibt (Statuscode, JSON-Antwort) zurück."""
        rumpf = roh if roh is not None else (None if daten is None else json.dumps(daten).encode("utf-8"))
        anfrage = urllib.request.Request(f"http://127.0.0.1:{self.port}{pfad}", data=rumpf, method=methode)
        anfrage.add_header("Content-Type", "application/json")
        if schluessel is not None:
            anfrage.add_header("Authorization", f"Bearer {schluessel}")
        try:
            with urllib.request.urlopen(anfrage, timeout=30) as antwort:
                return antwort.status, json.loads(antwort.read())
        except urllib.error.HTTPError as fehler:  # 4xx/5xx kommen als Ausnahme
            with fehler:  # Antwort danach schließen
                return fehler.code, json.loads(fehler.read())

    def aufruf(self) -> dict:
        """Liest, womit die Attrappe aufgerufen wurde."""
        return json.loads(self.attrappen_protokoll.read_text(encoding="utf-8"))


# ---------------------------------------------------------------------------

class StatusTests(HelferTestBasis):

    def test_status_mit_schluessel(self):
        status, antwort = self.anfrage("GET", "/status")
        self.assertEqual(status, 200)
        self.assertEqual(antwort, {"ok": True, "modell": "opus"})

    def test_status_ohne_oder_mit_falschem_schluessel(self):
        for schluessel in (None, "falsch", SCHLUESSEL + "x"):
            status, antwort = self.anfrage("GET", "/status", schluessel=schluessel)
            self.assertEqual(status, 401)
            self.assertEqual(antwort["fehler"], "nicht_angemeldet")
            self.assertFalse(antwort["wiederholen"])

    def test_unbekannte_adresse(self):
        self.assertEqual(self.anfrage("GET", "/irgendwas")[0], 404)
        self.assertEqual(self.anfrage("POST", "/irgendwas", {"inhalt": "x"})[0], 404)


class BuchfassungTests(HelferTestBasis):

    def test_erfolg_liefert_saubere_antwort(self):
        status, antwort = self.anfrage("POST", "/buchfassung", {"inhalt": "rohtext", "kapitel": ["Uni & Alltag"]})
        self.assertEqual(status, 200)
        # Genau diese Felder, Text an den Rändern getrimmt.
        self.assertEqual(antwort, {
            "buchFassung": "Das ist die Buch-Fassung.\n\nZweiter Absatz.",
            "titel": "Ein Titel",
            "kapitel": "Uni & Alltag",
            "kapitelNeu": False,
            "hinweis": "",
        })

    def test_claude_wird_richtig_aufgerufen(self):
        self.anfrage("POST", "/buchfassung", {"inhalt": "Mein Rohtext", "kapitel": ["Uni & Alltag", " Musik ", ""]})
        aufruf = self.aufruf()
        argumente = aufruf["argumente"]

        # Die wichtigen Schalter sind dabei …
        self.assertIn("-p", argumente)
        self.assertEqual(argumente[argumente.index("--model") + 1], "opus")
        self.assertEqual(argumente[argumente.index("--tools") + 1], "")
        self.assertEqual(argumente[argumente.index("--output-format") + 1], "json")
        self.assertIn("--no-session-persistence", argumente)
        self.assertIn("--strict-mcp-config", argumente)
        # … mit genau unserem Prompt und Schema.
        prompt = helfer.PROMPT_DATEI.read_text(encoding="utf-8")
        self.assertEqual(argumente[argumente.index("--system-prompt") + 1], prompt)
        self.assertEqual(json.loads(argumente[argumente.index("--json-schema") + 1]), helfer.ANTWORT_SCHEMA)
        # Der Rohtext geht über stdin, nicht über die Befehlszeile.
        self.assertNotIn("Mein Rohtext", " ".join(argumente))

        # Die Nachricht: Kapitel (getrimmt, leere weg) + Rohtext zwischen den Markern.
        self.assertEqual(aufruf["nachricht"],
                         "Vorhandene Kapitel:\n- Uni & Alltag\n- Musik\n\n"
                         "Rohtext des Eintrags:\n<<<\nMein Rohtext\n>>>")

        # claude lief in einem eigenen, leeren Ordner, der danach weg ist.
        self.assertIn("gedankengut-", aufruf["ordner"])
        self.assertNotEqual(Path(aufruf["ordner"]).resolve(), Path.cwd().resolve())
        self.assertFalse(Path(aufruf["ordner"]).exists())

    def test_ohne_kapitel(self):
        status, _ = self.anfrage("POST", "/buchfassung", {"inhalt": "Text"})
        self.assertEqual(status, 200)
        self.assertIn("Vorhandene Kapitel:\n(noch keine)\n", self.aufruf()["nachricht"])

    def test_falscher_schluessel_ruft_claude_gar_nicht_auf(self):
        status, antwort = self.anfrage("POST", "/buchfassung", {"inhalt": "Text"}, schluessel="falsch")
        self.assertEqual(status, 401)
        self.assertEqual(antwort["fehler"], "nicht_angemeldet")
        self.assertFalse(self.attrappen_protokoll.exists())

    def test_ungueltige_anfragen(self):
        faelle = [
            ({}, "ungueltige_anfrage"),
            ({"inhalt": ""}, "ungueltige_anfrage"),
            ({"inhalt": "   \n "}, "ungueltige_anfrage"),
            ({"inhalt": 42}, "ungueltige_anfrage"),
            ({"inhalt": "x", "kapitel": "kein Array"}, "ungueltige_anfrage"),
            ({"inhalt": "x", "kapitel": [1, 2]}, "ungueltige_anfrage"),
            ({"inhalt": "x", "kapitel": ["k"] * (helfer.MAX_KAPITEL + 1)}, "ungueltige_anfrage"),
            ([1, 2, 3], "ungueltige_anfrage"),
        ]
        for daten, code in faelle:
            with self.subTest(daten=str(daten)[:40]):
                status, antwort = self.anfrage("POST", "/buchfassung", daten)
                self.assertEqual(status, 400)
                self.assertEqual(antwort["fehler"], code)
                self.assertFalse(antwort["wiederholen"])
        self.assertFalse(self.attrappen_protokoll.exists())

    def test_kein_json(self):
        status, antwort = self.anfrage("POST", "/buchfassung", roh=b"{kaputt")
        self.assertEqual((status, antwort["fehler"]), (400, "ungueltige_anfrage"))

    def test_zu_langer_eintrag(self):
        status, antwort = self.anfrage("POST", "/buchfassung", {"inhalt": "a" * (helfer.MAX_ZEICHEN + 1)})
        self.assertEqual((status, antwort["fehler"]), (413, "zu_lang"))
        self.assertFalse(antwort["wiederholen"])

    def test_zu_grosse_anfrage(self):
        roh = json.dumps({"inhalt": "a", "fuell": "x" * helfer.MAX_ANFRAGE_BYTES}).encode()
        status, antwort = self.anfrage("POST", "/buchfassung", roh=roh)
        self.assertEqual((status, antwort["fehler"]), (413, "zu_lang"))


class ClaudeFehlerTests(HelferTestBasis):
    zeitlimit = 1.0

    def pruefe(self, modus: str, status: int, code: str):
        self.modus(modus, ATTRAPPE_WARTEN="3")
        s, antwort = self.anfrage("POST", "/buchfassung", {"inhalt": "Text"})
        self.assertEqual((s, antwort["fehler"]), (status, code))
        self.assertTrue(antwort["wiederholen"], "bei claude-Problemen soll die App es später erneut versuchen")

    def test_limit(self):
        self.pruefe("limit", 503, "limit")

    def test_allgemeiner_fehler(self):
        self.pruefe("fehler", 502, "claude_fehler")

    def test_keine_json_ausgabe(self):
        self.pruefe("kaputt", 502, "claude_fehler")

    def test_falsche_antwortform(self):
        self.pruefe("ohne_schema", 502, "antwort_ungueltig")

    def test_zeitlimit(self):
        self.pruefe("langsam", 504, "zeitlimit")

    def test_claude_nicht_startbar(self):
        self.einstellungen.claude_befehl = ["/gibt/es/nicht/claude"]
        s, antwort = self.anfrage("POST", "/buchfassung", {"inhalt": "Text"})
        self.assertEqual((s, antwort["fehler"]), (502, "claude_fehler"))


class WarteschlangeTests(HelferTestBasis):
    max_wartend = 1   # 1 arbeitet, 1 darf warten, der dritte wird abgewiesen

    def test_nur_einer_gleichzeitig_und_volle_schlange(self):
        self.modus("langsam", ATTRAPPE_WARTEN="1.5")
        ergebnisse: list[tuple[float, int]] = []

        def senden():
            status, _ = self.anfrage("POST", "/buchfassung", {"inhalt": "Text"})
            ergebnisse.append((time.monotonic(), status))

        start = time.monotonic()
        faeden = []
        for _ in range(3):
            faden = threading.Thread(target=senden)
            faden.start()
            faeden.append(faden)
            time.sleep(0.3)   # damit die Reihenfolge feststeht
        for faden in faeden:
            faden.join()

        self.assertEqual(sorted(status for _, status in ergebnisse), [200, 200, 503])
        # Die zwei erfolgreichen liefen nacheinander, nicht gleichzeitig.
        letzte_erfolgreiche = max(zeit for zeit, status in ergebnisse if status == 200)
        self.assertGreaterEqual(letzte_erfolgreiche - start, 3.0)

    def test_status_antwortet_waehrend_claude_laeuft(self):
        self.modus("langsam", ATTRAPPE_WARTEN="2")
        faden = threading.Thread(target=lambda: self.anfrage("POST", "/buchfassung", {"inhalt": "Text"}))
        faden.start()
        time.sleep(0.3)
        start = time.monotonic()
        status, _ = self.anfrage("GET", "/status")
        self.assertEqual(status, 200)
        self.assertLess(time.monotonic() - start, 1.0)
        faden.join()


class ProtokollTests(HelferTestBasis):

    def test_protokoll_enthaelt_keine_inhalte(self):
        geheim = "GEHEIMER-SATZ-über-Sebastian"
        mitschrift = io.StringIO()
        with redirect_stdout(mitschrift):
            self.anfrage("POST", "/buchfassung", {"inhalt": geheim, "kapitel": ["Geheimes Kapitel"]})
            self.modus("ohne_schema")
            self.anfrage("POST", "/buchfassung", {"inhalt": geheim})
        protokoll = mitschrift.getvalue()
        self.assertIn("→ 200", protokoll)
        self.assertIn("antwort_ungueltig", protokoll)
        self.assertNotIn("GEHEIM", protokoll)
        self.assertNotIn("Geheimes Kapitel", protokoll)
        self.assertNotIn("Buch-Fassung", protokoll)   # auch die Antwort nicht


class EinstellungenTests(unittest.TestCase):

    def test_kurzer_schluessel_wird_abgelehnt(self):
        with mock.patch.dict(os.environ, {"GEDANKENGUT_SCHLUESSEL": "zu-kurz"}):
            with self.assertRaises(SystemExit):
                helfer.einstellungen_aus_umgebung()

    def test_werte_aus_der_umgebung(self):
        with mock.patch.dict(os.environ, {
            "GEDANKENGUT_SCHLUESSEL": SCHLUESSEL,
            "GEDANKENGUT_CLAUDE": ATTRAPPE,
            "GEDANKENGUT_ADRESSE": "100.64.0.1",
            "GEDANKENGUT_PORT": "9000",
            "GEDANKENGUT_ZEITLIMIT": "60",
        }):
            e = helfer.einstellungen_aus_umgebung()
        self.assertEqual((e.adresse, e.port, e.zeitlimit, e.modell), ("100.64.0.1", 9000, 60.0, "opus"))
        self.assertEqual(e.claude_befehl, [ATTRAPPE])

    def test_standardwerte(self):
        with mock.patch.dict(os.environ, {"GEDANKENGUT_SCHLUESSEL": SCHLUESSEL, "GEDANKENGUT_CLAUDE": ATTRAPPE}):
            for name in ("GEDANKENGUT_ADRESSE", "GEDANKENGUT_PORT", "GEDANKENGUT_MODELL", "GEDANKENGUT_ZEITLIMIT"):
                os.environ.pop(name, None)
            e = helfer.einstellungen_aus_umgebung()
        self.assertEqual((e.adresse, e.port, e.modell, e.zeitlimit), ("127.0.0.1", 8765, "opus", 120.0))

    def test_prompt_ist_v4(self):
        prompt = helfer.PROMPT_DATEI.read_text(encoding="utf-8")
        self.assertIn("Redewendungen und umgangssprachliche Wendungen übernimmst du Wort für Wort", prompt)
        self.assertIn("⁂", prompt)


if __name__ == "__main__":
    unittest.main()
