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

// Vom Migrations-Werkzeug erzeugte Hilfen (`stepByStep`, Aufbau jeder
// Datenbank-Version). Nie von Hand ändern – siehe build.yaml.
import 'datenbank.steps.dart';

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
  /// WICHTIG: Zählt NUR dein eigenes Schreiben – Titel, Kapitel oder
  /// Buch-Fassung zu setzen ändert dieses Datum NICHT.
  DateTimeColumn get geaendertAm => dateTime()();

  // --- NEU in Datenbank-Version 2 (alle optional = `nullable()`) ------------
  // „nullable“ heißt: Das Feld darf leer sein (`null`). Das ist wichtig für
  // die Migration – bestehende Einträge haben diese Felder ja noch nicht.

  /// Titel des Eintrags im Buch (z. B. „Die leise Frage“). Später von der
  /// KI vorgeschlagen; leer = Buch zeigt das Datum als Titel.
  TextColumn get titel => text().nullable()();

  /// Zu welchem Kapitel der Eintrag gehört (die `id` aus der Kapitel-Tabelle).
  ///
  /// `references(...)` macht daraus einen „Fremdschlüssel“: Die Datenbank
  /// prüft, dass es das Kapitel wirklich gibt. `onDelete: setNull` heißt:
  /// Wird das Kapitel gelöscht, wird dieses Feld automatisch geleert – der
  /// Eintrag selbst bleibt erhalten.
  IntColumn get kapitelId => integer()
      .nullable()
      .references(KapitelTabelle, #id, onDelete: KeyAction.setNull)();

  /// Die BUCH-FASSUNG: die geordnete, korrigierte, schön formatierte Version
  /// des Eintrags (später von der KI erstellt). Die Rohfassung in [inhalt]
  /// bleibt davon IMMER unberührt.
  TextColumn get buchFassung => text().nullable()();

  /// Wann die Buch-Fassung erstellt wurde. Ist die Rohfassung danach noch
  /// geändert worden (`geaendertAm` später), ist die Buch-Fassung veraltet.
  DateTimeColumn get buchFassungAm => dateTime().nullable()();
}

// -----------------------------------------------------------------------------
// TABELLE: Kapitel (NEU in Datenbank-Version 2)
// -----------------------------------------------------------------------------

/// Die Kapitel des Buches (z. B. „Neuanfänge“, „Prüfungszeit“).
///
/// Namensgebung: Im Deutschen heißt Einzahl und Mehrzahl „Kapitel“. Damit
/// sich die Tabelle (`KapitelTabelle`) und eine einzelne Zeile (`Kapitel`)
/// im Code trotzdem unterscheiden, heißt die Klasse hier `KapitelTabelle`.
/// In der Datenbank-Datei heißt die Tabelle einfach `kapitel` (siehe
/// [tableName]).
///
/// Reihenfolge der Kapitel im Buch = nach [erstelltAm] (Entscheidung 2e:
/// das zuerst angelegte Kapitel ist Kapitel eins).
@DataClassName('Kapitel')
class KapitelTabelle extends Table {
  /// Name der Tabelle in der Datenbank-Datei.
  @override
  String get tableName => 'kapitel';

  /// Eindeutige Nummer des Kapitels (automatisch vergeben).
  IntColumn get id => integer().autoIncrement()();

  /// Name des Kapitels, z. B. „Neuanfänge“.
  TextColumn get titel => text()();

  /// Wann das Kapitel angelegt wurde (bestimmt die Reihenfolge im Buch).
  DateTimeColumn get erstelltAm => dateTime()();
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
@DriftDatabase(tables: [Eintraege, KapitelTabelle])
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
  ///
  /// Verlauf:
  ///   1 = Einträge (id, inhalt, erstelltAm, geaendertAm)
  ///   2 = + Kapitel-Tabelle, + titel / kapitelId / buchFassung /
  ///       buchFassungAm in den Einträgen
  ///
  /// Bei jeder Änderung am Aufbau wird diese Zahl erhöht und unten in
  /// [migration] beschrieben, wie eine ältere Datenbank umgebaut wird –
  /// damit deine bisherigen Einträge beim Update erhalten bleiben.
  @override
  int get schemaVersion => 2;

