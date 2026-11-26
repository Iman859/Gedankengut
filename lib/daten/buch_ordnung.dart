// =============================================================================
// buch_ordnung.dart – In welcher Reihenfolge stehen die Seiten im Buch?
// =============================================================================
//
// Das Buch ist die GEORDNETE Fassung deines Tagebuchs (die Übersicht bleibt
// der Zeitstrahl). Die Ordnung (Entscheidung 2e, „3B“):
//
//   Kapitel eins   → seine Einträge, nach Datum
//   Kapitel zwei   → seine Einträge, nach Datum
//   …
//   Lose Blätter   → alle Einträge ohne Kapitel, nach Datum
//
// Die Kapitel stehen in der Reihenfolge, in der sie angelegt wurden
// (Entscheidung „2A“). Später ordnet die KI die Einträge den Kapiteln zu.
//
// Diese Datei enthält nur „reine“ Funktionen: Sie bekommen Listen hinein,
// rechnen und geben ein Ergebnis zurück – ohne Datenbank und ohne Oberfläche.
// Dadurch lassen sie sich sehr einfach und gründlich testen.
// =============================================================================

import 'datenbank.dart';

/// Eine Seite im Buch: ein Eintrag plus das Kapitel, in dem er steht.
class BuchSeite {
  const BuchSeite({required this.eintrag, this.kapitel, this.kapitelNummer});

  /// Der Eintrag auf dieser Seite.
  final Eintrag eintrag;

  /// Das Kapitel der Seite – `null` = „Lose Blätter“ (kein Kapitel).
  final Kapitel? kapitel;

  /// Nummer des Kapitels im Buch (1 = erstes Kapitel) – `null` bei losen
  /// Blättern.
  final int? kapitelNummer;
}

/// Ordnet alle [eintraege] zu Buchseiten (siehe Erklärung oben).
///
/// KAPITELNUMMERN: Gezählt werden nur Kapitel, die auch Seiten haben. Ein
/// (noch) leeres Kapitel erscheint nicht im Buch und bekommt keine Nummer –
/// so gibt es nie ein „Kapitel drei“, das gar nicht zu sehen ist.
///
/// Einträge, deren Kapitel es nicht (mehr) gibt, landen sicherheitshalber
/// ebenfalls bei den losen Blättern – es geht nie eine Seite verloren.
List<BuchSeite> buchSeitenOrdnen(
  List<Eintrag> eintraege,
  List<Kapitel> kapitel,
) {
  // Einträge nach Datum sortieren (älteste zuerst; bei Gleichstand die id).
  // `[...liste]` erzeugt eine Kopie, damit die Original-Liste unverändert bleibt.
  final chronologisch = [...eintraege]
    ..sort((a, b) {
      final vergleich = a.erstelltAm.compareTo(b.erstelltAm);
      return vergleich != 0 ? vergleich : a.id.compareTo(b.id);
    });

  // Kapitel in Buch-Reihenfolge (nach Anlegedatum, bei Gleichstand die id).
  final kapitelSortiert = [...kapitel]
    ..sort((a, b) {
      final vergleich = a.erstelltAm.compareTo(b.erstelltAm);
      return vergleich != 0 ? vergleich : a.id.compareTo(b.id);
    });

  final seiten = <BuchSeite>[];
  final vergebeneEintraege = <int>{}; // ids, die schon einsortiert sind
  var nummer = 0;

  for (final k in kapitelSortiert) {
    // `where` filtert: nur die Einträge dieses Kapitels.
    final inhalt = chronologisch.where((e) => e.kapitelId == k.id).toList();
    if (inhalt.isEmpty) continue; // leeres Kapitel → nicht im Buch

    nummer++;
    for (final e in inhalt) {
      seiten.add(BuchSeite(eintrag: e, kapitel: k, kapitelNummer: nummer));
      vergebeneEintraege.add(e.id);
    }
  }

  // Alles, was noch übrig ist, sind die „Losen Blätter“.
  for (final e in chronologisch) {
    if (!vergebeneEintraege.contains(e.id)) {
      seiten.add(BuchSeite(eintrag: e));
    }
  }
  return seiten;
}

/// Findet die Position (0 = erste Seite) des NEUESTEN Eintrags im Buch –
/// dort öffnet sich das Buch. Bei leerem Buch: 0.
int indexDesNeuestenEintrags(List<BuchSeite> seiten) {
  var bester = 0;
  for (var i = 1; i < seiten.length; i++) {
    final kandidat = seiten[i].eintrag;
    final bisher = seiten[bester].eintrag;
    final neuer =
        kandidat.erstelltAm.isAfter(bisher.erstelltAm) ||
        (kandidat.erstelltAm == bisher.erstelltAm && kandidat.id > bisher.id);
    if (neuer) bester = i;
  }
  return bester;
}

/// Schreibt eine Zahl in Worten aus: 1 → „eins“, 3 → „drei“ … 20 → „zwanzig“.
/// Ab 21 wird die Zahl als Ziffer zurückgegeben (z. B. „21“).
String zahlInWorten(int zahl) {
  const woerter = [
    'eins',
    'zwei',
    'drei',
    'vier',
    'fünf',
    'sechs',
    'sieben',
    'acht',
    'neun',
    'zehn',
    'elf',
    'zwölf',
    'dreizehn',
    'vierzehn',
    'fünfzehn',
    'sechzehn',
    'siebzehn',
    'achtzehn',
    'neunzehn',
    'zwanzig',
  ];
  if (zahl >= 1 && zahl <= woerter.length) return woerter[zahl - 1];
  return '$zahl';
}

/// Die Kapitelzeile oben auf einer Buchseite, z. B.
/// „KAPITEL ZWEI · PRÜFUNGSZEIT“ – oder „LOSE BLÄTTER“ ohne Kapitel.
String kapitelZeile(BuchSeite seite) {
  final k = seite.kapitel;
  final nummer = seite.kapitelNummer;
  if (k == null || nummer == null) return 'LOSE BLÄTTER';
  return 'KAPITEL ${zahlInWorten(nummer)} · ${k.titel}'.toUpperCase();
}
