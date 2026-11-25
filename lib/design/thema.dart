// =============================================================================
// thema.dart – Das Gesamt-Theme von Gedankengut
// =============================================================================
//
// Ein „Theme“ legt das Aussehen der GANZEN App fest: Farben, Schriften, wie
// Dialoge, Kopfleisten oder der Text-Cursor aussehen. Flutters fertige
// Bausteine lesen diese Werte automatisch aus – so müssen wir nicht jeden
// Knopf und jeden Dialog einzeln einfärben.
//
// Hier werden die Farben (farben.dart) und Schriften (schriften.dart) zu einem
// stimmigen Ganzen zusammengesetzt.
// =============================================================================

// `services.dart` enthält u. a. `SystemUiOverlayStyle` – damit steuern wir
// die Farben der Android-Systemleisten (Uhrzeit/Akku oben, Navigation unten).
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'farben.dart';
import 'schriften.dart';

/// Einstellungen für die Android-Systemleisten:
/// - oben (Statusleiste): durchsichtig, mit hellen Symbolen,
/// - unten (Navigationsleiste): nachtschwarz, mit hellen Symbolen.
const SystemUiOverlayStyle gedankengutSystemleisten = SystemUiOverlayStyle(
  statusBarColor: Color(0x00000000), // komplett durchsichtig
  statusBarIconBrightness: Brightness.light, // helle Symbole (Android)
  statusBarBrightness: Brightness.dark, // dasselbe für iOS/macOS-Logik
  systemNavigationBarColor: GedankengutFarben.nacht,
  systemNavigationBarIconBrightness: Brightness.light,
);

/// Baut das Theme der App. Wird in `main.dart` an `MaterialApp` übergeben.
ThemeData gedankengutThema() {
  // Das Farbschema: Flutter-Bausteine fragen z. B. nach „primary“ (Hauptfarbe)
  // oder „onSurface“ (Schrift auf der Fläche) – hier sagen wir, was das ist.
  const farbschema = ColorScheme.dark(
    primary: GedankengutFarben.ultramarin,
    onPrimary: GedankengutFarben.text,
    secondary: GedankengutFarben.magenta,
    onSecondary: GedankengutFarben.nacht,
    surface: GedankengutFarben.nacht,
    onSurface: GedankengutFarben.text,
    onSurfaceVariant: GedankengutFarben.gedaempft,
    surfaceContainerHigh: GedankengutFarben.papier,
    outline: GedankengutFarben.linie,
    outlineVariant: GedankengutFarben.linie,
    // Fehler- und Lösch-Farben (z. B. Hintergrund beim Wegwischen):
    // ein gedecktes Beere-Rot, das zum Neon-Look passt.
    error: Color(0xFFFF6B8A),
    errorContainer: Color(0xFF3A0F2A),
    onErrorContainer: Color(0xFFFFB3C6),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: farbschema,
    // Hintergrund jedes Bildschirms (Scaffold).
    scaffoldBackgroundColor: GedankengutFarben.nacht,
    // Unsere Schriften für alle Standard-Textplätze.
    textTheme: GedankengutSchriften.textTheme,

    // Kopfleiste: durchsichtig, ohne Schatten – der Nachthimmel scheint durch.
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0x00000000),
      surfaceTintColor: Color(0x00000000),
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: GedankengutFarben.text,
      systemOverlayStyle: gedankengutSystemleisten,
    ),

    // Cursor in Magenta, Markierung in halbdurchsichtigem Ultramarin.
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: GedankengutFarben.magentaHell,
      selectionColor: GedankengutFarben.ultramarin.withValues(alpha: 0.4),
      selectionHandleColor: GedankengutFarben.magentaHell,
    ),

    // Trennlinien.
    dividerTheme: const DividerThemeData(
      color: GedankengutFarben.linie,
      thickness: 1,
    ),

    // Symbole (Icons) standardmäßig im hellen Knopf-Blau.
    iconTheme: const IconThemeData(color: GedankengutFarben.knopfSymbol),

    // Dialoge (z. B. „Eintrag löschen?“): Papier-Hintergrund, feiner Rand.
    dialogTheme: DialogThemeData(
      backgroundColor: GedankengutFarben.papier,
      surfaceTintColor: const Color(0x00000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GedankengutFarben.linie),
      ),
      titleTextStyle: GedankengutSchriften.bodoniStil(groesse: 24, kursiv: true),
      contentTextStyle: GedankengutSchriften.vorschau,
    ),

    // Textknöpfe (z. B. „Abbrechen“ / „Löschen“ im Dialog).
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: GedankengutFarben.ultramarinHell,
        textStyle: GedankengutSchriften.bodoniStil(groesse: 17, kursiv: true),
      ),
    ),
  );
}
