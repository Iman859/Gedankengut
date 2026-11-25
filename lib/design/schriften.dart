// =============================================================================
// schriften.dart – Alle Textstile von Gedankengut an einem Ort
// =============================================================================
//
// DIE ZWEI SCHRIFTEN (vom Nutzer gewählt, Gesamtentwurf J):
//   - BODONI MODA: elegante Schrift mit starkem Kontrast zwischen dicken und
//     dünnen Strichen. Für Überschriften, Datum und kleine Beschriftungen.
//   - PLAYFAIR: für alles, was man liest und schreibt (Fließtext, Initiale).
//
// Beide liegen als Dateien in `assets/schriften/` und sind in der
// pubspec.yaml angemeldet. Sie sind also IN der App – kein Internet nötig.
// Lizenz: SIL Open Font License 1.1 (Dateien OFL-*.txt im selben Ordner).
//
// „VARIABLE“ SCHRIFTEN (kurz erklärt):
//   Beide Schriften sind „variabel“: Eine einzige Datei enthält stufenlos alle
//   Strichstärken („wght“, z. B. 380 = etwas dünner als normal) und optische
//   Größen („opsz“). Die optische Größe ist der Trick hinter Playfair: Bei
//   großer Schrift werden die Kontraste feiner und eleganter, bei kleiner
//   Schrift robuster und besser lesbar. Wir setzen beide Werte über
//   `fontVariations` – passend zur jeweiligen Schriftgröße.
// =============================================================================

import 'package:material_ui/material_ui.dart';

import 'farben.dart';

/// Sammlung aller Textstile der App.
abstract final class GedankengutSchriften {
  // ---------------------------------------------------------------------------
  // SCHRIFTFAMILIEN (Namen wie in pubspec.yaml unter `fonts:` → `family:`)
  // ---------------------------------------------------------------------------

  /// Name der Familie „Playfair“ (Lesen und Schreiben).
  static const String playfair = 'Playfair';

  /// Name der Familie „Bodoni Moda“ (Überschriften und Beschriftungen).
  static const String bodoni = 'BodoniModa';

  // ---------------------------------------------------------------------------
  // BAUKASTEN: Grundfunktionen, aus denen alle Stile entstehen
  // ---------------------------------------------------------------------------

  /// Erzeugt einen Textstil in Playfair.
  ///
  /// - [groesse]: Schriftgröße in „logischen Pixeln“.
  /// - [gewicht]: Strichstärke von 300 (dünn) bis 900 (sehr fett); 400 = normal.
  /// - [kursiv]: schräg gestellt (italic).
  /// - [farbe]: Schriftfarbe.
  /// - [zeilenhoehe]: Abstand der Zeilen als Vielfaches der Schriftgröße.
  /// - [sperrung]: zusätzlicher Abstand zwischen den Buchstaben (in Pixeln).
  /// - [leuchten]: optionale Neon-Schatten (siehe GedankengutFarben).
  static TextStyle playfairStil({
    required double groesse,
    double gewicht = 400,
    bool kursiv = false,
    Color farbe = GedankengutFarben.text,
    double? zeilenhoehe,
    double? sperrung,
    List<Shadow>? leuchten,
  }) {
    return _stil(
      familie: playfair,
      groesse: groesse,
      gewicht: gewicht,
      kursiv: kursiv,
      farbe: farbe,
      zeilenhoehe: zeilenhoehe,
      sperrung: sperrung,
      leuchten: leuchten,
      // Playfair kennt optische Größen von 5 bis 1200.
      optischeGroesse: groesse.clamp(5, 1200).toDouble(),
    );
  }

  /// Erzeugt einen Textstil in Bodoni Moda (Parameter wie bei [playfairStil]).
  static TextStyle bodoniStil({
    required double groesse,
    double gewicht = 400,
    bool kursiv = false,
    Color farbe = GedankengutFarben.text,
    double? zeilenhoehe,
    double? sperrung,
    List<Shadow>? leuchten,
  }) {
    return _stil(
      familie: bodoni,
      groesse: groesse,
      gewicht: gewicht,
      kursiv: kursiv,
      farbe: farbe,
      zeilenhoehe: zeilenhoehe,
      sperrung: sperrung,
      leuchten: leuchten,
      // Bodoni Moda kennt optische Größen von 6 bis 96.
      optischeGroesse: groesse.clamp(6, 96).toDouble(),
    );
  }

  /// Gemeinsamer Unterbau für beide Schriften (privat, daher der `_`).
  static TextStyle _stil({
    required String familie,
    required double groesse,
    required double gewicht,
    required bool kursiv,
    required Color farbe,
    required double optischeGroesse,
    double? zeilenhoehe,
    double? sperrung,
    List<Shadow>? leuchten,
  }) {
    return TextStyle(
      fontFamily: familie,
      fontSize: groesse,
      fontStyle: kursiv ? FontStyle.italic : FontStyle.normal,
      // `fontWeight` ist die „grobe“ Stärke (nur 100er-Schritte) – dient als
      // Rückfall, falls ein Gerät die variablen Achsen nicht unterstützt.
      fontWeight: _naechsteStaerke(gewicht),
      // `fontVariations` stellt die variablen Achsen der Schrift genau ein.
      fontVariations: [
        FontVariation('wght', gewicht),
        FontVariation('opsz', optischeGroesse),
      ],
      color: farbe,
      height: zeilenhoehe,
      letterSpacing: sperrung,
      shadows: leuchten,
    );
  }

