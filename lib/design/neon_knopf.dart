// =============================================================================
// neon_knopf.dart – Der quadratische Knopf mit Leuchtrand
// =============================================================================
//
// Ein wiederverwendbarer Baustein für die kleinen Symbol-Knöpfe der App
// (z. B. „Einträge“, „Neue Seite“, „Zurück“). Es gibt ihn in zwei Farben:
// Blau (für Navigation) und Magenta (für „Neues anlegen“).
//
// Mindestgröße 44 × 44 Pixel: So groß sollte jede Tippfläche sein, damit man
// sie auch mit dem Daumen sicher trifft.
// =============================================================================

import 'package:material_ui/material_ui.dart';

import 'farben.dart';

/// Die verfügbaren Leuchtfarben eines [NeonKnopf]s.
enum NeonFarbe {
  /// Blauer Rand – für Navigation (Einträge, Zurück).
  blau,

  /// Magenta-Rand – für „Neues anlegen“ (Neue Seite).
  magenta,
}

/// Ein Symbol-Knopf mit leuchtendem Neon-Rand.
class NeonKnopf extends StatelessWidget {
  const NeonKnopf({
    super.key,
    required this.symbol,
    required this.hinweis,
    required this.beiDruck,
    this.farbe = NeonFarbe.blau,
  });

  /// Das Symbol im Knopf, z. B. `Icons.add`.
  final IconData symbol;

  /// Kurzer Hinweistext. Erscheint bei langem Drücken und wird von
  /// Screenreadern (Vorlesefunktion) vorgelesen.
  final String hinweis;

  /// Was beim Antippen passiert. `null` = Knopf ist deaktiviert (ausgegraut).
  final VoidCallback? beiDruck;

  /// Leuchtfarbe des Knopfs.
  final NeonFarbe farbe;

  @override
  Widget build(BuildContext context) {
    // Je nach gewählter Farbe: Randfarbe und Symbolfarbe festlegen.
    // `switch` mit `=>` liefert direkt ein Wertepaar (ein sogenanntes „Record“).
    final (randFarbe, symbolFarbe) = switch (farbe) {
      NeonFarbe.blau => (GedankengutFarben.knopfBlau, GedankengutFarben.knopfSymbol),
      NeonFarbe.magenta => (GedankengutFarben.magenta, GedankengutFarben.magentaSymbol),
    };

    final aktiv = beiDruck != null;

    // `Tooltip` zeigt den Hinweis bei langem Drücken.
    return Tooltip(
      message: hinweis,
      // `Opacity` macht den Knopf halb durchsichtig, wenn er deaktiviert ist.
      child: Opacity(
        opacity: aktiv ? 1 : 0.4,
        // `Material` + `InkWell` sorgen für die Tipp-Reaktion (Welleneffekt).
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: beiDruck,
            borderRadius: BorderRadius.circular(12),
            // `Ink` ist wie ein `Container`, aber der Welleneffekt bleibt
            // sichtbar (bei einem normalen Container läge er darunter).
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: GedankengutFarben.papier,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: randFarbe.withValues(alpha: 0.9)),
                boxShadow: GedankengutFarben.flaechenLeuchten(randFarbe),
              ),
              child: Icon(symbol, size: 20, color: symbolFarbe),
            ),
          ),
        ),
      ),
    );
  }
}
