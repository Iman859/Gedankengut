// =============================================================================
// widget_test.dart – Tests für den Schreib-Bildschirm
// =============================================================================
//
// Widget-Tests bauen die Oberfläche „unsichtbar“ auf und simulieren
// Benutzeraktionen (z. B. Tippen). So prüfen wir automatisch, ob der
// Schreib-Bildschirm richtig speichert und lädt.
//
// Ausführen mit: flutter test
// =============================================================================

// Eine Datenbank, die nur im Arbeitsspeicher existiert (keine echte Datei).
import 'package:drift/native.dart';
// Das Test-Werkzeug von Flutter (stellt `testWidgets`, `expect`, `find` bereit).
import 'package:flutter_test/flutter_test.dart';
// Lädt die deutschen Datumsformate (wie in `main.dart`).
import 'package:intl/date_symbol_data_local.dart';
// Die Material-Bausteine (z. B. `TextField`, `SizedBox`), nach denen wir suchen.
import 'package:material_ui/material_ui.dart';

// Unsere eigenen Dateien.
import 'package:gedankengut/bildschirme/schreib_bildschirm.dart';
import 'package:gedankengut/daten/datenbank.dart';
import 'package:gedankengut/main.dart';

void main() {
  // Die Test-Datenbank – wird vor jedem Test frisch angelegt.
  late GedankengutDatenbank db;

  // `setUpAll` läuft EINMAL vor allen Tests: deutsche Datumsformate laden.
  setUpAll(() async {
    await initializeDateFormatting('de_DE');
  });

  setUp(() {
    db = GedankengutDatenbank(verbindung: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Hilfsfunktion: Startet die App und wartet, bis der Startbildschirm
  /// fertig geladen ist. `WidgetTester` ist der „Test-Roboter“, der die
  /// Oberfläche bedient.
  Future<void> appStarten(WidgetTester tester) async {
    await tester.pumpWidget(GedankengutApp(datenbank: db));
    // `pump()` lässt Flutter einen neuen Frame zeichnen – nach dem Laden
    // aus der Datenbank muss der Bildschirm einmal aktualisiert werden.
    await tester.pump();
    await tester.pump();
  }

  /// Hilfsfunktion: Entfernt die App wieder, damit keine Timer o. Ä.
  /// über das Testende hinaus laufen.
  Future<void> appBeenden(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('zeigt eine leere Seite mit Hinweistext', (tester) async {
    await appStarten(tester);

    expect(find.text(SchreibBildschirm.hinweisText), findsOneWidget);

    await appBeenden(tester);
  });

  testWidgets('speichert getippten Text automatisch', (tester) async {
    await appStarten(tester);

    // Text in das Eingabefeld tippen.
    // `find.byType(TextField)` sucht das Eingabefeld auf dem Bildschirm.
    await tester.enterText(find.byType(TextField), 'Heute war ein guter Tag.');

    // Die Speicher-Verzögerung (0,5 s) „vorspulen“ und Flutter zeichnen lassen.
    await tester.pump(SchreibBildschirm.speicherVerzoegerung);
    await tester.pump();

    // Liegt der Eintrag jetzt in der Datenbank?
    final eintrag = await db.eintragZumWeiterschreiben();
    expect(eintrag?.inhalt, 'Heute war ein guter Tag.');
    expect(find.text('✓ gespeichert'), findsOneWidget);

    await appBeenden(tester);
  });

  testWidgets('lädt einen kürzlich bearbeiteten Eintrag zum Weiterschreiben',
      (tester) async {
    // Vorher einen Eintrag anlegen (gerade eben → innerhalb von 15 Minuten).
    await db.eintragSpeichern(inhalt: 'Wo war ich stehen geblieben?');

    await appStarten(tester);

    expect(find.text('Wo war ich stehen geblieben?'), findsOneWidget);

    await appBeenden(tester);
  });
}
