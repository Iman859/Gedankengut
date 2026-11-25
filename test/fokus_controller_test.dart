// =============================================================================
// fokus_controller_test.dart – Tests für den Fokus-Modus und den Wortzähler
// =============================================================================
//
// Prüft, welcher Teil des Textes hervorgehoben bzw. gedimmt wird, ob die
// Tastatur-Unterstreichung erhalten bleibt und ob Wörter richtig gezählt
// werden.
//
// Ausführen mit: flutter test
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:gedankengut/bildschirme/fokus_controller.dart';

void main() {
  /// Hilfsfunktion: Liefert den Text des aktiven (hervorgehobenen) Satzes –
  /// oder `null`, wenn nichts hervorgehoben ist.
  String? aktiverSatz(String text, int cursor) {
    final aktiv = fokusAbschnitte(text, cursor)
        .where((a) => a.art == FokusArt.aktiv)
        .toList();
    if (aktiv.isEmpty) return null;
    return text.substring(aktiv.single.start, aktiv.single.ende);
  }

  group('fokusAbschnitte', () {
    test('leerer Text hat keine Abschnitte', () {
      expect(fokusAbschnitte('', 0), isEmpty);
    });

    test('hebt den Satz hervor, in dem der Cursor steht', () {
      const text = 'Erster Satz. Zweiter Satz';
      expect(aktiverSatz(text, text.length), 'Zweiter Satz');
    });

    test('der vorige Satz im selben Absatz ist leicht gedimmt', () {
      const text = 'Erster Satz. Zweiter Satz';
      expect(fokusAbschnitte(text, text.length), [
        const FokusAbschnitt(0, 13, FokusArt.halbGedimmt), // „Erster Satz. “
        const FokusAbschnitt(13, 25, FokusArt.aktiv), // „Zweiter Satz“
      ]);
    });

    test('andere Absätze sind stark gedimmt', () {
      const text = 'Absatz eins.\nAbsatz zwei';
      expect(fokusAbschnitte(text, text.length), [
        const FokusAbschnitt(0, 13, FokusArt.gedimmt), // „Absatz eins.\n“
        const FokusAbschnitt(13, 24, FokusArt.aktiv), // „Absatz zwei“
      ]);
    });

    test('direkt nach dem Satzzeichen bleibt der Satz hervorgehoben', () {
      const text = 'Satz eins.';
      expect(aktiverSatz(text, text.length), 'Satz eins.');
    });

    test('nach Satzzeichen und Leerzeichen ist nichts hervorgehoben', () {
      const text = 'Satz eins. ';
      expect(aktiverSatz(text, text.length), isNull);
    });

    test('Cursor mitten im Text hebt den richtigen Satz hervor', () {
      const text = 'Eins. Zwei? Drei!';
      // Cursor im Wort „Zwei“ (Position 8).
      expect(aktiverSatz(text, 8), 'Zwei?');
    });
  });

  group('woerterZaehlen', () {
    test('zählt durch Leerraum getrennte Wörter', () {
      expect(woerterZaehlen(''), 0);
      expect(woerterZaehlen('   '), 0);
      expect(woerterZaehlen('Heute war ein guter Tag.'), 5);
      expect(woerterZaehlen('Zeile eins\nZeile  zwei'), 4);
    });
  });

  group('FokusTextController', () {
    testWidgets('behält die Tastatur-Unterstreichung bei', (tester) async {
      // Ein kleiner Bildschirm, nur um einen gültigen „Kontext“ zu bekommen.
      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(),
      ));
      final kontext = tester.element(find.byType(SizedBox));

      // Text „Hallo Welt“, die Tastatur bearbeitet gerade „Welt“ (6 bis 10).
      final controller = FokusTextController()
        ..value = const TextEditingValue(
          text: 'Hallo Welt',
          selection: TextSelection.collapsed(offset: 10),
          composing: TextRange(start: 6, end: 10),
        );

      final span = controller.buildTextSpan(
        context: kontext,
        style: const TextStyle(),
        withComposing: true,
      );

      // Das Stück „Welt“ muss unterstrichen sein, „Hallo “ nicht.
      final stuecke = span.children!.cast<TextSpan>();
      final welt = stuecke.firstWhere((s) => s.text == 'Welt');
      final hallo = stuecke.firstWhere((s) => s.text == 'Hallo ');
      expect(welt.style?.decoration, TextDecoration.underline);
      expect(hallo.style?.decoration, isNot(TextDecoration.underline));

      // Der ganze Text ergibt zusammengesetzt wieder „Hallo Welt“.
      expect(stuecke.map((s) => s.text).join(), 'Hallo Welt');

      controller.dispose();
    });
  });
}
