// =============================================================================
// sternenhimmel.dart – Der Hintergrund mit Sternenstaub
// =============================================================================
//
// Zeichnet den nächtlichen Hintergrund der Schreibseite (Raster „G2“):
//   - viele kleine, zart leuchtende Sterne in Weiß, Ultramarin und Magenta,
//   - zwei weiche Lichtschimmer (Magenta unten rechts, Ultramarin links).
//
// NEU IN DIESER DATEI: „CustomPainter“
//   Normalerweise setzen wir Bildschirme aus fertigen Widgets zusammen. Für
//   freie Grafik (Punkte, Kreise, Verläufe) gibt es den `CustomPainter`: eine
//   Klasse mit einer `paint`-Methode, die wie ein Maler direkt auf eine
//   Leinwand („Canvas“) zeichnet.
//
// WARUM SEHEN DIE STERNE IMMER GLEICH AUS?
//   Die Positionen werden zwar „zufällig“ berechnet, aber mit einem festen
//   Startwert (Seed). Ein Zufallsgenerator mit gleichem Startwert liefert
//   immer dieselbe Zahlenfolge – also liegen die Sterne bei jedem Öffnen an
//   derselben Stelle. Nichts springt, nichts flackert.
// =============================================================================

// `dart:math` enthält den Zufallsgenerator `Random`.
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'farben.dart';

/// Der Sternenhimmel als Widget. Füllt den ganzen verfügbaren Platz.
///
/// Verwendung: als unterste Ebene in einem `Stack`, z. B.
/// `const Positioned.fill(child: Sternenhimmel())`.
class Sternenhimmel extends StatelessWidget {
  const Sternenhimmel({super.key});

  @override
  Widget build(BuildContext context) {
    // `RepaintBoundary` trennt den Sternenhimmel vom Rest des Bildschirms:
    // Wenn du tippst und sich der Text ändert, muss der Himmel NICHT neu
    // gezeichnet werden. Das spart Rechenzeit und Akku.
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _SternenMaler(),
        // `Size.infinite` = so groß wie der Platz, den das Eltern-Widget gibt.
        size: Size.infinite,
      ),
    );
  }
}

/// Der eigentliche „Maler“ des Sternenhimmels.
class _SternenMaler extends CustomPainter {
  const _SternenMaler();

  /// Fester Startwert für den Zufallsgenerator (siehe Erklärung oben).
  static const int _startwert = 2611;

  /// Sterne pro 1000 × 1000 Pixel Fläche – bestimmt, wie dicht der Himmel ist.
  /// (Feinschliff 2b: von 110 auf 145 erhöht – „etwas mehr“.)
  static const double _sterneProFlaeche = 145;

  /// Höhe des gedachten „Himmels“, über den die Sterne verteilt werden.
  ///
  /// WARUM EINE FESTE HÖHE? Öffnet sich die Tastatur, wird der sichtbare
  /// Bereich kleiner. Würden wir die Sterne relativ zur aktuellen Höhe
  /// verteilen, würden sie dabei alle verrutschen. Mit fester Höhe wird der
  /// Himmel unten nur „abgeschnitten“ – die Sterne bleiben, wo sie sind.
  static const double _himmelHoehe = 2400;

  @override
  void paint(Canvas canvas, Size size) {
    _lichtschimmerMalen(canvas, size);
    _sterneMalen(canvas, size);
  }

  /// Malt die zwei weichen Lichtschimmer.
  void _lichtschimmerMalen(Canvas canvas, Size size) {
    // Magenta-Schimmer unten rechts.
    _schimmer(
      canvas,
      size,
      mitte: Offset(size.width * 0.85, size.height),
      radius: 320,
      farbe: GedankengutFarben.magenta.withValues(alpha: 0.17),
    );
    // Ultramarin-Schimmer links, etwa auf einem Drittel der Höhe.
    _schimmer(
      canvas,
      size,
      mitte: Offset(0, size.height * 0.3),
      radius: 280,
      farbe: GedankengutFarben.ultramarin.withValues(alpha: 0.18),
    );
  }

