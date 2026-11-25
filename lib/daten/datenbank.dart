// =============================================================================
// datenbank.dart – Die lokale Datenbank von Gedankengut
// =============================================================================
//
// Hier wird festgelegt, WIE deine Einträge auf dem Gerät gespeichert werden.
//
// WIE DAS FUNKTIONIERT (kurz erklärt):
//   - Wir nutzen SQLite: eine kleine, sehr verbreitete Datenbank, die als
//     einzelne Datei auf dem Handy liegt. Nichts davon verlässt das Gerät.
//   - Das Paket „Drift“ macht SQLite in Dart bequem nutzbar. Wir beschreiben
//     unsere Tabelle als Dart-Klasse, und Drift ERZEUGT daraus automatisch
//     den passenden Code (Datei `datenbank.g.dart`).
//   - Diese erzeugte Datei schreiben wir NIE von Hand. Nach jeder Änderung an
//     der Tabelle wird sie mit folgendem Befehl neu erzeugt:
//         dart run build_runner build
//
// Eine Tabelle kann man sich wie eine Excel-Tabelle vorstellen:
//   Jede ZEILE ist ein Eintrag, jede SPALTE eine Eigenschaft (Text, Datum, …).
// =============================================================================

// Die Grundbausteine von Drift (Tabellen, Spalten, Abfragen …).
import 'package:drift/drift.dart';

// Hilfspaket, das die Datenbank-Datei am richtigen Ort auf dem Gerät anlegt
// (im privaten Speicherbereich der App, auf den andere Apps keinen Zugriff haben).
import 'package:drift_flutter/drift_flutter.dart';

// `part` bindet die automatisch erzeugte Datei ein. Sie gehört logisch zu
// DIESER Datei und enthält u. a. die Klassen `Eintrag` und `EintraegeCompanion`.
part 'datenbank.g.dart';

// -----------------------------------------------------------------------------
// TABELLE: Eintraege
// -----------------------------------------------------------------------------

/// Beschreibt die Tabelle, in der alle Journal-Einträge gespeichert werden.
///
/// `@DataClassName('Eintrag')` legt fest, wie EINE Zeile dieser Tabelle in
/// Dart heißt. Drift erzeugt daraus die Klasse `Eintrag` mit den Feldern
/// `id`, `inhalt`, `erstelltAm` und `geaendertAm`.
///
/// (Hinweis: In Dart-Namen verwenden wir „ae/oe/ue“ statt Umlauten, weil
/// Programmiersprachen bei Namen nur einfache Buchstaben zulassen.)
@DataClassName('Eintrag')
class Eintraege extends Table {
  /// Eindeutige Nummer jedes Eintrags. `autoIncrement` heißt: Die Datenbank
  /// vergibt sie automatisch und zählt dabei hoch (1, 2, 3, …).
  IntColumn get id => integer().autoIncrement()();

  /// Der eigentliche Text, den du geschrieben hast.
  TextColumn get inhalt => text()();

  /// Wann der Eintrag angelegt wurde (ändert sich danach nie mehr).
  DateTimeColumn get erstelltAm => dateTime()();

  /// Wann der Eintrag zuletzt verändert wurde (wird bei jedem Speichern
  /// aktualisiert). Damit erkennen wir z. B., ob du gerade erst daran
  /// geschrieben hast (→ „15-Minuten-Regel“, siehe unten).
  DateTimeColumn get geaendertAm => dateTime()();
}

// -----------------------------------------------------------------------------
// DATENBANK: GedankengutDatenbank
// -----------------------------------------------------------------------------

