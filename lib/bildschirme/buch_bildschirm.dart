// =============================================================================
// buch_bildschirm.dart – Deine Einträge als Buch zum Lesen und Blättern
// =============================================================================
//
// Jeder Eintrag ist eine Buchseite. Die Seiten sind chronologisch sortiert:
// Dein ältester Eintrag ist Seite 1. Das Buch öffnet sich auf der NEUESTEN
// Seite.
//
// BLÄTTERRICHTUNG (Wunsch des Nutzers, „deutsch-intuitiv“):
//   - nach LINKS wischen  → ältere Seite (zurück in die Vergangenheit)
//   - nach RECHTS wischen → neuere Seite
//
// Oben: „Zurück“ (blau) und „Bearbeiten“ (magenta). „Bearbeiten“ öffnet die
// gerade angezeigte Seite auf der Schreibseite.
//
// AUSSEHEN (Gesamtentwurf J): Punktraster, eine „Papierseite“ mit
// Magenta-Kante, Kapitelzeile, kursiver Titel, Ornament, leuchtende
// Initiale über zwei Zeilen, Fußzeile mit Seitenzahl.
//
// PLATZHALTER BIS PHASE 2e: Kapitel und Titel gibt es noch nicht. Bis dahin
// steht in der Kapitelzeile der Monat und als Titel das Datum.
//
// NEU IN DIESER DATEI: `PageView`
//   Ein Widget, das seine Kinder als „Seiten“ nebeneinander anordnet, zwischen
//   denen man wischen kann – genau richtig für ein Buch. Ein `PageController`
//   steuert, welche Seite angezeigt wird (z. B. beim Öffnen die letzte).
// =============================================================================

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../daten/datenbank.dart';
import '../design/farben.dart';
import '../design/initialen_text.dart';
import '../design/leuchtlinien.dart';
import '../design/neon_knopf.dart';
import '../design/punktraster.dart';
import '../design/schriften.dart';

/// Der Buch-Bildschirm.
///
/// Gibt beim Schließen über „Bearbeiten“ die id der angezeigten Seite zurück
/// (sonst `null`).
class BuchBildschirm extends StatefulWidget {
  const BuchBildschirm({super.key, required this.datenbank});

  /// Die Datenbank, aus der die Einträge gelesen werden.
  final GedankengutDatenbank datenbank;

  /// Schalter: Blocksatz (`true`) oder linksbündig (`false`).
  ///
  /// Entscheidung nach dem Test auf dem Pixel: LINKSBÜNDIG. Grund: Flutter
  /// trennt keine Wörter, daher erzeugt Blocksatz auf schmalen Seiten
  /// ungleichmäßige Wortabstände. (Blocksatz + Silbentrennung ist eine Idee
  /// für später.)
  static const bool blocksatz = false;

  /// Perspektive des 3D-Umblätterns: Je größer, desto stärker wirkt die
  /// räumliche Tiefe (kleine Werte wie 0,001 sind üblich).
  static const double perspektive = 0.0012;

  @override
  State<BuchBildschirm> createState() => _BuchBildschirmState();
}

class _BuchBildschirmState extends State<BuchBildschirm> {
  /// Alle Einträge, neueste zuerst (so liefert sie die Datenbank).
  late final Stream<List<Eintrag>> _eintraege;

  /// Steuert das Blättern. Wird erst erzeugt, wenn die Einträge geladen sind –
  /// denn erst dann wissen wir, welche Seite die neueste ist.
  PageController? _seitenSteuerung;

  /// Die Einträge in Buch-Reihenfolge (älteste zuerst) – für „Bearbeiten“.
  List<Eintrag> _seiten = const [];

  /// Index der gerade angezeigten Seite (0 = Seite 1).
  int _aktuelleSeite = 0;

  @override
  void initState() {
    super.initState();
    _eintraege = widget.datenbank.alleEintraegeBeobachten();
  }

  @override
  void dispose() {
    // Der PageController muss aufgeräumt werden (gibt Speicher frei).
    _seitenSteuerung?.dispose();
    super.dispose();
  }