  /// Malt einen kreisförmigen Farbverlauf: innen [farbe], außen durchsichtig.
  void _schimmer(
    Canvas canvas,
    Size size, {
    required Offset mitte,
    required double radius,
    required Color farbe,
  }) {
    // Ein `Shader` füllt eine Fläche mit einem Muster – hier einem Verlauf.
    final pinsel = Paint()
      ..shader = RadialGradient(
        colors: [farbe, farbe.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: mitte, radius: radius));
    canvas.drawCircle(mitte, radius, pinsel);
  }

  /// Malt die Sterne.
  void _sterneMalen(Canvas canvas, Size size) {
    final zufall = Random(_startwert);

    // Wie viele Sterne passen auf den gedachten Himmel?
    final anzahl = (size.width * _himmelHoehe / 1e6 * _sterneProFlaeche).round();

    // Die möglichen Sternfarben (mit Grund-Deckkraft).
    const farben = [
      Color(0xFFFFFFFF), // weiß
      GedankengutFarben.ultramarinHell, // bläulich
      GedankengutFarben.magentaHell, // rötlich-lila
    ];

    for (var i = 0; i < anzahl; i++) {
      // WICHTIG: Alle Zufallszahlen IMMER ziehen – auch für Sterne, die gerade
      // nicht sichtbar sind. Sonst verschiebt sich die Zahlenfolge und die
      // übrigen Sterne würden springen.
      final x = zufall.nextDouble() * size.width;
      final y = zufall.nextDouble() * _himmelHoehe;
      final radius = 0.4 + zufall.nextDouble() * 0.8; // 0,4 bis 1,2 Pixel
      final farbe = farben[zufall.nextInt(farben.length)];
      final deckkraft = 0.3 + zufall.nextDouble() * 0.45; // 30 % bis 75 %
      final zufallLeuchten = zufall.nextDouble();
      final leuchtet = zufallLeuchten < 0.18; // etwa jeder 6. Stern
      final funkelt = zufallLeuchten < 0.035; // nur die hellsten ~3,5 %

      // Unterhalb des sichtbaren Bereichs? Dann nicht malen.
      if (y > size.height) continue;

      final mitte = Offset(x, y);
      final pinsel = Paint()..color = farbe.withValues(alpha: deckkraft);
      canvas.drawCircle(mitte, radius, pinsel);

      // Einige Sterne bekommen einen kleinen, verschwommenen Schein.
      if (leuchtet) {
        final schein = Paint()
          ..color = farbe.withValues(alpha: deckkraft * 0.6)
          // `MaskFilter.blur` lässt die Form weich verschwimmen.
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
        canvas.drawCircle(mitte, radius * 2.8, schein);
      }

      // Die hellsten Sterne funkeln: ein winziges, sehr zartes Kreuz.
      // Das unterscheidet sie von Staubkörnchen auf dem Display.
      if (funkelt) _funkelnMalen(canvas, mitte, farbe);
    }
  }

  /// Malt ein feines, vierstrahliges Funkeln um einen Stern.
  void _funkelnMalen(Canvas canvas, Offset mitte, Color farbe) {
    const laenge = 5.0; // Länge jedes Strahls in Pixeln
    final strahl = Paint()
      ..color = farbe.withValues(alpha: 0.45)
      ..strokeWidth = 0.6
      // Weiche Enden, leicht verschwommen – damit es zart bleibt.
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
    // Waagerechter und senkrechter Strahl.
    canvas.drawLine(
      mitte.translate(-laenge, 0),
      mitte.translate(laenge, 0),
      strahl,
    );
    canvas.drawLine(
      mitte.translate(0, -laenge),
      mitte.translate(0, laenge),
      strahl,
    );
    // Ein etwas hellerer Kern.
    canvas.drawCircle(
      mitte,
      1.3,
      Paint()..color = farbe.withValues(alpha: 0.85),
    );
  }

  /// Muss neu gemalt werden, wenn sich der Maler ändert? Nein – der Himmel
  /// ist immer derselbe. (Bei einer Größenänderung malt Flutter ohnehin neu.)
  @override
  bool shouldRepaint(covariant _SternenMaler alterMaler) => false;
}
