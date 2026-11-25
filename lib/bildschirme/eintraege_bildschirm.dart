// =============================================================================
// eintraege_bildschirm.dart – Die Übersicht aller Einträge
// =============================================================================
//
// Zeigt alle Einträge, die neuesten oben, nach MONATEN gruppiert. Von hier
// aus kannst du:
//   - einen Eintrag ANTIPPEN → er öffnet sich auf der Schreibseite,
//   - einen Eintrag nach LINKS WISCHEN → löschen (mit Sicherheitsabfrage).
//
// AUSSEHEN (Design „Neon-Eleganz“, Phase 2c):
//   Punktraster im Hintergrund, Buchrücken-Linie, Neon-Knopf „Zurück“, Titel
//   in Bodoni kursiv, leuchtende Monatsüberschriften, Karten mit großer
//   Tageszahl – der neueste Eintrag mit Leuchtrand.
//
// WICHTIGE BAUSTEINE IN DIESER DATEI:
//   - `StreamBuilder`: Ein Widget, das einen Stream „abonniert“ und sich
//     automatisch neu zeichnet, sobald neue Daten kommen. Wird ein Eintrag
//     gelöscht, verschwindet er dadurch von selbst aus der Liste.
//   - `Navigator`: Flutters „Bildschirm-Stapel“. Neue Bildschirme werden
//     oben auf den Stapel gelegt (`push`), mit `pop` wird der oberste wieder
//     entfernt – dabei kann man ein Ergebnis zurückgeben. Wir geben die id
//     des angetippten Eintrags an die Schreibseite zurück.
//   - `Dismissible`: Macht ein Listenelement „wegwischbar“.
// =============================================================================

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../daten/datenbank.dart';
import '../design/farben.dart';
import '../design/leuchtlinien.dart';
import '../design/neon_knopf.dart';
import '../design/punktraster.dart';
import '../design/schriften.dart';

// -----------------------------------------------------------------------------
// HILFSFUNKTIONEN (rein rechnerisch, ohne Oberfläche – daher leicht testbar)
// -----------------------------------------------------------------------------

/// Eine Monatsgruppe: der Monat und alle Einträge daraus.
///
/// `typedef` gibt einem Typ einen eigenen Namen. Hier ist es ein „Record“ –
/// ein kleines Paket aus zwei benannten Werten, ohne eigene Klasse.
typedef MonatsGruppe = ({DateTime monat, List<Eintrag> eintraege});

/// Teilt eine (neueste zuerst sortierte) Liste von Einträgen in Monate auf.
///
/// Beispiel: Einträge vom 25.11., 24.11. und 30.10. ergeben zwei Gruppen:
/// November (2 Einträge) und Oktober (1 Eintrag). Die Reihenfolge bleibt.
List<MonatsGruppe> monateGruppieren(List<Eintrag> eintraege) {
  final gruppen = <MonatsGruppe>[];
  for (final eintrag in eintraege) {
    // Der Monat eines Eintrags = 1. Tag seines Monats (Tag/Uhrzeit egal).
    final monat = DateTime(eintrag.erstelltAm.year, eintrag.erstelltAm.month);
    // Gehört der Eintrag zum selben Monat wie die letzte Gruppe? Dann dazu,
    // sonst eine neue Gruppe beginnen.
    if (gruppen.isNotEmpty && gruppen.last.monat == monat) {
      gruppen.last.eintraege.add(eintrag);
    } else {
      gruppen.add((monat: monat, eintraege: [eintrag]));
    }
  }
  return gruppen;
}

/// Baut die Zeile unter dem Titel, z. B. „12 SEITEN · SEIT NOVEMBER“.
///
/// Die Jahreszahl wird nur angehängt, wenn der älteste Eintrag aus einem
/// anderen Jahr stammt als der neueste (z. B. „SEIT DEZEMBER 2025“).
/// Erwartet die Einträge neueste zuerst (wie sie aus der Datenbank kommen).
String uebersichtUntertitel(List<Eintrag> eintraege) {
  if (eintraege.isEmpty) return '';
  final anzahl = eintraege.length;
  final seiten = anzahl == 1 ? '1 SEITE' : '$anzahl SEITEN';

  final neuester = eintraege.first.erstelltAm;
  final aeltester = eintraege.last.erstelltAm;
  final format = aeltester.year == neuester.year ? 'MMMM' : 'MMMM y';
  final seit = DateFormat(format, 'de_DE').format(aeltester).toUpperCase();

  return '$seiten · SEIT $seit';
}

// -----------------------------------------------------------------------------
// DER BILDSCHIRM
// -----------------------------------------------------------------------------

/// Die Übersicht – ein StatefulWidget, weil sie sich ein paar Dinge merken
/// muss (den Stream und frisch weggewischte Einträge, siehe unten).
class EintraegeBildschirm extends StatefulWidget {
  const EintraegeBildschirm({super.key, required this.datenbank});