  /// „Bearbeiten“: Buch schließen und die id der aktuellen Seite zurückgeben.
  void _bearbeiten() {
    if (_seiten.isEmpty) return;
    Navigator.of(context).pop(_seiten[_aktuelleSeite].id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: Punktraster()),
          SafeArea(
            child: Column(
              children: [
                _kopfzeile(),
                Expanded(
                  child: StreamBuilder<List<Eintrag>>(
                    stream: _eintraege,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();

                      // `reversed` dreht die Reihenfolge um: älteste zuerst.
                      _seiten = snapshot.data!.reversed.toList();
                      if (_seiten.isEmpty) return const SizedBox.shrink();

                      // Beim ersten Mal: auf der neuesten (letzten) Seite öffnen.
                      if (_seitenSteuerung == null) {
                        _aktuelleSeite = _seiten.length - 1;
                        _seitenSteuerung = PageController(
                          initialPage: _aktuelleSeite,
                        );
                      }

                      return PageView.builder(
                        controller: _seitenSteuerung,
                        // `reverse: true` spiegelt die Anordnung: Die nächste
                        // (neuere) Seite liegt LINKS, die ältere RECHTS.
                        // Dadurch gilt: Finger nach rechts → neuere Seite,
                        // Finger nach links → ältere Seite.
                        reverse: true,
                        itemCount: _seiten.length,
                        // Merken, welche Seite gerade sichtbar ist.
                        onPageChanged: (index) => _aktuelleSeite = index,
                        // Baut nur die sichtbaren Seiten (spart Speicher).
                        // `AnimatedBuilder` baut die Seite bei JEDER
                        // Bewegung des Fingers neu ein – so kann sie sich
                        // passend zur Wischbewegung drehen (Umblättern).
                        itemBuilder: (context, index) => AnimatedBuilder(
                          animation: _seitenSteuerung!,
                          // Die Seite selbst wird nur EINMAL gebaut und als
                          // `child` weitergereicht – nur die Drehung ändert
                          // sich. Das hält die Animation flüssig.
                          child: _seite(_seiten[index], seitenzahl: index + 1),
                          builder: (context, seite) =>
                              _umblaettern(index: index, seite: seite!),
                        ),
                      );
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

  /// Das 3D-Umblättern: verwandelt das seitliche Wischen in ein Umblättern
  /// um den Buchrücken (linker Rand).
  ///
  /// SO FUNKTIONIERT ES:
  /// Ein `PageView` schiebt Seiten normalerweise nur seitlich. Wir lesen
  /// aus, wie weit jede Seite gerade von der Bildschirmmitte entfernt ist
  /// ([abstand]: 0 = sichtbar, +1 = die nächst NEUERE Seite, −1 = die nächst
  /// ÄLTERE; wegen `reverse: true` liegt die neuere links, die ältere rechts),
  /// und:
  ///   1. HEBEN das seitliche Verschieben auf (`Transform.translate`) –
  ///      die Seiten liegen also aufeinander wie in einem Buch.
  ///   2. DREHEN die neuere Seite um ihren linken Rand (den Buchrücken,
  ///      `rotateY`): Bei 1 steht sie senkrecht (unsichtbar), bei 0 liegt sie
  ///      flach. Ihre rechte Kante folgt dabei dem Finger:
  ///        - nach LINKS wischen: die aktuelle Seite hebt sich an, schwenkt
  ///          mit dem Finger nach links weg und gibt die ältere frei;
  ///        - nach RECHTS wischen: die neuere Seite schwenkt von links herein
  ///          und legt sich über die aktuelle.
  ///   3. ABDUNKELN: Die sich hebende Seite und die verdeckte Seite darunter
  ///      werden leicht dunkler – wie der Schatten einer Buchseite.
  Widget _umblaettern({required int index, required Widget seite}) {
    final steuerung = _seitenSteuerung!;

    // Aktuelle Blätter-Position (z. B. 4,3 = zwischen Seite 5 und 6).
    // Vor dem ersten Zeichnen gibt es noch keine Position → Startseite.
    final position =
        steuerung.hasClients && steuerung.position.hasContentDimensions
        ? (steuerung.page ?? index.toDouble())
        : steuerung.initialPage.toDouble();
    final abstand = (index - position).clamp(-1.0, 1.0);

    // Ruhende Seite → nichts zu tun (spart Rechenzeit).
    if (abstand == 0) return seite;

    return LayoutBuilder(
      builder: (context, grenzen) {
        // Wie dunkel wird die Seite? (0 = gar nicht, 0,55 = recht dunkel)
        final schatten = abstand > 0 ? abstand * 0.55 : -abstand * 0.35;

        Widget ergebnis = Stack(
          children: [
            seite,
            // Die Abdunklung als halbdurchsichtige schwarze Fläche darüber.
            // `IgnorePointer`: Sie fängt keine Fingertipps ab.
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: const Color(0xFF000000).withValues(alpha: schatten),
                ),
              ),
            ),
          ],
        );

        // Nur die rechte (neuere) Seite dreht sich um den Buchrücken.
        if (abstand > 0) {
          ergebnis = Transform(
            // Drehpunkt: der linke Rand, in der Mitte der Höhe.
            alignment: Alignment.centerLeft,
            // Eine „Matrix“ beschreibt die Verwandlung: zuerst etwas
            // Perspektive (Tiefe), dann die Drehung um die senkrechte Achse.
            // Winkel im Bogenmaß: π/2 ≈ 1,5708 = 90°.
            transform: Matrix4.identity()
              ..setEntry(3, 2, BuchBildschirm.perspektive)
              ..rotateY(abstand * 1.5708),
            child: ergebnis,
          );
        }

        // Das seitliche Verschieben des PageView aufheben → Seiten liegen
        // übereinander statt nebeneinander. (Wegen `reverse: true` liegt die
        // neuere Seite um `abstand × Breite` LINKS → wir schieben sie um
        // genau so viel nach RECHTS zurück; bei der älteren umgekehrt.)
        return Transform.translate(
          offset: Offset(abstand * grenzen.maxWidth, 0),
          child: ergebnis,
        );
      },
    );
  }

  /// Kopfzeile: Zurück · „MEIN BUCH“ · Bearbeiten.
  Widget _kopfzeile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NeonKnopf(
            symbol: Icons.chevron_left,
            hinweis: 'Zurück',
            beiDruck: () => Navigator.of(context).pop(),
          ),
          Text('MEIN BUCH', style: GedankengutSchriften.beschriftung),
          NeonKnopf(
            symbol: Icons.edit_outlined,
            hinweis: 'Bearbeiten',
            farbe: NeonFarbe.magenta,
            beiDruck: _bearbeiten,
          ),
        ],
      ),
    );
  }

  /// Eine Buchseite für einen Eintrag.
  Widget _seite(Eintrag eintrag, {required int seitenzahl}) {
    final datum = eintrag.erstelltAm;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      // Die „Papierseite“: Papier-Farbe, feiner Rand, oben leicht abgerundet,
      // sanftes Ultramarin-Leuchten drumherum.
      child: Container(
        decoration: BoxDecoration(
          color: GedankengutFarben.papier,
          border: const Border(
            top: BorderSide(color: GedankengutFarben.linie),
            left: BorderSide(color: GedankengutFarben.linie),
            right: BorderSide(color: GedankengutFarben.linie),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          boxShadow: [
            BoxShadow(
              color: GedankengutFarben.ultramarin.withValues(alpha: 0.16),
              blurRadius: 28,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Die Magenta-Kante links (wie der Rücken eines Buches).
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: GedankengutFarben.magenta.withValues(alpha: 0.55),
              ),
            ),
            // Der Seiteninhalt: oben der Text (scrollt bei langen Einträgen),
            // unten fest die Fußzeile mit der Seitenzahl (immer sichtbar).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 34, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Kapitelzeile (Platzhalter bis 2e: der Monat).
                          Text(
                            DateFormat(
                              'MMMM y',
                              'de_DE',
                            ).format(datum).toUpperCase(),
                            style: GedankengutSchriften.beschriftungLeuchtend,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          // Titel (Platzhalter bis 2e: das Datum).
                          Text(
                            DateFormat('EEEE, d. MMMM', 'de_DE').format(datum),
                            style: GedankengutSchriften.buchTitel,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          const Ornament(),
                          const SizedBox(height: 22),
                          // Der Text mit leuchtender Initiale.
                          InitialenText(
                            text: eintrag.inhalt,
                            textStil: GedankengutSchriften.fliesstext,
                            initialenStil: GedankengutSchriften.initiale,
                            blocksatz: BuchBildschirm.blocksatz,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _fusszeile(datum, seitenzahl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fußzeile einer Seite: Datum · Seitenzahl · Uhrzeit.
  Widget _fusszeile(DateTime datum, int seitenzahl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 22),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: GedankengutFarben.linie)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('d. MMMM y', 'de_DE').format(datum),
              style: GedankengutSchriften.fusszeile,
            ),
          ),
          Text(
            '— $seitenzahl —',
            style: GedankengutSchriften.fusszeile.copyWith(
              fontSize: 15,
              color: GedankengutFarben.text,
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('HH:mm', 'de_DE').format(datum),
              style: GedankengutSchriften.fusszeile,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