/// Die Datenbank der App. Über ein Objekt dieser Klasse lesen und schreiben
/// alle Bildschirme ihre Einträge.
///
/// `@DriftDatabase(tables: [...])` sagt Drift, welche Tabellen dazugehören.
/// `_$GedankengutDatenbank` ist eine von Drift erzeugte Elternklasse, die die
/// ganze „Maschinerie“ (Verbindung, Abfragen, Tabellen-Zugriff) bereitstellt.
@DriftDatabase(tables: [Eintraege])
class GedankengutDatenbank extends _$GedankengutDatenbank {
  /// Erstellt die Datenbank.
  ///
  /// Beide Parameter sind optional und vor allem für TESTS gedacht:
  /// - [verbindung]: Wohin gespeichert wird. Ohne Angabe ist das die echte
  ///   Datei „gedankengut.sqlite“ auf dem Gerät. In Tests übergeben wir eine
  ///   Datenbank, die nur im Arbeitsspeicher existiert.
  /// - [uhr]: Liefert die aktuelle Uhrzeit. Ohne Angabe ist das die echte Uhr
  ///   (`DateTime.now`). In Tests können wir so die Zeit „vorspulen“, um z. B.
  ///   die 15-Minuten-Regel zu prüfen, ohne 15 Minuten warten zu müssen.
  GedankengutDatenbank({QueryExecutor? verbindung, DateTime Function()? uhr})
      // Der Teil nach dem Doppelpunkt läuft, BEVOR das Objekt fertig ist:
      // `_uhr` wird gesetzt, und `super(...)` gibt die Verbindung an die
      // Elternklasse weiter. `??` heißt: „falls links nichts (null) ist,
      // nimm das Rechte“.
      : _uhr = uhr ?? DateTime.now,
        super(verbindung ?? driftDatabase(name: 'gedankengut'));

  /// Die Uhr, die wir für Zeitstempel verwenden (siehe Konstruktor).
  /// Der Unterstrich `_` am Anfang macht das Feld „privat“: Es ist nur
  /// innerhalb dieser Datei sichtbar.
  final DateTime Function() _uhr;

  /// Die Versionsnummer des Datenbank-Aufbaus.
  /// Wenn wir später Spalten hinzufügen (z. B. Titel, Kapitel, Stimmung),
  /// erhöhen wir diese Zahl und beschreiben eine „Migration“ – damit deine
  /// bisherigen Einträge beim Update erhalten bleiben.
  @override
  int get schemaVersion => 1;

  /// Wie lange nach der letzten Änderung ein Eintrag beim erneuten Öffnen der
  /// App weitergeschrieben wird (statt eine neue Seite zu beginnen).
  /// `static const` = ein fester Wert, der zur Klasse gehört, nicht zu einem Objekt.
  static const Duration weiterschreibZeitfenster = Duration(minutes: 15);

  // ---------------------------------------------------------------------------
  // LESEN
  // ---------------------------------------------------------------------------

