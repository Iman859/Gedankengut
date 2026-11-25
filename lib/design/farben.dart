// =============================================================================
// farben.dart – Alle Farben von Gedankengut an einem Ort
// =============================================================================
//
// WARUM EINE EIGENE DATEI?
//   Statt Farbcodes wie `0xFF3B2BFF` quer durch die App zu verstreuen, haben
//   alle Farben hier einen NAMEN. Soll sich ein Farbton ändern, passen wir nur
//   diese eine Zeile an – und die ganze App übernimmt ihn automatisch.
//
// FARBCODES LESEN:
//   `Color(0xFF3B2BFF)` → 0x = „jetzt kommt eine Hexadezimalzahl“,
//   FF = Deckkraft (FF = voll sichtbar), 3B = Rot, 2B = Grün, FF = Blau.
//
// DAS DESIGN „NEON-ELEGANZ“ (Gesamtentwurf J, vom Nutzer freigegeben):
//   Fast schwarzer Nachthimmel, Ultramarin-Neon als Leitfarbe, Magenta als
//   zweiter Akzent, helle Schrift mit leichtem Blaustich.
// =============================================================================

import 'package:material_ui/material_ui.dart';

/// Sammlung aller Farben der App.
///
/// `abstract final class` bedeutet: Von dieser Klasse kann man keine Objekte
/// erzeugen und nicht von ihr erben – sie ist nur ein „Behälter“ für
/// Konstanten. Zugriff z. B. mit `GedankengutFarben.ultramarin`.
abstract final class GedankengutFarben {
  // ---------------------------------------------------------------------------
  // HINTERGRÜNDE
  // ---------------------------------------------------------------------------

  /// Nachthimmel – der Hintergrund aller Bildschirme.
  /// (Dieselbe Farbe steht auch in android/app/src/main/res/values/colors.xml,
  /// damit der Startbildschirm nahtlos in die App übergeht.)
  static const Color nacht = Color(0xFF060815);

  /// „Papier“ – etwas heller als die Nacht. Für Karten, Buchseiten, Dialoge
  /// und Knöpfe.
  static const Color papier = Color(0xFF0A0E24);

  /// Feine Trennlinien und Ränder ohne Leuchten.
  static const Color linie = Color(0xFF1C2350);

  // ---------------------------------------------------------------------------
  // SCHRIFTFARBEN
  // ---------------------------------------------------------------------------

  /// Haupt-Schriftfarbe: fast weiß mit einem Hauch Blau.
  static const Color text = Color(0xFFE6ECFF);

  /// Etwas weichere Schriftfarbe für längeren Lesetext auf der Buchseite.
  static const Color textBuch = Color(0xFFDDE4FF);

  /// Gedämpfte Schrift für Nebensächliches (Datum, Wortzahl, Hinweise).
  static const Color gedaempft = Color(0xFF8C96C8);

  // ---------------------------------------------------------------------------
  // ULTRAMARIN-NEON (Leitfarbe)
  // ---------------------------------------------------------------------------

  /// Ultramarin-Neon – vom Nutzer gewählt (Initiale, Leuchten, Akzente).
  /// Sehr dunkel, daher nur für GROSSE Elemente oder mit Leuchten verwenden.
  static const Color ultramarin = Color(0xFF3B2BFF);

  /// Hellere Variante für KLEINE Schrift (z. B. Kapitelzeile), damit sie auf
  /// dem dunklen Hintergrund gut lesbar bleibt.
  static const Color ultramarinHell = Color(0xFF8F86FF);

  /// Mittlere Variante für große Zahlen (z. B. Datum in der Übersicht).
  static const Color ultramarinMittel = Color(0xFF6D62FF);

  // ---------------------------------------------------------------------------
  // BLAU DER KNÖPFE
  // ---------------------------------------------------------------------------

  /// Rand der blauen Neon-Knöpfe (z. B. „Einträge“, „Zurück“).
  static const Color knopfBlau = Color(0xFF3358F0);

  /// Symbolfarbe in den blauen Knöpfen.
  static const Color knopfSymbol = Color(0xFF8FA3F7);

  // ---------------------------------------------------------------------------
  // MAGENTA (zweiter Akzent)
  // ---------------------------------------------------------------------------

  /// Neon-Magenta – Ränder, Buchrücken-Verlauf, Ornament.
  static const Color magenta = Color(0xFFC04DFF);

  /// Helleres Magenta – Cursor und kleine leuchtende Details.
  static const Color magentaHell = Color(0xFFD27BFF);

  /// Symbol- und Schriftfarbe in Magenta-Knöpfen.
  static const Color magentaSymbol = Color(0xFFE0B3FF);

  // ---------------------------------------------------------------------------
  // HILFSFUNKTIONEN FÜR LEUCHTEFFEKTE
  // ---------------------------------------------------------------------------

  /// Erzeugt einen Neon-Leuchteffekt für SCHRIFT.
  ///
  /// Zwei übereinanderliegende Schatten in der Leuchtfarbe: ein enger, kräftiger
  /// (Kern) und ein weiter, weicher (Schein). `blurRadius` = wie stark der
  /// Schatten verschwimmt. `withValues(alpha: …)` = Deckkraft (0 bis 1).
  static List<Shadow> schriftLeuchten(Color farbe, {double staerke = 1}) => [
        Shadow(color: farbe.withValues(alpha: 0.95), blurRadius: 6 * staerke),
        Shadow(color: farbe.withValues(alpha: 0.65), blurRadius: 20 * staerke),
      ];

  /// Erzeugt einen Neon-Leuchteffekt für FLÄCHEN (Knöpfe, Karten, Linien).
  /// `BoxShadow` ist der Schatten eines Kastens – hier als Lichtschein genutzt.
  static List<BoxShadow> flaechenLeuchten(Color farbe, {double radius = 14}) => [
        BoxShadow(color: farbe.withValues(alpha: 0.35), blurRadius: radius),
      ];
}
