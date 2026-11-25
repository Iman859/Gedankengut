// =============================================================================
// fokus_controller.dart – Der Fokus-Modus beim Schreiben
// =============================================================================
//
// WAS DER FOKUS-MODUS MACHT:
//   Damit du dich ganz auf deinen aktuellen Gedanken konzentrieren kannst,
//   wird der Text beim Schreiben unterschiedlich hell dargestellt:
//     - andere Absätze:                    stark gedimmt (40 % Deckkraft)
//     - übrige Sätze im aktuellen Absatz:  leicht gedimmt (55 %)
//     - der Satz, in dem der Cursor steht: voll sichtbar + weicher
//       Ultramarin-Lichtschein dahinter
//
// WIE DAS TECHNISCH FUNKTIONIERT:
//   Ein Eingabefeld (`TextField`) fragt seinen „Controller“ bei jeder
//   Änderung: „Wie soll ich den Text darstellen?“ Dafür ruft es die Methode
//   `buildTextSpan` auf. Normalerweise kommt ein einziger, einheitlich
//   gestalteter Textblock zurück. Unser `FokusTextController` überschreibt
//   diese Methode und liefert stattdessen mehrere Stücke („TextSpans“), jedes
//   mit eigenem Stil. Der Text selbst bleibt dabei unverändert – nur die
//   DARSTELLUNG ändert sich.
//
// DIE TASTATUR-UNTERSTREICHUNG:
//   Während du ein Wort tippst, unterstreicht die Tastatur (z. B. Gboard) das
//   Wort, für das sie gerade Vorschläge macht (der „Composing“-Bereich). Diese
//   Unterstreichung bauen wir bewusst nach – sonst würden Autokorrektur und
//   Wortvorschläge verwirrend wirken.
// =============================================================================

import 'package:material_ui/material_ui.dart';

import '../design/farben.dart';

/// Wie stark ein Textstück im Fokus-Modus hervorgehoben wird.
enum FokusArt {
  /// Ein anderer Absatz → stark gedimmt.
  gedimmt,

  /// Ein anderer Satz im aktuellen Absatz → leicht gedimmt.
  halbGedimmt,

  /// Der Satz, in dem der Cursor steht → voll sichtbar und hinterlegt.
  aktiv,
}

/// Ein zusammenhängendes Textstück mit seiner Fokus-Art.
///
/// [start] ist die Position des ersten Zeichens, [ende] die Position NACH dem
/// letzten Zeichen (so wie bei `String.substring(start, ende)`).
class FokusAbschnitt {
  const FokusAbschnitt(this.start, this.ende, this.art);

  final int start;
  final int ende;
  final FokusArt art;

  /// Zwei Abschnitte sind gleich, wenn alle drei Werte gleich sind.
  /// (Nötig, damit Tests Abschnitte vergleichen können.)
  @override
  bool operator ==(Object other) =>
      other is FokusAbschnitt &&
      other.start == start &&
      other.ende == ende &&
      other.art == art;

  @override
  int get hashCode => Object.hash(start, ende, art);

  @override
  String toString() => 'FokusAbschnitt($start, $ende, $art)';
}

