#!/usr/bin/env python3
"""
Attrappe für `claude` – nur für die Tests.

Die Tests sollen weder das Abo-Kontingent verbrauchen noch echte Einträge
verschicken. Deshalb setzen sie statt `claude` dieses kleine Programm ein.
Es verhält sich nach außen wie `claude -p --output-format json`: Es liest die
Nachricht von der Standardeingabe und gibt ein JSON-Objekt aus.

Was es tut, steuert die Umgebungsvariable ATTRAPPE_MODUS:

    ok            normale Antwort (Standard)
    limit         „Nutzungslimit erreicht“
    fehler        allgemeiner Fehler von claude
    langsam       wartet ATTRAPPE_WARTEN Sekunden (Standard 5), dann ok
    kaputt        gibt kein JSON aus
    ohne_schema   Antwort ohne die erwarteten Felder

Ist ATTRAPPE_PROTOKOLL gesetzt, schreibt die Attrappe dorthin, womit sie
aufgerufen wurde (Argumente, Arbeitsordner, Nachricht). So können die Tests
prüfen, ob der Helfer `claude` richtig aufruft.
"""

import json
import os
import sys
import time

nachricht = sys.stdin.read()
modus = os.environ.get("ATTRAPPE_MODUS", "ok")

protokoll_datei = os.environ.get("ATTRAPPE_PROTOKOLL")
if protokoll_datei:
    with open(protokoll_datei, "w", encoding="utf-8") as datei:
        json.dump({"argumente": sys.argv[1:], "ordner": os.getcwd(), "nachricht": nachricht}, datei)

if modus == "langsam":
    time.sleep(float(os.environ.get("ATTRAPPE_WARTEN", "5")))

if modus == "kaputt":
    print("das ist kein JSON")
    sys.exit(1)

if modus == "limit":
    print(json.dumps({"type": "result", "subtype": "success", "is_error": True,
                      "result": "You've hit your limit · resets 11pm"}))
    sys.exit(1)

if modus == "fehler":
    print(json.dumps({"type": "result", "subtype": "error_during_execution", "is_error": True,
                      "result": "Irgendetwas ist schiefgegangen"}))
    sys.exit(1)

if modus == "ohne_schema":
    print(json.dumps({"type": "result", "subtype": "success", "is_error": False,
                      "result": "Freitext", "structured_output": {"text": "falsche Form"}}))
    sys.exit(0)

# Normale Antwort, wie sie das echte `claude` liefert.
print(json.dumps({
    "type": "result",
    "subtype": "success",
    "is_error": False,
    "result": "",
    "structured_output": {
        "buchFassung": "  Das ist die Buch-Fassung.\n\nZweiter Absatz.  ",
        "titel": "Ein Titel",
        "kapitel": "Uni & Alltag",
        "kapitelNeu": False,
        "hinweis": "",
    },
}, ensure_ascii=False))
