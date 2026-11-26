// =============================================================================
// initialen_text.dart – Text mit großer Initiale über zwei Zeilen
// =============================================================================
//
// Wie in alten Büchern: Der erste Buchstabe eines Textes ist groß und
// leuchtend, und die ersten ZWEI Zeilen fließen rechts daneben. Ab der
// dritten Zeile läuft der Text wieder über die ganze Breite.
//
// DAS PROBLEM:
//   Im Web gibt es dafür `float: left`. Flutter kennt so etwas nicht – Text
//   kann nicht von selbst um ein anderes Element „herumfließen“.
//
// DIE LÖSUNG (in drei Schritten):
//   1. MESSEN: Mit einem `TextPainter` (Flutters „Textvermesser“) berechnen
//      wir, wie breit die Initiale ist und welcher Teil des Textes in genau
//      zwei Zeilen neben die Initiale passt.
//   2. AUFTEILEN: Der Text wird an dieser Stelle in zwei Teile geschnitten:
//      „daneben“ (die zwei Zeilen) und „darunter“ (der Rest).
//   3. ZUSAMMENSETZEN: Initiale + „daneben“ nebeneinander, „darunter“ darunter.
//      Die Initiale wird so platziert, dass ihre Grundlinie genau auf der
//      Grundlinie der ZWEITEN Zeile sitzt – und sie nimmt nie mehr Höhe ein
//      als zwei Zeilen. So entsteht keine Lücke (der Fehler aus der Vorschau).
// =============================================================================

import 'package:material_ui/material_ui.dart';

/// Das Ergebnis der Vermessung (siehe [initialeAufteilen]).
///
/// Ein „Record“ mit benannten Feldern – ein kleines Datenpaket.
typedef InitialenAufteilung = ({
  /// Der große erste Buchstabe.
  String initiale,

  /// Der Text, der in den zwei Zeilen neben der Initiale steht.
  String daneben,

  /// Der restliche Text unter der Initiale (über die volle Breite).
  String darunter,

  /// Breite der Initiale in Pixeln.
  double initialenBreite,

  /// Wie weit die Initiale von oben verschoben wird, damit ihre Grundlinie
  /// auf der Grundlinie der zweiten Zeile sitzt.
  double initialenOben,

  /// Höhe des Bereichs neben der Initiale (höchstens zwei Zeilen).
  double blockHoehe,
});