/// Zerlegt [text] in Fokus-Abschnitte, abhängig von der [cursor]-Position.
///
/// Das ist eine „reine“ Funktion: Sie hängt nur von ihren Eingaben ab und
/// verändert nichts. Dadurch lässt sie sich sehr einfach testen.
///
/// Regeln:
///   - Absätze werden durch Zeilenumbrüche (`\n`) getrennt.
///   - Sätze enden mit `.`, `!` oder `?`.
///   - Steht der Cursor DIREKT hinter einem Satzzeichen (du hast den Satz
///     gerade beendet), bleibt dieser Satz noch hervorgehoben.
///   - Steht der Cursor nach einem Satzzeichen + Leerzeichen, beginnt ein neuer
///     (noch leerer) Satz – dann ist nichts hervorgehoben.
List<FokusAbschnitt> fokusAbschnitte(String text, int cursor) {
  if (text.isEmpty) return const [];

  // Cursor auf den gültigen Bereich begrenzen (0 bis Textlänge).
  final c = cursor.clamp(0, text.length);

  // --- 1. Den aktuellen Absatz finden -------------------------------------
  // Absatzanfang: direkt nach dem letzten Zeilenumbruch VOR dem Cursor.
  // `lastIndexOf` liefert -1, wenn es keinen gibt → dann 0 (Textanfang).
  final absatzStart = c == 0 ? 0 : text.lastIndexOf('\n', c - 1) + 1;
  // Absatzende: beim nächsten Zeilenumbruch AB dem Cursor (oder Textende).
  final naechsterUmbruch = text.indexOf('\n', c);
  final absatzEnde = naechsterUmbruch == -1 ? text.length : naechsterUmbruch;

  // --- 2. Den aktuellen Satz finden ---------------------------------------
  // Satzanfang: nach dem letzten Satzzeichen, das VOR dem Zeichen direkt
  // links vom Cursor steht (siehe Regel „gerade beendeter Satz“ oben).
  var satzStart = absatzStart;
  for (var i = c - 2; i >= absatzStart; i--) {
    if (_istSatzende(text[i])) {
      satzStart = i + 1;
      break;
    }
  }
  // Leerzeichen am Satzanfang überspringen.
  while (satzStart < c && text[satzStart] == ' ') {
    satzStart++;
  }

  // Satzende: beim nächsten Satzzeichen ab dem Cursor (inklusive des
  // Satzzeichens), sonst am Absatzende.
  var satzEnde = absatzEnde;
  for (var i = c; i < absatzEnde; i++) {
    if (_istSatzende(text[i])) {
      satzEnde = i + 1;
      break;
    }
  }

  // --- 3. Abschnitte zusammensetzen (leere werden weggelassen) ------------
  final abschnitte = <FokusAbschnitt>[];
  void hinzufuegen(int start, int ende, FokusArt art) {
    if (ende > start) abschnitte.add(FokusAbschnitt(start, ende, art));
  }

  hinzufuegen(0, absatzStart, FokusArt.gedimmt);
  hinzufuegen(absatzStart, satzStart, FokusArt.halbGedimmt);
  hinzufuegen(satzStart, satzEnde, FokusArt.aktiv);
  hinzufuegen(satzEnde, absatzEnde, FokusArt.halbGedimmt);
  hinzufuegen(absatzEnde, text.length, FokusArt.gedimmt);
  return abschnitte;
}

/// Ist [zeichen] ein Satzende-Zeichen?
bool _istSatzende(String zeichen) =>
    zeichen == '.' || zeichen == '!' || zeichen == '?';

/// Zählt die Wörter in [text]: alles, was durch Leerraum getrennt ist.
/// `RegExp(r'\S+')` = „ein oder mehrere Zeichen, die KEIN Leerraum sind“.
int woerterZaehlen(String text) => RegExp(r'\S+').allMatches(text).length;

/// Ein `TextEditingController` mit Fokus-Modus (siehe Erklärung ganz oben).
///
/// `extends TextEditingController` = er kann alles, was der normale
/// Controller kann – wir ändern nur die Darstellung.
class FokusTextController extends TextEditingController {
  FokusTextController({super.text});

  /// Deckkraft für [FokusArt.gedimmt].
  static const double deckkraftGedimmt = 0.4;

  /// Deckkraft für [FokusArt.halbGedimmt].
  static const double deckkraftHalbGedimmt = 0.55;

  /// Weicher Lichtschein HINTER dem aktiven Satz.
  ///
  /// Ein `Paint` ist ein „Pinsel“ mit Farbe und Effekten. Der Trick für den
  /// weichen Glow: `MaskFilter.blur` lässt die sonst eckige Hinterlegung an
  /// allen Rändern verschwimmen – aus dem „Textmarker“ wird ein Lichtschein.
  static final Paint lichtschein = Paint()
    ..color = GedankengutFarben.ultramarin.withValues(alpha: 0.38)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

