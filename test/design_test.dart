// =============================================================================
// design_test.dart – Tests für das Design-Fundament (Phase 2a)
// =============================================================================
//
// Prüft, ob Theme, Schriften und Sprache so eingestellt sind, wie im
// Gesamtentwurf festgelegt. Ändert später jemand versehentlich z. B. die
// Hintergrundfarbe oder die Sprache, schlagen diese Tests Alarm.
//
// Ausführen mit: flutter test
// =============================================================================

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'package:gedankengut/bildschirme/schreib_bildschirm.dart';
import 'package:gedankengut/daten/datenbank.dart';
import 'package:gedankengut/design/farben.dart';
import 'package:gedankengut/design/schriften.dart';
import 'package:gedankengut/design/thema.dart';
import 'package:gedankengut/main.dart';

void main() {
  group('Theme', () {
    test('ist dunkel und nutzt den Nachthimmel als Hintergrund', () {
      final thema = gedankengutThema();

      expect(thema.brightness, Brightness.dark);
      expect(thema.scaffoldBackgroundColor, GedankengutFarben.nacht);
      expect(thema.colorScheme.primary, GedankengutFarben.ultramarin);
      expect(thema.colorScheme.secondary, GedankengutFarben.magenta);
    });
  });

  group('Schriften', () {
    test('Lesen und Schreiben in Playfair, Überschriften in Bodoni Moda', () {
      expect(GedankengutSchriften.schreibtext.fontFamily, 'Playfair');
      expect(GedankengutSchriften.fliesstext.fontFamily, 'Playfair');
      expect(GedankengutSchriften.initiale.fontFamily, 'Playfair');
      expect(GedankengutSchriften.buchTitel.fontFamily, 'BodoniModa');
      expect(GedankengutSchriften.beschriftung.fontFamily, 'BodoniModa');
    });

    test('Titel sind kursiv', () {
      expect(GedankengutSchriften.buchTitel.fontStyle, FontStyle.italic);
      expect(GedankengutSchriften.seitenTitel.fontStyle, FontStyle.italic);
    });

    test('variable Achsen werden passend zur Größe gesetzt', () {
      final stil = GedankengutSchriften.playfairStil(groesse: 18.5, gewicht: 380);

      // Strichstärke 380 und optische Größe = Schriftgröße.
      expect(stil.fontVariations, [
        const FontVariation('wght', 380),
        const FontVariation('opsz', 18.5),
      ]);
      // Rückfall-Stärke: 380 wird auf die nächste feste Stärke (400) gerundet.
      expect(stil.fontWeight, FontWeight.w400);
    });

    test('optische Größe bleibt im erlaubten Bereich der Schrift', () {
      // Bodoni Moda kennt optische Größen nur bis 96.
      final riesig = GedankengutSchriften.bodoniStil(groesse: 200);
      expect(riesig.fontVariations, contains(const FontVariation('opsz', 96)));
    });
  });

  group('Sprache', () {
    setUpAll(() async {
      await initializeDateFormatting('de_DE');
    });

    testWidgets('Flutters eingebaute Texte sind deutsch', (tester) async {
      final db = GedankengutDatenbank(verbindung: NativeDatabase.memory());
      await tester.pumpWidget(GedankengutApp(datenbank: db));
      await tester.pump();

      // Den „Kontext“ des Schreib-Bildschirms holen und darin nachsehen,
      // wie das Menü-Wort für „Kopieren“ lautet.
      final kontext = tester.element(find.byType(SchreibBildschirm));
      expect(MaterialLocalizations.of(kontext).copyButtonLabel, 'Kopieren');

      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
  });
}
