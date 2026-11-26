// =============================================================================
// migration_test.dart – Tests für das Umbauen der Datenbank bei App-Updates
// =============================================================================
//
// WARUM DIESE TESTS SO WICHTIG SIND:
//   Auf deinem Pixel liegt eine Datenbank im ALTEN Format (Version 1) mit
//   deinen echten Einträgen. Startet die neue App-Version, baut sie diese
//   Datenbank auf Version 2 um („Migration“). Geht dabei etwas schief, wären
//   Einträge weg. Diese Tests spielen genau das vorher durch.
//
// WIE SIE FUNKTIONIEREN:
//   Das Migrations-Werkzeug (`dart run drift_dev make-migrations`) hat zu
//   jeder Version einen Schnappschuss gespeichert (`drift_schemas/`) und
//   daraus Hilfsdateien in `generated/` erzeugt (nie von Hand ändern!).
//   Damit kann ein Test eine Datenbank im exakten Aufbau von Version 1
//   anlegen, sie mit unserer App-Datenbank öffnen (→ Migration läuft) und
//   anschließend prüfen, ob der Aufbau stimmt und alle Daten noch da sind.
//
// Diese Datei ist aus der Vorlage des Werkzeugs entstanden und angepasst.
// Ausführen mit: flutter test
// =============================================================================

// `ignore_for_file`: Die Vorlage importiert alle Versionen, auch wenn nicht
// jede in jedem Test gebraucht wird – das ist hier gewollt.
// ignore_for_file: unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gedankengut/daten/datenbank.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  // Drift warnt sonst, weil in Tests mehrere Datenbanken gleichzeitig offen
  // sind (alte + neue Version). Das ist hier Absicht.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  /// Der „Prüfer“, der Datenbanken in alten Versionen erzeugen und den
  /// Aufbau nach der Migration mit dem Schnappschuss vergleichen kann.
  late SchemaVerifier pruefer;

  setUpAll(() {
    pruefer = SchemaVerifier(GeneratedHelper());
  });

  /// Öffnet UNSERE App-Datenbank auf einer vorgegebenen Verbindung.
  /// (Unser Konstruktor hat benannte Parameter, die Vorlage erwartete einen
  /// Positionsparameter – daher diese kleine Übersetzungsfunktion.)
  GedankengutDatenbank appDatenbank(QueryExecutor verbindung) =>
      GedankengutDatenbank(verbindung: verbindung);

  group('Aufbau nach der Migration', () {
    // Für jede mögliche Kombination „von Version X auf neuere Version Y“:
    // leere alte Datenbank anlegen, migrieren, Aufbau prüfen.
    const versionen = GeneratedHelper.versions;
    for (final (i, vonVersion) in versionen.indexed) {
      group('von Version $vonVersion', () {
        for (final zuVersion in versionen.skip(i + 1)) {
          test('auf Version $zuVersion', () async {
            final schema = await pruefer.schemaAt(vonVersion);
            final db = appDatenbank(schema.newConnection());
            // `migrateAndValidate` migriert und vergleicht den entstandenen
            // Aufbau mit dem gespeicherten Schnappschuss der Zielversion.
            await pruefer.migrateAndValidate(db, zuVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('Version 1 → 2: alle bisherigen Einträge bleiben unverändert erhalten',
      () async {
    // Zeitpunkte werden in Version 1 als Sekunden seit 1.1.1970 gespeichert.
    final montag =
        DateTime(2026, 11, 23, 21, 0).millisecondsSinceEpoch ~/ 1000;
    final dienstag =
        DateTime(2026, 11, 24, 23, 5).millisecondsSinceEpoch ~/ 1000;

    // So sehen die Einträge in der ALTEN Datenbank aus …
    final alteEintraege = [
      v1.EintraegeData(
        id: 1,
        inhalt: 'heute beim training wieder dieses gefühl …',
        erstelltAm: montag,
        geaendertAm: montag,
      ),
      v1.EintraegeData(
        id: 2,
        inhalt: 'Gespräch mit Mama war besser als gedacht.\nZweiter Absatz.',
        erstelltAm: dienstag,
        geaendertAm: dienstag + 120,
      ),
    ];

    // … und so müssen sie NACH der Migration aussehen: gleiche Werte,
    // die neuen Felder (Titel, Kapitel, Buch-Fassung) leer.
    final erwarteteEintraege = [
      for (final alt in alteEintraege)
        v2.EintraegeData(
          id: alt.id,
          inhalt: alt.inhalt,
          erstelltAm: alt.erstelltAm,
          geaendertAm: alt.geaendertAm,
          titel: null,
          kapitelId: null,
          buchFassung: null,
          buchFassungAm: null,
        ),
    ];

    await pruefer.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: appDatenbank,
      // Alte Datenbank mit den Einträgen füllen.
      createItems: (stapel, alteDb) {
        stapel.insertAll(alteDb.eintraege, alteEintraege);
      },
      // Nach der Migration: Stimmen alle Einträge exakt?
      validateItems: (neueDb) async {
        expect(await neueDb.select(neueDb.eintraege).get(), erwarteteEintraege);
        // Die neue Kapitel-Tabelle existiert und ist leer.
        expect(await neueDb.select(neueDb.kapitel).get(), isEmpty);
      },
    );
  });
}
