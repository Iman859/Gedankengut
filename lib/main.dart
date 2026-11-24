// =============================================================================
// main.dart – Der Einstiegspunkt der App „Gedankengut“
// =============================================================================
//
// Jede Flutter-App startet in dieser Datei. Hier passiert (vorerst) nur sehr
// wenig: Wir starten die App und zeigen einen schlichten Startbildschirm.
// In den nächsten Phasen wachsen hier nach und nach die echten Bildschirme
// (Schreiben, Einträge, Buch) heran – dann in eigenen Dateien.
//
// GRUNDIDEE VON FLUTTER (kurz erklärt):
//   In Flutter ist ALLES ein „Widget“ – ein Baustein der Oberfläche.
//   Ein Text ist ein Widget, ein Abstand ist ein Widget, ein ganzer Bildschirm
//   ist ein Widget. Widgets werden ineinander verschachtelt wie Lego-Steine
//   oder wie russische Matroschka-Puppen. Das Ergebnis nennt man „Widget-Baum“.
// =============================================================================

// `import` holt fertigen Code aus einem Paket in diese Datei.
// `material_ui` enthält die Bausteine von Googles Design-System „Material“
// (z. B. Text, Farben, Bildschirm-Gerüste). Seit neueren Flutter-Versionen
// ist es ein eigenes Paket – deshalb steht es auch in der Datei pubspec.yaml.
import 'package:material_ui/material_ui.dart';

/// Die Funktion `main()` ist der Startpunkt JEDES Dart-Programms.
/// Wenn du die App auf dem Handy antippst, wird genau diese Funktion zuerst
/// ausgeführt.
void main() {
  // `runApp` nimmt unser oberstes Widget und zeichnet es auf den Bildschirm.
  // `const` bedeutet: Dieses Objekt ändert sich nie – Flutter kann es daher
  // einmal erstellen und wiederverwenden, was die App schneller macht.
  runApp(const GedankengutApp());
}

/// Das oberste Widget der App – quasi der „Rahmen“ um alles andere.
///
/// `StatelessWidget` heißt: Dieses Widget hat keinen eigenen, veränderlichen
/// Zustand. Es sieht immer gleich aus, solange sich seine Eingaben nicht
/// ändern. (Das Gegenstück ist `StatefulWidget` – das lernen wir kennen,
/// sobald sich etwas auf dem Bildschirm ändern soll, z. B. beim Tippen.)
class GedankengutApp extends StatelessWidget {
  /// Der Konstruktor: So wird ein `GedankengutApp`-Objekt erzeugt.
  /// `super.key` reicht einen optionalen „Schlüssel“ an Flutter weiter, mit dem
  /// Flutter Widgets intern auseinanderhalten kann. Brauchen wir hier nicht
  /// aktiv, gehört aber zum guten Stil.
  const GedankengutApp({super.key});

  /// `build` beschreibt, WIE das Widget aussieht.
  /// Flutter ruft diese Methode automatisch auf, wann immer es das Widget
  /// (neu) zeichnen muss. `@override` zeigt an, dass wir eine vorgegebene
  /// Methode der Elternklasse mit unserem eigenen Inhalt überschreiben.
  /// `context` enthält Infos darüber, wo im Widget-Baum wir uns befinden.
  @override
  Widget build(BuildContext context) {
    // `MaterialApp` richtet die Grundlagen einer App ein:
    // Titel, Farbschema (Theme), Navigation zwischen Bildschirmen usw.
    return MaterialApp(
      // Name der App (wird z. B. in der Übersicht offener Apps verwendet).
      title: 'Gedankengut',

      // Blendet das rote „DEBUG“-Band oben rechts aus, das Flutter während
      // der Entwicklung sonst anzeigt.
      debugShowCheckedModeBanner: false,

      // Das Theme legt das Aussehen der ganzen App fest.
      // VORLÄUFIG: Ein dunkles Schema auf Basis von Lila. Das echte Design
      // (Dunkelblau, Lila, Neon-Akzente, Notizbuch-Look) entwerfen wir in
      // Phase 2 gemeinsam und du segnest es ab.
      theme: ThemeData(
        // `ColorScheme.fromSeed` erzeugt aus EINER Grundfarbe automatisch
        // eine ganze, harmonische Farbpalette.
        colorScheme: ColorScheme.fromSeed(
          // Farbe im Format 0xAARRGGBB (Deckkraft, Rot, Grün, Blau – hexadezimal).
          seedColor: const Color(0xFF7C4DFF), // ein kräftiges Lila
          brightness: Brightness.dark, // dunkler Modus – angenehm am Abend
        ),
      ),

      // `home` ist der erste Bildschirm, den man nach dem Start sieht.
      home: const StartBildschirm(),
    );
  }
}

/// Ein schlichter Platzhalter-Bildschirm, damit wir prüfen können, dass die
/// App auf dem Pixel läuft. Wird in Phase 1 durch den echten Schreib-
/// Bildschirm ersetzt.
class StartBildschirm extends StatelessWidget {
  const StartBildschirm({super.key});

  @override
  Widget build(BuildContext context) {
    // `Theme.of(context)` holt das oben definierte Theme, damit wir dessen
    // Farben und Schriftstile hier wiederverwenden können.
    final theme = Theme.of(context);

    // `Scaffold` (engl. „Baugerüst“) ist das Grundgerüst eines Bildschirms:
    // Es bietet Plätze für Kopfleiste, Inhalt, Knöpfe usw.
    return Scaffold(
      // `body` ist der Hauptinhalt des Bildschirms.
      // `Center` setzt sein Kind-Widget genau in die Mitte.
      body: Center(
        // `Column` ordnet mehrere Widgets untereinander an (eine „Spalte“).
        child: Column(
          // Die Spalte nimmt nur so viel Höhe ein, wie ihr Inhalt braucht –
          // so bleibt alles schön mittig.
          mainAxisSize: MainAxisSize.min,
          // `children` ist die Liste der Widgets in der Spalte (von oben nach unten).
          children: [
            // Ein Symbol (Icon) aus der eingebauten Material-Icon-Sammlung.
            Icon(
              Icons.auto_stories, // ein aufgeschlagenes Buch
              size: 64,
              color: theme.colorScheme.primary, // Hauptfarbe aus dem Theme
            ),

            // `SizedBox` ist ein unsichtbarer Kasten – hier als Abstand
            // von 16 „logischen Pixeln“ zwischen Icon und Text.
            const SizedBox(height: 16),

            // Der App-Name als große Überschrift.
            Text(
              'Gedankengut',
              style: theme.textTheme.headlineMedium,
            ),

            const SizedBox(height: 8),

            // Eine kleine Unterzeile in etwas gedämpfter Farbe.
            Text(
              'Hier entsteht dein Buch der Gedanken.',
              style: theme.textTheme.bodyMedium?.copyWith(
                // `?.` heißt: Nur ausführen, falls der Stil nicht leer (null) ist.
                // `copyWith` übernimmt den Stil und ändert nur die Farbe.
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
