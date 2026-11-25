// =============================================================================
// main.dart – Der Einstiegspunkt der App „Gedankengut“
// =============================================================================
//
// Jede Flutter-App startet in dieser Datei. Hier wird:
//   1. alles Nötige vorbereitet (deutsche Datumsformate, Datenbank),
//   2. die App mit ihrem Farbschema eingerichtet,
//   3. der erste Bildschirm angezeigt – der Schreib-Bildschirm.
//
// GRUNDIDEE VON FLUTTER (kurz erklärt):
//   In Flutter ist ALLES ein „Widget“ – ein Baustein der Oberfläche.
//   Ein Text ist ein Widget, ein Abstand ist ein Widget, ein ganzer Bildschirm
//   ist ein Widget. Widgets werden ineinander verschachtelt wie Lego-Steine
//   oder wie russische Matroschka-Puppen. Das Ergebnis nennt man „Widget-Baum“.
// =============================================================================

// Lädt die Datumsformate für eine bestimmte Sprache (bei uns Deutsch), damit
// z. B. „Mittwoch, 25. November“ statt „Wednesday, November 25“ angezeigt wird.
import 'package:intl/date_symbol_data_local.dart';

// `material_ui` enthält die Bausteine von Googles Design-System „Material“
// (z. B. Text, Farben, Bildschirm-Gerüste). Seit neueren Flutter-Versionen
// ist es ein eigenes Paket – deshalb steht es auch in der Datei pubspec.yaml.
import 'package:material_ui/material_ui.dart';

// Unsere eigenen Dateien: die Datenbank und der Schreib-Bildschirm.
// `package:gedankengut/...` zeigt auf den Ordner `lib/` unseres Projekts.
import 'package:gedankengut/bildschirme/schreib_bildschirm.dart';
import 'package:gedankengut/daten/datenbank.dart';

/// Die Funktion `main()` ist der Startpunkt JEDES Dart-Programms.
/// Wenn du die App auf dem Handy antippst, wird genau diese Funktion zuerst
/// ausgeführt.
///
/// `async` + `Future<void>`: Die Funktion darf mit `await` auf Dinge warten,
/// die etwas Zeit brauchen (hier: das Laden der Datumsformate).
Future<void> main() async {
  // Stellt sicher, dass Flutter selbst bereit ist, BEVOR wir vor `runApp`
  // schon andere Dinge erledigen. (Pflicht, sobald vor `runApp` gewartet wird.)
  WidgetsFlutterBinding.ensureInitialized();

  // Deutsche Datumsformate laden.
  await initializeDateFormatting('de_DE');

  // Die Datenbank EINMAL für die ganze App erzeugen. Sie wird dann an die
  // Bildschirme weitergereicht, die sie brauchen.
  final datenbank = GedankengutDatenbank();

  // `runApp` nimmt unser oberstes Widget und zeichnet es auf den Bildschirm.
  runApp(GedankengutApp(datenbank: datenbank));
}

/// Das oberste Widget der App – quasi der „Rahmen“ um alles andere.
///
/// `StatelessWidget` heißt: Dieses Widget hat keinen eigenen, veränderlichen
/// Zustand. Es sieht immer gleich aus, solange sich seine Eingaben nicht
/// ändern. (Das Gegenstück `StatefulWidget` findest du im Schreib-Bildschirm.)
class GedankengutApp extends StatelessWidget {
  /// Der Konstruktor: So wird ein `GedankengutApp`-Objekt erzeugt.
  /// `required this.datenbank` heißt: Eine Datenbank MUSS übergeben werden.
  /// `super.key` reicht einen optionalen „Schlüssel“ an Flutter weiter, mit dem
  /// Flutter Widgets intern auseinanderhalten kann.
  const GedankengutApp({super.key, required this.datenbank});

  /// Die Datenbank der App (wird an die Bildschirme weitergegeben).
  final GedankengutDatenbank datenbank;

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

      // `home` ist der erste Bildschirm, den man nach dem Start sieht:
      // direkt die Schreibseite – so ist die Hürde zum Schreiben minimal.
      home: SchreibBildschirm(datenbank: datenbank),
    );
  }
}