  /// Die Datenbank, aus der die Einträge gelesen werden.
  final GedankengutDatenbank datenbank;

  /// Text, der erscheint, wenn es noch keine Einträge gibt.
  static const String leerText =
      'Noch keine Einträge.\nDein Buch wartet auf seine erste Seite.';

  @override
  State<EintraegeBildschirm> createState() => _EintraegeBildschirmState();
}

class _EintraegeBildschirmState extends State<EintraegeBildschirm> {
  /// Der Stream mit allen Einträgen. Wir erzeugen ihn EINMAL in `initState`
  /// (statt in `build`), weil `build` oft aufgerufen wird und sonst jedes Mal
  /// eine neue Datenbank-Abfrage starten würde.
  late final Stream<List<Eintrag>> _eintraege;

  /// ids von Einträgen, die gerade weggewischt wurden.
  ///
  /// Warum? `Dismissible` verlangt, dass ein weggewischtes Element SOFORT aus
  /// der Liste verschwindet. Die Datenbank meldet die Löschung aber erst einen
  /// Augenblick später über den Stream. Diese Menge überbrückt die Lücke:
  /// Was hier drinsteht, blenden wir sofort aus.
  /// Ein `Set` ist eine Sammlung ohne Duplikate – ideal für „ist drin / nicht drin“.
  final Set<int> _weggewischteIds = {};

  @override
  void initState() {
    super.initState();
    _eintraege = widget.datenbank.alleEintraegeBeobachten();
  }

  /// Zeigt die Sicherheitsabfrage vor dem Löschen.
  /// Gibt `true` zurück, wenn wirklich gelöscht werden soll.
  /// (Das Aussehen des Dialogs kommt aus dem Theme, siehe thema.dart.)
  Future<bool> _loeschenBestaetigen() async {
    // `showDialog` öffnet ein Dialogfenster über dem Bildschirm und wartet,
    // bis es geschlossen wird. Der Wert, der beim Schließen an `pop`
    // übergeben wird, ist das Ergebnis.
    final bestaetigt = await showDialog<bool>(
      context: context,
      // `dialogContext` ist der Kontext INNERHALB des Dialogs – mit ihm
      // schließen wir genau den Dialog (und nicht die ganze Übersicht).
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text('Das kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    // Wird der Dialog anders geschlossen (z. B. daneben tippen), kommt `null`
    // zurück – das werten wir als „nicht löschen“.
    return bestaetigt ?? false;
  }

  /// Macht aus dem Eintragstext eine kurze, einzeilige Vorschau:
  /// Leerzeichen am Rand weg, Zeilenumbrüche und mehrfache Leerzeichen
  /// werden zu einem einzigen Leerzeichen.
  /// `RegExp(r'\s+')` ist ein Suchmuster: „ein oder mehrere Leerraum-Zeichen“.
  String _vorschau(String inhalt) =>
      inhalt.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Aufbau in Ebenen (wie auf der Schreibseite): Punktraster → Buchrücken →
  /// Inhalt (Zurück-Knopf fest oben, darunter die scrollbare Liste).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: Punktraster()),
          const Buchruecken(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Der Zurück-Knopf bleibt beim Scrollen oben stehen.
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 12, 16, 4),
                  child: NeonKnopf(
                    symbol: Icons.chevron_left,
                    hinweis: 'Zurück',
                    // `pop()` ohne Ergebnis = einfach zurück zur Schreibseite.
                    beiDruck: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Eintrag>>(
                    stream: _eintraege,
                    // `builder` wird bei JEDEM neuen Wert aus dem Stream
                    // aufgerufen. `snapshot` („Momentaufnahme“) enthält den
                    // aktuellen Stand.
                    builder: (context, snapshot) {
                      // Noch keine Daten da (die erste Abfrage läuft noch)?
                      // → Vorerst nichts anzeigen; dauert nur einen Moment.
                      if (!snapshot.hasData) return const SizedBox.shrink();

                      // Alle Einträge – ohne die gerade weggewischten.
                      final eintraege = snapshot.data!
                          .where((e) => !_weggewischteIds.contains(e.id))
                          .toList();

                      if (eintraege.isEmpty) return _leererZustand();
                      return _liste(eintraege);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Der Hinweis, wenn es noch keine Einträge gibt.
  Widget _leererZustand() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48, 0, 32, 80),
        child: Text(
          EintraegeBildschirm.leerText,
          textAlign: TextAlign.center,
          style: GedankengutSchriften.vorschau.copyWith(
            fontSize: 17,
            color: GedankengutFarben.gedaempft,
          ),
        ),
      ),
    );
  }

  /// Die scrollbare Liste: Titel, dann pro Monat eine Überschrift + Karten.
  Widget _liste(List<Eintrag> eintraege) {
    // Der allererste Eintrag (der neueste) bekommt den Leuchtrand.
    final neuesteId = eintraege.first.id;

    // Wir bauen alle Zeilen der Liste der Reihe nach auf.
    final zeilen = <Widget>[_titel(eintraege)];
    for (final gruppe in monateGruppieren(eintraege)) {
      zeilen.add(_monatsUeberschrift(gruppe.monat));
      for (final eintrag in gruppe.eintraege) {
        zeilen.add(_eintragKarte(eintrag, istNeuester: eintrag.id == neuesteId));
      }
    }

    // `ListView` = scrollbare Liste. Unten etwas Platz, damit die letzte
    // Karte nicht am Bildschirmrand klebt.
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: zeilen,
    );
  }

