// =============================================================================
// datenbank_test.dart – Tests für die Datenbank
// =============================================================================
//
// Diese Tests prüfen, ob das Speichern, Ändern, Löschen und Sortieren von
// Einträgen richtig funktioniert. Die Datenbank liegt dabei NUR im
// Arbeitsspeicher (`NativeDatabase.memory()`), also wird keine echte Datei
// angelegt und jeder Test beginnt mit einer frischen, leeren Datenbank.
//
// Ausführen mit: flutter test
// =============================================================================

// Werkzeuge für Tests (`test`, `expect`, `setUp`, …).
import 'package:flutter_test/flutter_test.dart';

// `NativeDatabase.memory()` – eine Datenbank, die nur im Arbeitsspeicher lebt.
import 'package:drift/native.dart';

// Unsere eigene Datenbank, die wir testen wollen.
import 'package:gedankengut/daten/datenbank.dart';

void main() {
  // `late` heißt: Die Variable bekommt ihren Wert erst später (in `setUp`),
  // aber garantiert, bevor sie benutzt wird.
  late GedankengutDatenbank db;

  // Eine „Test-Uhr“: Wir bestimmen selbst, wie spät es ist.
  // So können wir Zeit vergehen lassen, ohne wirklich zu warten.
  late DateTime testZeit;

  // `setUp` läuft VOR JEDEM einzelnen Test → jeder Test startet frisch.
  setUp(() {
    testZeit = DateTime(2026, 11, 25, 22, 0); // 25.11.2026, 22:00 Uhr
    db = GedankengutDatenbank(
      verbindung: NativeDatabase.memory(),
      // Eine Funktion, die immer die aktuelle Test-Zeit zurückgibt.
      uhr: () => testZeit,
    );
  });

  // `tearDown` läuft NACH JEDEM Test → Datenbank sauber schließen.
  tearDown(() async {
    await db.close();
  });

  // `group` fasst zusammengehörige Tests unter einer Überschrift zusammen.
  group('eintragSpeichern', () {
    test('legt einen neuen Eintrag an, wenn noch keine id existiert', () async {
      final id = await db.eintragSpeichern(inhalt: 'Mein erster Gedanke');

      // Es muss eine id zurückkommen …
      expect(id, isNotNull);
      // … und der Eintrag muss mit genau diesem Text in der Datenbank stehen.
      final eintrag = await db.eintragLaden(id!);
      expect(eintrag?.inhalt, 'Mein erster Gedanke');
      expect(eintrag?.erstelltAm, testZeit);
    });

    test('speichert KEINEN leeren Eintrag', () async {
      final id = await db.eintragSpeichern(inhalt: '   \n  ');

      expect(id, isNull);
      // `.first` nimmt den ersten Wert aus dem Stream = aktuelle Liste.
      expect(await db.alleEintraegeBeobachten().first, isEmpty);
    });

    test('aktualisiert einen bestehenden Eintrag (kein Duplikat)', () async {
      final id = await db.eintragSpeichern(inhalt: 'Ent');

      // 5 Minuten später weitergeschrieben:
      testZeit = testZeit.add(const Duration(minutes: 5));
      final gleicheId = await db.eintragSpeichern(id: id, inhalt: 'Entwurf');

      expect(gleicheId, id);
      final alle = await db.alleEintraegeBeobachten().first;
      expect(alle, hasLength(1)); // immer noch nur EIN Eintrag
      expect(alle.single.inhalt, 'Entwurf');
      // erstelltAm bleibt gleich, geaendertAm ist neu:
      expect(alle.single.erstelltAm, DateTime(2026, 11, 25, 22, 0));
      expect(alle.single.geaendertAm, DateTime(2026, 11, 25, 22, 5));
    });

    test('löscht den Eintrag, wenn der ganze Text entfernt wird', () async {
      final id = await db.eintragSpeichern(inhalt: 'Doch nicht');
      final ergebnis = await db.eintragSpeichern(id: id, inhalt: '');

      expect(ergebnis, isNull);
      expect(await db.eintragLaden(id!), isNull);
    });
  });

  group('alleEintraegeBeobachten', () {
    test('liefert die neuesten Einträge zuerst', () async {
      await db.eintragSpeichern(inhalt: 'Montag');
      testZeit = testZeit.add(const Duration(days: 1));
      await db.eintragSpeichern(inhalt: 'Dienstag');

      final alle = await db.alleEintraegeBeobachten().first;
      // `map` wandelt jeden Eintrag in seinen Text um → ['Dienstag', 'Montag']
      expect(alle.map((e) => e.inhalt), ['Dienstag', 'Montag']);
    });
  });

  group('eintragZumWeiterschreiben (15-Minuten-Regel)', () {
    test('liefert den letzten Eintrag, wenn er < 15 Minuten alt ist', () async {
      final id = await db.eintragSpeichern(inhalt: 'Gerade unterbrochen');
      testZeit = testZeit.add(const Duration(minutes: 14));

      final eintrag = await db.eintragZumWeiterschreiben();
      expect(eintrag?.id, id);
    });

    test('liefert null, wenn die letzte Änderung >= 15 Minuten her ist',
        () async {
      await db.eintragSpeichern(inhalt: 'Von vorhin');
      testZeit = testZeit.add(const Duration(minutes: 15));

      expect(await db.eintragZumWeiterschreiben(), isNull);
    });

    test('liefert null, wenn es noch gar keine Einträge gibt', () async {
      expect(await db.eintragZumWeiterschreiben(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // NEU in Version 2: Titel, Buch-Fassung, Kapitel
  // ---------------------------------------------------------------------------

  group('Titel und Buch-Fassung', () {
    test('Titel setzen und wieder entfernen – Rohfassung bleibt unberührt',
        () async {
      final id = await db.eintragSpeichern(inhalt: 'rohe gedanken');

      await db.eintragTitelSetzen(id!, '  Die leise Frage  ');
      var eintrag = await db.eintragLaden(id);
      expect(eintrag?.titel, 'Die leise Frage'); // Leerzeichen entfernt
      expect(eintrag?.inhalt, 'rohe gedanken'); // Rohfassung unverändert

      await db.eintragTitelSetzen(id, '   '); // leer = entfernen
      eintrag = await db.eintragLaden(id);
      expect(eintrag?.titel, isNull);
    });

    test('Titel, Kapitel und Buch-Fassung ändern NICHT das Änderungsdatum',
        () async {
      final id = await db.eintragSpeichern(inhalt: 'rohe gedanken');
      final kapitelId = await db.kapitelAnlegen('Neuanfänge');

      // Eine Stunde später: nur „Metadaten“ setzen.
      testZeit = testZeit.add(const Duration(hours: 1));
      await db.eintragTitelSetzen(id!, 'Titel');
      await db.eintragKapitelSetzen(id, kapitelId);
      await db.buchFassungSpeichern(id, 'Schöne Fassung.');

      final eintrag = await db.eintragLaden(id);
      // geaendertAm ist noch der ursprüngliche Zeitpunkt (22:00 Uhr).
      expect(eintrag?.geaendertAm, DateTime(2026, 11, 25, 22, 0));
    });

    test('Buch-Fassung wird mit Zeitpunkt gespeichert', () async {
      final id = await db.eintragSpeichern(inhalt: 'heute war gut');
      testZeit = testZeit.add(const Duration(minutes: 30));

      await db.buchFassungSpeichern(id!, 'Heute war ein guter Tag.');

      final eintrag = await db.eintragLaden(id);
      expect(eintrag?.buchFassung, 'Heute war ein guter Tag.');
      expect(eintrag?.buchFassungAm, DateTime(2026, 11, 25, 22, 30));
      expect(eintrag?.inhalt, 'heute war gut'); // Rohfassung bleibt
    });

    test('Buch-Fassung ist veraltet, wenn die Rohfassung danach geändert wurde',
        () async {
      final id = await db.eintragSpeichern(inhalt: 'erste fassung');
      testZeit = testZeit.add(const Duration(minutes: 5));
      await db.buchFassungSpeichern(id!, 'Erste Fassung.');

      var eintrag = await db.eintragLaden(id);
      expect(GedankengutDatenbank.buchFassungVeraltet(eintrag!), isFalse);

      // Später weitergeschrieben → Buch-Fassung passt nicht mehr.
      testZeit = testZeit.add(const Duration(minutes: 5));
      await db.eintragSpeichern(id: id, inhalt: 'erste fassung und mehr');

      eintrag = await db.eintragLaden(id);
      expect(GedankengutDatenbank.buchFassungVeraltet(eintrag!), isTrue);
    });

    test('ohne Buch-Fassung ist nichts veraltet', () async {
      final id = await db.eintragSpeichern(inhalt: 'nur roh');
      final eintrag = await db.eintragLaden(id!);
      expect(GedankengutDatenbank.buchFassungVeraltet(eintrag!), isFalse);
    });
  });

  group('Kapitel', () {
    test('werden in der Reihenfolge des Anlegens geliefert', () async {
      await db.kapitelAnlegen('Neuanfänge');
      testZeit = testZeit.add(const Duration(days: 1));
      await db.kapitelAnlegen('Prüfungszeit');

      final kapitel = await db.alleKapitelBeobachten().first;
      expect(kapitel.map((k) => k.titel), ['Neuanfänge', 'Prüfungszeit']);
    });

    test('lassen sich umbenennen', () async {
      final id = await db.kapitelAnlegen('Neuanfang');
      await db.kapitelUmbenennen(id, 'Neuanfänge');

      final kapitel = await db.alleKapitelBeobachten().first;
      expect(kapitel.single.titel, 'Neuanfänge');
    });

    test('Löschen eines Kapitels behält seine Einträge (nur ohne Zuordnung)',
        () async {
      final kapitelId = await db.kapitelAnlegen('Prüfungszeit');
      final eintragId = await db.eintragSpeichern(inhalt: 'Drei Abgaben …');
      await db.eintragKapitelSetzen(eintragId!, kapitelId);
      expect((await db.eintragLaden(eintragId))?.kapitelId, kapitelId);

      await db.kapitelLoeschen(kapitelId);

      final eintrag = await db.eintragLaden(eintragId);
      expect(eintrag, isNotNull); // Eintrag ist noch da …
      expect(eintrag?.inhalt, 'Drei Abgaben …');
      expect(eintrag?.kapitelId, isNull); // … nur ohne Kapitel.
      expect(await db.alleKapitelBeobachten().first, isEmpty);
    });

    test('Zuordnung zu einem nicht existierenden Kapitel wird abgelehnt',
        () async {
      // Der Fremdschlüssel schützt vor „Geister-Kapiteln“.
      final eintragId = await db.eintragSpeichern(inhalt: 'Test');
      expect(
        () => db.eintragKapitelSetzen(eintragId!, 999),
        throwsA(anything),
      );
    });
  });
}
