// =============================================================================
// eintraege_test.dart – Tests für die Übersicht der Einträge
// =============================================================================
//
// Prüft, ob die Übersicht Einträge richtig anzeigt, ob Antippen den Eintrag
// auf der Schreibseite öffnet und ob Löschen (mit Rückfrage) funktioniert.
//
// Ausführen mit: flutter test
// =============================================================================

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'package:gedankengut/bildschirme/eintraege_bildschirm.dart';
import 'package:gedankengut/bildschirme/schreib_bildschirm.dart';
import 'package:gedankengut/daten/datenbank.dart';
import 'package:gedankengut/main.dart';

void main() {
  late GedankengutDatenbank db;

  // Die „Test-Uhr“ – wir bestimmen selbst, wie spät es ist.
  late DateTime testZeit;

  setUpAll(() async {
    await initializeDateFormatting('de_DE');
  });

  setUp(() {
    testZeit = DateTime(2026, 11, 23, 21, 0); // Montag, 23.11.2026, 21:00
    db = GedankengutDatenbank(
      // `closeStreamsSynchronously: true` beendet Datenbank-Streams sofort,
      // wenn niemand mehr zuhört. Sonst blieben in Tests kurz Timer übrig,
      // was der Test-Rahmen als Fehler meldet.
      verbindung: DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      uhr: () => testZeit,
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// Startet die App und wartet, bis alles geladen und gezeichnet ist.
  /// `pumpAndSettle` zeichnet so lange neue Frames, bis keine Animation mehr läuft.
  Future<void> appStarten(WidgetTester tester) async {
    await tester.pumpWidget(GedankengutApp(datenbank: db));
    await tester.pumpAndSettle();
  }

  /// Tippt auf den Buch-Knopf und wartet, bis die Übersicht offen ist.
  Future<void> uebersichtOeffnen(WidgetTester tester) async {
    // `byTooltip` findet den Knopf über seinen Tooltip-Text.
    await tester.tap(find.byTooltip('Einträge'));
    await tester.pumpAndSettle();
  }

  /// Entfernt die App am Testende wieder (keine übrig gebliebenen Timer).
  Future<void> appBeenden(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('zeigt einen Hinweis, wenn es noch keine Einträge gibt',
      (tester) async {
    await appStarten(tester);
    await uebersichtOeffnen(tester);

    expect(find.text(EintraegeBildschirm.leerText), findsOneWidget);

    await appBeenden(tester);
  });

  testWidgets('zeigt Einträge (neueste oben) und öffnet sie beim Antippen',
      (tester) async {
    await db.eintragSpeichern(inhalt: 'Gedanken vom Montag');
    testZeit = testZeit.add(const Duration(days: 1)); // Dienstag
    await db.eintragSpeichern(inhalt: 'Gedanken vom Dienstag');
    // Einen Tag später die App öffnen → 15-Minuten-Regel greift NICHT,
    // die Schreibseite ist also leer.
    testZeit = testZeit.add(const Duration(days: 1));

    await appStarten(tester);
    await uebersichtOeffnen(tester);

    // Beide Einträge sind zu sehen …
    final montag = find.text('Gedanken vom Montag');
    final dienstag = find.text('Gedanken vom Dienstag');
    expect(montag, findsOneWidget);
    expect(dienstag, findsOneWidget);
    // … und der neuere (Dienstag) steht WEITER OBEN (kleinere y-Position).
    expect(
      tester.getTopLeft(dienstag).dy,
      lessThan(tester.getTopLeft(montag).dy),
    );
    // Das deutsche Datum wird angezeigt.
    expect(find.text('Mo., 23. November 2026 · 21:00'), findsOneWidget);

    // Montag antippen → zurück auf der Schreibseite, Eintrag ist geladen.
    await tester.tap(montag);
    await tester.pumpAndSettle();

    expect(find.byType(SchreibBildschirm), findsOneWidget);
    // `widgetWithText` sucht ein TextField, das diesen Text enthält.
    expect(
      find.widgetWithText(TextField, 'Gedanken vom Montag'),
      findsOneWidget,
    );

    await appBeenden(tester);
  });

  testWidgets('Löschen fragt nach und entfernt den Eintrag erst nach „Löschen“',
      (tester) async {
    await db.eintragSpeichern(inhalt: 'Kann weg');
    testZeit = testZeit.add(const Duration(days: 1));

    await appStarten(tester);
    await uebersichtOeffnen(tester);

    // 1) Nach links wischen → Abfrage erscheint → „Abbrechen“.
    await tester.drag(find.text('Kann weg'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Eintrag löschen?'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Kann weg'), findsOneWidget); // noch da

    // 2) Noch einmal wischen → diesmal „Löschen“.
    await tester.drag(find.text('Kann weg'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    expect(find.text('Kann weg'), findsNothing);
    expect(find.text(EintraegeBildschirm.leerText), findsOneWidget);

    await appBeenden(tester);
  });

  testWidgets('löscht man den offenen Eintrag, beginnt eine neue Seite',
      (tester) async {
    // Gerade erst geschrieben → wird beim Start geladen (15-Minuten-Regel).
    await db.eintragSpeichern(inhalt: 'Gerade offen');

    await appStarten(tester);
    expect(find.widgetWithText(TextField, 'Gerade offen'), findsOneWidget);

    await uebersichtOeffnen(tester);
    await tester.drag(find.text('Gerade offen'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    // Mit dem Zurück-Pfeil zur Schreibseite. Der Knopf wird über seinen
    // (deutschen) Hinweistext „Zurück“ gefunden.
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    // Die Seite ist jetzt leer (Hinweistext sichtbar).
    expect(find.text(SchreibBildschirm.hinweisText), findsOneWidget);

    await appBeenden(tester);
  });
}