  /// Die „Migration“: beschreibt, wie die Datenbank angelegt bzw. von einer
  /// älteren Version auf die aktuelle umgebaut wird.
  ///
  /// - `onCreate`: Bei einer brandneuen Installation werden einfach alle
  ///   Tabellen angelegt.
  /// - `onUpgrade`: Bei einem App-Update mit älterer Datenbank wird Schritt
  ///   für Schritt umgebaut (`stepByStep` stammt aus der vom
  ///   Migrations-Werkzeug erzeugten Datei `datenbank.steps.dart`). Jeder
  ///   Schritt bekommt dabei den genauen Aufbau der Zielversion (`schema`),
  ///   so bleibt er auch dann richtig, wenn sich der Code später weiter ändert.
  /// - `beforeOpen`: Läuft bei JEDEM Öffnen. Schaltet die Prüfung von
  ///   Fremdschlüsseln ein (SQLite macht das nicht von selbst) – nötig, damit
  ///   „Kapitel löschen → Zuordnung leeren“ automatisch funktioniert.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: stepByStep(
          // Version 1 → 2: Kapitel-Tabelle anlegen und die vier neuen,
          // optionalen Felder an die Einträge anhängen. Bestehende Einträge
          // bleiben unverändert – ihre neuen Felder sind einfach leer.
          from1To2: (m, schema) async {
            await m.createTable(schema.kapitel);
            await m.addColumn(schema.eintraege, schema.eintraege.titel);
            await m.addColumn(schema.eintraege, schema.eintraege.kapitelId);
            await m.addColumn(schema.eintraege, schema.eintraege.buchFassung);
            await m.addColumn(schema.eintraege, schema.eintraege.buchFassungAm);
          },
        ),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

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

  // ---------------------------------------------------------------------------
  // TITEL & BUCH-FASSUNG (NEU in Version 2)
  // ---------------------------------------------------------------------------
  // GRUNDREGEL: Keine dieser Funktionen verändert die Rohfassung (`inhalt`)
  // oder `geaendertAm`. `geaendertAm` zählt nur DEIN Schreiben – sonst würde
  // z. B. das Setzen eines Titels die 15-Minuten-Regel auslösen.

  /// Setzt den Titel eines Eintrags. Leerer Text (oder `null`) entfernt ihn.
  Future<void> eintragTitelSetzen(int id, String? titel) async {
    final sauber = titel?.trim();
    await (update(eintraege)..where((t) => t.id.equals(id))).write(
      EintraegeCompanion(
        titel: Value(sauber == null || sauber.isEmpty ? null : sauber),
      ),
    );
  }

  /// Ordnet einen Eintrag einem Kapitel zu. `null` = keinem Kapitel
  /// (der Eintrag landet im Buch dann unter „Lose Blätter“).
  Future<void> eintragKapitelSetzen(int id, int? kapitelId) async {
    await (update(eintraege)..where((t) => t.id.equals(id))).write(
      EintraegeCompanion(kapitelId: Value(kapitelId)),
    );
  }

  /// Speichert die Buch-Fassung eines Eintrags (später: Ergebnis der KI)
  /// und merkt sich den Zeitpunkt. `null` entfernt die Buch-Fassung wieder.
  Future<void> buchFassungSpeichern(int id, String? buchFassung) async {
    final sauber = buchFassung?.trim();
    final vorhanden = sauber != null && sauber.isNotEmpty;
    await (update(eintraege)..where((t) => t.id.equals(id))).write(
      EintraegeCompanion(
        buchFassung: Value(vorhanden ? sauber : null),
        buchFassungAm: Value(vorhanden ? _uhr() : null),
      ),
    );
  }

  /// Ist die Buch-Fassung dieses Eintrags veraltet? Das ist der Fall, wenn du
  /// die Rohfassung NACH dem Erstellen der Buch-Fassung noch geändert hast.
  ///
  /// `static` = gehört zur Klasse, braucht keine Datenbank-Verbindung – es
  /// wird nur der übergebene Eintrag angeschaut.
  static bool buchFassungVeraltet(Eintrag eintrag) {
    final erstellt = eintrag.buchFassungAm;
    if (eintrag.buchFassung == null || erstellt == null) return false;
    return eintrag.geaendertAm.isAfter(erstellt);
  }

  // ---------------------------------------------------------------------------
  // KAPITEL (NEU in Version 2)
  // ---------------------------------------------------------------------------

  /// Liefert alle Kapitel in Buch-Reihenfolge (zuerst angelegt = Kapitel
  /// eins) als Stream – aktualisiert sich automatisch bei Änderungen.
  Stream<List<Kapitel>> alleKapitelBeobachten() {
    return (select(kapitelTabelle)
          ..orderBy([
            (k) => OrderingTerm(expression: k.erstelltAm),
            // Bei gleicher Sekunde entscheidet die (aufsteigende) id.
            (k) => OrderingTerm(expression: k.id),
          ]))
        .watch();
  }

  /// Legt ein neues Kapitel an und gibt seine id zurück.
  Future<int> kapitelAnlegen(String titel) {
    return into(kapitelTabelle).insert(
      KapitelTabelleCompanion.insert(titel: titel.trim(), erstelltAm: _uhr()),
    );
  }

  /// Gibt einem Kapitel einen neuen Namen.
  Future<void> kapitelUmbenennen(int id, String titel) async {
    await (update(kapitelTabelle)..where((k) => k.id.equals(id))).write(
      KapitelTabelleCompanion(titel: Value(titel.trim())),
    );
  }

  /// Löscht ein Kapitel. Die Einträge darin bleiben ERHALTEN – sie verlieren
  /// nur ihre Zuordnung (und stehen im Buch dann unter „Lose Blätter“).
  ///
  /// Die Datenbank würde die Zuordnung dank Fremdschlüssel ohnehin leeren;
  /// wir machen es zusätzlich ausdrücklich, damit es garantiert passiert.
  /// `transaction` = alles oder nichts: Beide Schritte gelingen gemeinsam,
  /// oder keiner (z. B. falls die App mittendrin beendet wird).
  Future<void> kapitelLoeschen(int id) async {
    await transaction(() async {
      await (update(eintraege)..where((t) => t.kapitelId.equals(id))).write(
        const EintraegeCompanion(kapitelId: Value(null)),
      );
      await (delete(kapitelTabelle)..where((k) => k.id.equals(id))).go();
    });
  }
}