  /// Der große Titel „Einträge“ mit der Zeile darunter.
  Widget _titel(List<Eintrag> eintraege) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 14, 26, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Einträge', style: GedankengutSchriften.seitenTitel),
          const SizedBox(height: 6),
          Text(
            uebersichtUntertitel(eintraege),
            style: GedankengutSchriften.beschriftung,
          ),
        ],
      ),
    );
  }

  /// Die leuchtende Monatsüberschrift, z. B. „NOVEMBER 2026“.
  Widget _monatsUeberschrift(DateTime monat) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 22, 26, 10),
      child: Text(
        DateFormat('MMMM y', 'de_DE').format(monat).toUpperCase(),
        style: GedankengutSchriften.beschriftungLeuchtend,
      ),
    );
  }

  /// Eine Karte für einen Eintrag – wegwischbar und antippbar.
  Widget _eintragKarte(Eintrag eintrag, {required bool istNeuester}) {
    // Tageszahl („25“) und kurzer Wochentag („MI“).
    // `DateFormat('E')` liefert z. B. „Mi.“ → Punkt weg, Großbuchstaben.
    final tag = DateFormat('d', 'de_DE').format(eintrag.erstelltAm);
    final wochentag = DateFormat('E', 'de_DE')
        .format(eintrag.erstelltAm)
        .replaceAll('.', '')
        .toUpperCase();

    final rundung = BorderRadius.circular(12);

    // Abstand außen um die Karte (links mehr wegen der Buchrücken-Linie).
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 16, 10),
      child: Dismissible(
        // Der `key` muss eindeutig sein, damit Flutter weiß, WELCHES Element
        // weggewischt wurde. Die Datenbank-id ist dafür perfekt.
        key: ValueKey(eintrag.id),
        // Nur nach links wischen (von Ende zu Anfang).
        direction: DismissDirection.endToStart,
        // Was beim Wischen hinter der Karte sichtbar wird: Beerenrot + Papierkorb.
        background: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: rundung,
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        // Wird VOR dem Entfernen gefragt. Gibt sie `false` zurück, springt die
        // Karte zurück an ihren Platz.
        confirmDismiss: (_) => _loeschenBestaetigen(),
        // Wird NACH dem bestätigten Wegwischen aufgerufen.
        onDismissed: (_) {
          setState(() => _weggewischteIds.add(eintrag.id));
          widget.datenbank.eintragLoeschen(eintrag.id);
        },
        // `Material` + `InkWell` = Tipp-Reaktion (Welleneffekt).
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: rundung,
            // Antippen: Übersicht schließen und die id an die Schreibseite
            // zurückgeben – die öffnet daraufhin genau diesen Eintrag.
            onTap: () => Navigator.of(context).pop(eintrag.id),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: GedankengutFarben.papier,
                borderRadius: rundung,
                // Der neueste Eintrag: Ultramarin-Rand mit Leuchten.
                border: Border.all(
                  color: istNeuester
                      ? GedankengutFarben.ultramarin.withValues(alpha: 0.85)
                      : GedankengutFarben.linie,
                ),
                boxShadow: istNeuester
                    ? GedankengutFarben.flaechenLeuchten(
                        GedankengutFarben.ultramarin,
                        radius: 18,
                      )
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Links: Tageszahl und Wochentag untereinander.
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        Text(
                          tag,
                          style: istNeuester
                              ? GedankengutSchriften.datumZahl.copyWith(
                                  color: GedankengutFarben.ultramarinMittel,
                                  shadows: GedankengutFarben.schriftLeuchten(
                                    GedankengutFarben.ultramarin,
                                    staerke: 0.8,
                                  ),
                                )
                              : GedankengutSchriften.datumZahl,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          wochentag,
                          style: GedankengutSchriften.beschriftung.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Rechts: die Vorschau (höchstens zwei Zeilen, dann „…“).
                  Expanded(
                    child: Text(
                      _vorschau(eintrag.inhalt),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GedankengutSchriften.vorschau,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