  /// Rundet z. B. 380 auf die nächste feste Stärke (hier: 400 = w400).
  /// `FontWeight.values` ist die Liste w100, w200, … w900 (Index 0 bis 8).
  static FontWeight _naechsteStaerke(double gewicht) {
    final index = ((gewicht / 100).round() - 1).clamp(0, 8);
    return FontWeight.values[index];
  }

  // ---------------------------------------------------------------------------
  // FERTIGE STILE (so in den Bildschirmen verwenden)
  // ---------------------------------------------------------------------------
  // `static final` = wird einmal beim ersten Zugriff erzeugt und dann
  // wiederverwendet. (Nicht `const`, weil die Stile berechnet werden.)
  //
  // HINWEIS ZU VERSALIEN: Beschriftungen wie „KAPITEL DREI“ werden im
  // Entwurf in Großbuchstaben gezeigt. Das ist keine Eigenschaft des Stils –
  // der Text wird dafür im Bildschirm mit `.toUpperCase()` umgewandelt.

  /// Kleine, gesperrte Beschriftung in Bodoni (z. B. „MEIN BUCH“).
  static final TextStyle beschriftung = bodoniStil(
    groesse: 10.5,
    farbe: GedankengutFarben.gedaempft,
    sperrung: 3.1, // ≈ 0,3 em: weit gesperrt wie im Entwurf
  );

  /// Wie [beschriftung], aber in leuchtendem Ultramarin
  /// (z. B. Kapitelzeile, Wochentag über dem Datum).
  static final TextStyle beschriftungLeuchtend = bodoniStil(
    groesse: 10.5,
    farbe: GedankengutFarben.ultramarinHell,
    sperrung: 3.1,
    leuchten: [
      Shadow(
        color: GedankengutFarben.ultramarin.withValues(alpha: 0.85),
        blurRadius: 10,
      ),
    ],
  );

  /// Großer Seitentitel, z. B. „Einträge“ (Bodoni kursiv).
  static final TextStyle seitenTitel = bodoniStil(
    groesse: 38,
    kursiv: true,
    zeilenhoehe: 1.1,
  );

  /// Titel eines Eintrags auf der Buchseite (Bodoni kursiv).
  static final TextStyle buchTitel = bodoniStil(
    groesse: 34,
    kursiv: true,
    zeilenhoehe: 1.12,
  );

  /// Datum oben auf der Schreibseite, z. B. „25. November“.
  static final TextStyle datumKopf = bodoniStil(groesse: 24, kursiv: true);

  /// Große Tageszahl in der Übersicht, z. B. „25“.
  static final TextStyle datumZahl = bodoniStil(groesse: 30, zeilenhoehe: 1);

  /// Text, den du auf der Schreibseite tippst (Playfair).
  static final TextStyle schreibtext = playfairStil(
    groesse: 18.5,
    gewicht: 380,
    zeilenhoehe: 1.68,
  );

  /// Lesetext auf der Buchseite (Playfair).
  static final TextStyle fliesstext = playfairStil(
    groesse: 16.5,
    gewicht: 380,
    zeilenhoehe: 1.72,
    farbe: GedankengutFarben.textBuch,
  );

  /// Kurze Vorschau eines Eintrags in der Übersicht (Playfair).
  static final TextStyle vorschau = playfairStil(
    groesse: 15.5,
    gewicht: 380,
    zeilenhoehe: 1.55,
  );

  /// Die große, leuchtende Initiale auf der Buchseite (Playfair, Ultramarin).
  static final TextStyle initiale = playfairStil(
    groesse: 68,
    farbe: GedankengutFarben.ultramarin,
    leuchten: GedankengutFarben.schriftLeuchten(GedankengutFarben.ultramarin),
  );

  /// Kleine Fußzeile, z. B. Datum und Seitenzahl auf der Buchseite.
  static final TextStyle fusszeile = playfairStil(
    groesse: 12,
    farbe: GedankengutFarben.gedaempft,
    sperrung: 0.7,
  );

  /// Beschriftung großer Knöpfe, z. B. „Als Buch lesen“ (Bodoni kursiv).
  static final TextStyle knopf = bodoniStil(
    groesse: 19,
    kursiv: true,
    farbe: GedankengutFarben.magentaSymbol,
  );

  // ---------------------------------------------------------------------------
  // TEXT-THEME FÜR FLUTTER
  // ---------------------------------------------------------------------------

  /// Ordnet unsere Stile den Standard-Plätzen von Flutters `TextTheme` zu.
  ///
  /// Viele fertige Flutter-Bausteine (Dialoge, Listen, Kopfleisten) greifen
  /// automatisch auf diese Plätze zu – so tragen auch sie unsere Schriften.
  static TextTheme get textTheme => TextTheme(
        headlineMedium: seitenTitel,
        headlineSmall: buchTitel,
        titleLarge: bodoniStil(groesse: 22, kursiv: true),
        titleMedium: bodoniStil(groesse: 20, kursiv: true),
        bodyLarge: schreibtext,
        bodyMedium: vorschau,
        bodySmall: fusszeile,
        labelLarge: bodoniStil(groesse: 16, kursiv: true),
        labelMedium: beschriftung,
        labelSmall: beschriftung,
      );
}
