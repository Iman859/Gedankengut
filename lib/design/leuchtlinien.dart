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