  /// Zusätzlicher, leichter Schein direkt um die Buchstaben des aktiven
  /// Satzes (wie das Leuchten einer Neonschrift).
  static final List<Shadow> buchstabenSchein = [
    Shadow(
      color: GedankengutFarben.ultramarin.withValues(alpha: 0.55),
      blurRadius: 12,
    ),
  ];

  /// Wird vom Eingabefeld aufgerufen, um den Text darzustellen.
  ///
  /// - [style]: der Grundstil des Eingabefelds (Schrift, Größe, Farbe).
  /// - [withComposing]: ob die Tastatur-Unterstreichung gezeigt werden soll.
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final grundstil = style ?? const TextStyle();
    final grundfarbe = grundstil.color ?? GedankengutFarben.text;

    // Wo steht der Cursor? (Ohne gültige Auswahl: am Textende.)
    final cursor = selection.isValid ? selection.extentOffset : text.length;
    final abschnitte = fokusAbschnitte(text, cursor);

    // Der Bereich, den die Tastatur gerade unterstreicht (falls vorhanden).
    final tastaturBereich = withComposing && value.isComposingRangeValid
        ? value.composing
        : TextRange.empty;

    // Alle „Schnittstellen“ sammeln: Grenzen der Fokus-Abschnitte und des
    // Tastatur-Bereichs. Zwischen zwei Schnittstellen ist der Stil einheitlich.
    final grenzen = <int>{0, text.length};
    for (final a in abschnitte) {
      grenzen
        ..add(a.start)
        ..add(a.ende);
    }
    if (tastaturBereich.isValid && !tastaturBereich.isCollapsed) {
      grenzen
        ..add(tastaturBereich.start)
        ..add(tastaturBereich.end);
    }
    final sortiert = grenzen.toList()..sort();

    // Für jedes Stück zwischen zwei Grenzen einen eigenen TextSpan bauen.
    final stuecke = <TextSpan>[];
    for (var i = 0; i < sortiert.length - 1; i++) {
      final von = sortiert[i];
      final bis = sortiert[i + 1];
      if (bis <= von) continue;

      // Zu welchem Fokus-Abschnitt gehört dieses Stück?
      final art = abschnitte
          .firstWhere(
            (a) => a.start <= von && bis <= a.ende,
            orElse: () => FokusAbschnitt(von, bis, FokusArt.aktiv),
          )
          .art;

      // Liegt das Stück im Tastatur-Bereich? Dann unterstreichen.
      final unterstrichen = tastaturBereich.isValid &&
          von >= tastaturBereich.start &&
          bis <= tastaturBereich.end;

      stuecke.add(
        TextSpan(
          text: text.substring(von, bis),
          style: _stilFuer(art, grundfarbe).copyWith(
            decoration: unterstrichen ? TextDecoration.underline : null,
          ),
        ),
      );
    }

    // Ein „Eltern“-Span mit dem Grundstil, darin alle Stücke.
    return TextSpan(style: grundstil, children: stuecke);
  }

  /// Liefert den Zusatzstil für eine Fokus-Art.
  TextStyle _stilFuer(FokusArt art, Color grundfarbe) {
    return switch (art) {
      FokusArt.gedimmt =>
        TextStyle(color: grundfarbe.withValues(alpha: deckkraftGedimmt)),
      FokusArt.halbGedimmt =>
        TextStyle(color: grundfarbe.withValues(alpha: deckkraftHalbGedimmt)),
      // `background` (statt `backgroundColor`) erlaubt einen eigenen Pinsel –
      // hier den verschwommenen Lichtschein.
      FokusArt.aktiv => TextStyle(
          color: grundfarbe,
          background: lichtschein,
          shadows: buchstabenSchein,
        ),
    };
  }
}