  /// Liefert alle Einträge, die neuesten zuerst – und zwar als „Stream“.
  ///
  /// Ein Stream ist wie ein Nachrichtenkanal: Immer wenn sich in der Tabelle
  /// etwas ändert (neuer Eintrag, Änderung, Löschung), liefert er automatisch
  /// die aktuelle Liste nach. Die Übersicht bleibt so immer auf dem neuesten
  /// Stand, ohne dass wir sie selbst neu laden müssen.
  Stream<List<Eintrag>> alleEintraegeBeobachten() {
    // `select(eintraege)` = „wähle Zeilen aus der Tabelle Eintraege“.
    // `..orderBy(...)` sortiert (die zwei Punkte `..` rufen eine Methode auf
    // demselben Objekt auf und geben danach wieder dieses Objekt zurück).
    // `OrderingMode.desc` = absteigend, also neueste zuerst.
    // `.watch()` macht daraus einen Stream statt einer einmaligen Abfrage.
    return (select(eintraege)
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.erstelltAm,
              mode: OrderingMode.desc,
            ),
            // Zweites Sortierkriterium, falls zwei Einträge in derselben
            // Sekunde entstanden sind: die höhere (= neuere) id zuerst.
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Lädt einen einzelnen Eintrag anhand seiner [id].
  /// Gibt `null` zurück, falls es keinen Eintrag mit dieser id gibt.
  ///
  /// `Future` bedeutet: Das Ergebnis kommt „in der Zukunft“, weil das Lesen
  /// aus der Datei einen Moment dauert. Mit `await` wartet man darauf.
  Future<Eintrag?> eintragLaden(int id) {
    // `where` filtert: nur die Zeile, deren id gleich der gesuchten ist.
    // `getSingleOrNull` liefert genau diese eine Zeile – oder null.
    return (select(eintraege)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Liefert den Eintrag, an dem du zuletzt geschrieben hast – aber NUR, wenn
  /// das weniger als [weiterschreibZeitfenster] (15 Minuten) her ist.
  /// Sonst `null`, und die App beginnt mit einer neuen, leeren Seite.
  Future<Eintrag?> eintragZumWeiterschreiben() async {
    // Den zuletzt geänderten Eintrag suchen: nach `geaendertAm` absteigend
    // sortieren und mit `limit(1)` nur den obersten nehmen.
    final letzter =
        await (select(eintraege)
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.geaendertAm,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    // Gibt es gar keinen Eintrag, gibt es auch nichts weiterzuschreiben.
    if (letzter == null) return null;

    // Wie lange ist die letzte Änderung her?
    final vergangen = _uhr().difference(letzter.geaendertAm);

    // Nur zurückgeben, wenn es innerhalb des Zeitfensters liegt.
    return vergangen < weiterschreibZeitfenster ? letzter : null;
  }

  // ---------------------------------------------------------------------------
  // SCHREIBEN
  // ---------------------------------------------------------------------------

  /// Speichert einen Text – die zentrale Funktion für den Schreib-Bildschirm.
  ///
  /// Sie entscheidet selbst, was zu tun ist:
  /// - [id] ist `null` (neue Seite) und Text vorhanden → neuen Eintrag anlegen.
  /// - [id] ist `null` und Text leer → nichts tun (keine leeren Einträge!).
  /// - [id] vorhanden und Text vorhanden → bestehenden Eintrag aktualisieren.
  /// - [id] vorhanden, aber Text komplett gelöscht → Eintrag löschen.
  ///
  /// Rückgabe: die id des gespeicherten Eintrags – oder `null`, wenn (danach)
  /// kein Eintrag existiert. Der Schreib-Bildschirm merkt sich diese id, damit
  /// das nächste automatische Speichern denselben Eintrag aktualisiert.
  Future<int?> eintragSpeichern({int? id, required String inhalt}) async {
    // `trim()` entfernt Leerzeichen/Zeilenumbrüche am Anfang und Ende.
    // So zählt ein Text, der nur aus Leerzeichen besteht, als „leer“.
    final istLeer = inhalt.trim().isEmpty;

    if (id == null) {
      if (istLeer) return null;
      return _eintragAnlegen(inhalt);
    }

    if (istLeer) {
      await eintragLoeschen(id);
      return null;
    }

    await _eintragAktualisieren(id, inhalt);
    return id;
  }

  /// Legt einen neuen Eintrag an und gibt seine (automatisch vergebene) id zurück.
  Future<int> _eintragAnlegen(String inhalt) {
    final jetzt = _uhr();
    // Ein „Companion“ ist eine von Drift erzeugte Hilfsklasse, die beschreibt,
    // welche Werte in eine Zeile geschrieben werden sollen. Die id fehlt hier
    // absichtlich – die vergibt die Datenbank selbst.
    return into(eintraege).insert(
      EintraegeCompanion.insert(
        inhalt: inhalt,
        erstelltAm: jetzt,
        geaendertAm: jetzt,
      ),
    );
  }

  /// Ändert den Text eines bestehenden Eintrags und aktualisiert `geaendertAm`.
  /// `erstelltAm` bleibt unverändert.
  Future<void> _eintragAktualisieren(int id, String inhalt) async {
    // `update(...)..where(...)` wählt die zu ändernde Zeile aus,
    // `write(...)` überschreibt nur die angegebenen Spalten.
    // `Value(...)` markiert einen Wert als „bitte setzen“ (im Unterschied zu
    // „nicht anfassen“ – Spalten ohne Angabe bleiben, wie sie sind).
    await (update(eintraege)..where((t) => t.id.equals(id))).write(
      EintraegeCompanion(inhalt: Value(inhalt), geaendertAm: Value(_uhr())),
    );
  }

  /// Löscht den Eintrag mit der angegebenen [id] endgültig.
  Future<void> eintragLoeschen(int id) async {
    await (delete(eintraege)..where((t) => t.id.equals(id))).go();
  }
}
