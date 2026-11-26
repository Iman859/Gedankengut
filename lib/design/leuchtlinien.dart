// =============================================================================
// leuchtlinien.dart – Die leuchtenden Linien des Designs
// =============================================================================
//
// Zwei kleine Bausteine mit demselben Prinzip: eine 1 Pixel dünne Linie mit
// einem Farbverlauf von Ultramarin nach Magenta und einem weichen Lichtschein.
//   - `Buchruecken`: die senkrechte Linie am linken Rand („Buchrücken“).
//   - `Trennleuchtlinie`: die waagerechte Linie unter der Kopfzeile.
// =============================================================================

import 'package:material_ui/material_ui.dart';

import 'farben.dart';

/// Farbe des Lichtscheins um die Linien: eine Mischung aus Ultramarin und
/// Magenta, damit der Schein über die ganze Länge stimmig wirkt.
const Color _scheinFarbe = Color(0xFF6E3CFF);

/// Der Lichtschein der Linien: ein kräftiger enger und ein weiter, schwacher
/// Schein (Feinschliff 2b: etwas stärker, damit die Linien „poppiger“ wirken).
final List<BoxShadow> _schein = [
  BoxShadow(color: _scheinFarbe.withValues(alpha: 0.8), blurRadius: 8),
  BoxShadow(color: _scheinFarbe.withValues(alpha: 0.3), blurRadius: 20),
];

/// Die senkrechte Leuchtlinie am linken Rand.
///
/// WICHTIG: Muss direkt in einem `Stack` stehen, weil sie mit `Positioned`
/// an den linken Rand geheftet wird (von ganz oben bis ganz unten).
class Buchruecken extends StatelessWidget {
  const Buchruecken({super.key, this.abstandLinks = 20});

  /// Abstand der Linie vom linken Bildschirmrand in Pixeln.
  final double abstandLinks;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: abstandLinks,
      top: 0,
      bottom: 0,
      child: Container(
        width: 1,
        decoration: BoxDecoration(
          // Verlauf von oben (Ultramarin) nach unten (Magenta).
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GedankengutFarben.ultramarin, GedankengutFarben.magenta],
          ),
          boxShadow: _schein,
        ),
      ),
    );
  }
}

/// Das Ornament unter Buchtiteln: zwei auslaufende Linien (links Ultramarin,
/// rechts Magenta) und dazwischen eine leuchtende, auf die Spitze gestellte
/// Raute – wie eine Zierlinie in einem gedruckten Buch.
class Ornament extends StatelessWidget {
  const Ornament({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Linke Linie: blendet von durchsichtig zu Ultramarin ein.
        Container(
          width: 44,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              GedankengutFarben.ultramarin.withValues(alpha: 0),
              GedankengutFarben.ultramarin,
            ]),
          ),
        ),
        const SizedBox(width: 12),
        // Die Raute: ein Quadrat, um 45° gedreht (`Transform.rotate`,
        // Winkel im Bogenmaß: 0,785 ≈ π/4 = 45°).
        Transform.rotate(
          angle: 0.785,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              border: Border.all(color: GedankengutFarben.magentaHell),
              boxShadow: GedankengutFarben.flaechenLeuchten(
                GedankengutFarben.magenta,
                radius: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Rechte Linie: blendet von Magenta zu durchsichtig aus.
        Container(
          width: 44,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              GedankengutFarben.magenta,
              GedankengutFarben.magenta.withValues(alpha: 0),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Die waagerechte Leuchtlinie (z. B. unter der Kopfzeile).
/// Nimmt die volle verfügbare Breite ein.
class Trennleuchtlinie extends StatelessWidget {
  const Trennleuchtlinie({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        // Verlauf von links (Ultramarin) nach rechts (Magenta).
        gradient: LinearGradient(
          colors: [GedankengutFarben.ultramarin, GedankengutFarben.magenta],
        ),
        boxShadow: _schein,
      ),
    );
  }
}