/// Vermisst [text] und teilt ihn für die Initialen-Darstellung auf.
///
/// - [breite]: verfügbare Gesamtbreite in Pixeln.
/// - [abstand]: Lücke zwischen Initiale und Text.
/// - [textScaler]: die Schriftvergrößerung des Systems (Bedienungshilfen) –
///   muss beim Messen und beim Anzeigen gleich sein.
InitialenAufteilung initialeAufteilen({
  required String text,
  required TextStyle textStil,
  required TextStyle initialenStil,
  required double breite,
  required TextScaler textScaler,
  double abstand = 8,
}) {
  // `characters.first` = das erste „sichtbare Zeichen“. Anders als `text[0]`
  // funktioniert das auch bei Umlauten mit Zusatzzeichen oder Emojis.
  final initiale = text.characters.first;
  final rest = text.substring(initiale.length);

  // --- 1. Die Initiale vermessen ------------------------------------------
  final initialenMaler = TextPainter(
    text: TextSpan(text: initiale, style: initialenStil),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();
  final initialenBreite = initialenMaler.width;
  // Abstand von der Oberkante bis zur Grundlinie der Initiale.
  final initialenGrundlinie =
      initialenMaler.computeDistanceToActualBaseline(TextBaseline.alphabetic);

  // --- 2. Den Text neben der Initiale vermessen ---------------------------
  final danebenBreite = (breite - initialenBreite - abstand).clamp(1.0, breite);
  final textMaler = TextPainter(
    text: TextSpan(text: rest, style: textStil),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(maxWidth: danebenBreite);

  // `computeLineMetrics` liefert Maße für jede Zeile (Höhe, Grundlinie …).
  final zeilen = textMaler.computeLineMetrics();
  initialenMaler.dispose();

  // Wo liegt die Grundlinie der zweiten Zeile (oder der letzten, falls der
  // Text kürzer ist)? Daran richten wir die Initiale aus.
  final zielZeile = zeilen.length >= 2 ? zeilen[1] : zeilen.firstOrNull;
  final zielGrundlinie = zielZeile?.baseline ?? initialenGrundlinie;
  final blockHoehe = zeilen.take(2).fold<double>(0, (summe, z) => summe + z.height);

  // --- 3. Den Schnittpunkt nach der zweiten Zeile finden ------------------
  var schnitt = rest.length; // Standard: alles passt daneben.
  if (zeilen.length > 2) {
    // Ein Punkt knapp unterhalb der Oberkante der DRITTEN Zeile …
    final dritte = zeilen[2];
    final y = dritte.baseline - dritte.ascent + 1;
    // … welches Zeichen liegt dort ganz links? Dort beginnt Zeile 3.
    schnitt = textMaler.getPositionForOffset(Offset(0, y)).offset;
  }
  textMaler.dispose();

  return (
    initiale: initiale,
    daneben: rest.substring(0, schnitt),
    darunter: rest.substring(schnitt),
    initialenBreite: initialenBreite,
    initialenOben: zielGrundlinie - initialenGrundlinie,
    blockHoehe: blockHoehe,
  );
}

/// Zeigt einen Text mit großer Initiale über zwei Zeilen an.
class InitialenText extends StatelessWidget {
  const InitialenText({
    super.key,
    required this.text,
    required this.textStil,
    required this.initialenStil,
    this.blocksatz = true,
    this.abstand = 8,
  });

  /// Der ganze Text (die Initiale ist dessen erster Buchstabe).
  final String text;

  /// Stil des normalen Textes.
  final TextStyle textStil;

  /// Stil der Initiale (groß, leuchtend).
  final TextStyle initialenStil;

  /// `true` = Blocksatz (beide Ränder gerade), `false` = linksbündig.
  final bool blocksatz;

  /// Lücke zwischen Initiale und Text in Pixeln.
  final double abstand;

  @override
  Widget build(BuildContext context) {
    final sauber = text.trim();
    if (sauber.isEmpty) return const SizedBox.shrink();

    final ausrichtung = blocksatz ? TextAlign.justify : TextAlign.start;
    // Die Schriftvergrößerung aus den Systemeinstellungen des Handys.
    final textScaler = MediaQuery.textScalerOf(context);

    // WICHTIG (Fehlerbehebung „abgerutschte Initiale“):
    // Ein `Text`-Widget mischt seinen Stil automatisch mit dem Standard-
    // Textstil der Umgebung (`DefaultTextStyle`) – z. B. einem großen
    // Zeilenabstand. Beim Vermessen mit dem `TextPainter` passiert das NICHT.
    // Damit Messung und Anzeige exakt übereinstimmen, mischen wir hier selbst
    // und verwenden die fertigen Stile für BEIDES.
    final umgebung = DefaultTextStyle.of(context).style;
    final textStilFertig = umgebung.merge(textStil);
    final initialenStilFertig = umgebung.merge(initialenStil);

    // `LayoutBuilder` verrät uns, wie viel Breite zur Verfügung steht –
    // die brauchen wir zum Vermessen.
    return LayoutBuilder(
      builder: (context, grenzen) {
        final teile = initialeAufteilen(
          text: sauber,
          textStil: textStilFertig,
          initialenStil: initialenStilFertig,
          breite: grenzen.maxWidth,
          textScaler: textScaler,
          abstand: abstand,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Die Initiale in einem Kasten, der genau zwei Zeilen hoch ist.
                // `Stack` + `Clip.none`: Die Initiale darf über den Kasten
                // hinausragen (z. B. ihr Leuchten), ohne Platz zu verbrauchen.
                SizedBox(
                  width: teile.initialenBreite,
                  height: teile.blockHoehe,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: teile.initialenOben,
                        child: Text(
                          teile.initiale,
                          style: initialenStilFertig,
                          textScaler: textScaler,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: abstand),
                // Die zwei Zeilen neben der Initiale.
                Expanded(
                  child: Text(
                    teile.daneben.trimRight(),
                    style: textStilFertig,
                    textAlign: ausrichtung,
                    textScaler: textScaler,
                  ),
                ),
              ],
            ),
            // Der Rest über die volle Breite (falls vorhanden).
            if (teile.darunter.trim().isNotEmpty)
              Text(
                teile.darunter.trimLeft(),
                style: textStilFertig,
                textAlign: ausrichtung,
                textScaler: textScaler,
              ),
          ],
        );
      },
    );
  }
}
