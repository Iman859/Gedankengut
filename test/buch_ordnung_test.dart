// =============================================================================
// buch_ordnung_test.dart – Tests für die Reihenfolge der Seiten im Buch
// =============================================================================
//
// Prüft die reinen Funktionen aus `lib/daten/buch_ordnung.dart`:
// Sortierung nach Kapiteln, „Lose Blätter“, Kapitelnummern, die Startseite
// und die Kapitelzeile.
//
// Ausführen mit: flutter test
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:gedankengut/daten/buch_ordnung.dart';
import 'package:gedankengut/daten/datenbank.dart';

void main() {
  // Hilfsfunktionen: Testdaten ohne Datenbank erzeugen.
  Eintrag eintrag(int id, DateTime datum, {int? kapitelId}) => Eintrag(
    id: id,
    inhalt: 'Eintrag $id',
    erstelltAm: datum,
    geaendertAm: datum,
    kapitelId: kapitelId,
  );

  Kapitel kapitel(int id, String titel, DateTime angelegt) =>
      Kapitel(id: id, titel: titel, erstelltAm: angelegt);

  final tag1 = DateTime(2026, 11, 20);
  final tag2 = DateTime(2026, 11, 21);
  final tag3 = DateTime(2026, 11, 22);
  final tag4 = DateTime(2026, 11, 23);

  /// Kurzschreibweise: die Eintrags-ids der Seiten in Buch-Reihenfolge.
  List<int> ids(List<BuchSeite> seiten) =>
      seiten.map((s) => s.eintrag.id).toList();

  group('buchSeitenOrdnen', () {
    test('ohne Kapitel: alle Einträge als lose Blätter, nach Datum', () {
      final seiten = buchSeitenOrdnen([
        eintrag(3, tag3),
        eintrag(1, tag1),
        eintrag(2, tag2),
      ], []);

      expect(ids(seiten), [1, 2, 3]);
      expect(seiten.every((s) => s.kapitel == null), isTrue);
    });

    test('erst Kapitel in Anlege-Reihenfolge, dann lose Blätter', () {
      final neuanfaenge = kapitel(10, 'Neuanfänge', tag1);
      final pruefung = kapitel(20, 'Prüfungszeit', tag2);

      final seiten = buchSeitenOrdnen(
        [
          eintrag(1, tag1, kapitelId: 20), // Prüfungszeit
          eintrag(2, tag2), // lose
          eintrag(3, tag3, kapitelId: 10), // Neuanfänge
          eintrag(4, tag4, kapitelId: 10), // Neuanfänge
        ],
        // Absichtlich „falsch herum“ übergeben – die Funktion sortiert selbst.
        [pruefung, neuanfaenge],
      );

      expect(ids(seiten), [3, 4, 1, 2]);
      expect(seiten.map((s) => s.kapitelNummer), [1, 1, 2, null]);
    });

    test('leere Kapitel erscheinen nicht und bekommen keine Nummer', () {
      final seiten = buchSeitenOrdnen(
        [eintrag(1, tag1, kapitelId: 20)],
        [kapitel(10, 'Leer', tag1), kapitel(20, 'Voll', tag2)],
      );

      expect(seiten.single.kapitel?.titel, 'Voll');
      expect(seiten.single.kapitelNummer, 1); // nicht 2!
    });

    test(
      'Eintrag mit unbekanntem Kapitel geht nicht verloren (lose Blätter)',
      () {
        final seiten = buchSeitenOrdnen([eintrag(1, tag1, kapitelId: 99)], []);

        expect(ids(seiten), [1]);
        expect(seiten.single.kapitel, isNull);
      },
    );
  });

  group('indexDesNeuestenEintrags', () {
    test('findet den neuesten Eintrag, auch in einem frühen Kapitel', () {
      final seiten = buchSeitenOrdnen(
        [
          eintrag(1, tag1),
          eintrag(2, tag4, kapitelId: 10), // neuester, steht im Kapitel vorne
        ],
        [kapitel(10, 'Kapitel', tag1)],
      );

      expect(ids(seiten), [2, 1]);
      expect(indexDesNeuestenEintrags(seiten), 0);
    });

    test('leeres Buch → 0', () {
      expect(indexDesNeuestenEintrags([]), 0);
    });
  });

  group('zahlInWorten', () {
    test('1 bis 20 in Worten, danach als Ziffer', () {
      expect(zahlInWorten(1), 'eins');
      expect(zahlInWorten(5), 'fünf');
      expect(zahlInWorten(12), 'zwölf');
      expect(zahlInWorten(20), 'zwanzig');
      expect(zahlInWorten(21), '21');
    });
  });

  group('kapitelZeile', () {
    test('mit Kapitel: Nummer in Worten und Name in Großbuchstaben', () {
      final seite = BuchSeite(
        eintrag: eintrag(1, tag1, kapitelId: 10),
        kapitel: kapitel(10, 'Prüfungszeit', tag1),
        kapitelNummer: 2,
      );
      expect(kapitelZeile(seite), 'KAPITEL ZWEI · PRÜFUNGSZEIT');
    });

    test('ohne Kapitel: „LOSE BLÄTTER“', () {
      expect(
        kapitelZeile(BuchSeite(eintrag: eintrag(1, tag1))),
        'LOSE BLÄTTER',
      );
    });
  });
}
