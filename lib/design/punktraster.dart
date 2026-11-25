// =============================================================================
// punktraster.dart – Der Hintergrund mit feinem Punktraster
// =============================================================================
//
// Ein ruhiger Hintergrund für die Übersicht und die Buchseite: auf dem
// Nachthimmel ein gleichmäßiges Raster aus winzigen, bläulichen Punkten –
// wie ein dezent bedrucktes Notizbuchpapier bei Nacht.
//
// Gezeichnet mit einem `CustomPainter` (Erklärung siehe sternenhimmel.dart).
// =============================================================================

import 'package:material_ui/material_ui.dart';

import 'farben.dart';

/// Das Punktraster als Widget. Füllt den ganzen verfügbaren Platz.
///
/// Verwendung: als unterste Ebene in einem `Stack`, z. B.
/// `const Positioned.fill(child: Punktraster())`.
class Punktraster extends StatelessWidget {
  const Punktraster({super.key});

  @override
  Widget build(BuildContext context) {
    // `RepaintBoundary`: Das Raster wird nur einmal gezeichnet und nicht bei
    // jeder Änderung im Vordergrund (z. B. beim Scrollen der Liste) erneut.
    return const RepaintBoundary(
      child: CustomPaint(painter: _RasterMaler(), size: Size.infinite),
    );
  }
}

/// Der „Maler“ des Punktrasters.
class _RasterMaler extends CustomPainter {
  const _RasterMaler();

  /// Abstand zwischen zwei Punkten in Pixeln (wie im Entwurf: 18).
  static const double _abstand = 18;

  /// Radius eines Punktes in Pixeln.
  static const double _punktRadius = 1;

  @override
  void paint(Canvas canvas, Size size) {
    // Ein Pinsel für alle Punkte: helles Blau, nur leicht sichtbar.
    final pinsel = Paint()
      ..color = GedankengutFarben.ultramarinHell.withValues(alpha: 0.14);

    // Zeile für Zeile, Spalte für Spalte einen Punkt setzen.
    // Die Punkte beginnen bei der halben Rasterweite, damit am Rand
    // gleichmäßig Platz bleibt.
    for (var y = _abstand / 2; y < size.height; y += _abstand) {
      for (var x = _abstand / 2; x < size.width; x += _abstand) {
        canvas.drawCircle(Offset(x, y), _punktRadius, pinsel);
      }
    }
  }

  /// Das Raster ändert sich nie → nie neu malen (außer bei Größenänderung,
  /// das macht Flutter von selbst).
  @override
  bool shouldRepaint(covariant _RasterMaler alterMaler) => false;
}
