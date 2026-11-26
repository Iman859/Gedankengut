// =============================================================================
// buch_test.dart – Tests für die Buchseite und die Initiale
// =============================================================================
//
// Prüft:
//   - die Vermessung der Initiale (kein Text geht verloren, höchstens zwei
//     Zeilen neben der Initiale),
//   - das Buch: öffnet auf der neuesten Seite, Blättern, Seitenzahlen,
//     „Bearbeiten“ öffnet die richtige Seite auf der Schreibseite.
//
// HINWEIS: In Tests lädt Flutter nicht unsere echten Schriften, sondern eine
// Testschrift, in der jedes Zeichen ein Quadrat ist (so breit wie hoch).
// Das macht Messungen vorhersagbar.
//
// Ausführen mit: flutter test
// =============================================================================

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'package:gedankengut/bildschirme/schreib_bildschirm.dart';
import 'package:gedankengut/daten/datenbank.dart';
import 'package:gedankengut/design/initialen_text.dart';
import 'package:gedankengut/main.dart';

void main() {
  // Nötig, damit Text-Vermessung auch in „einfachen“ Tests funktioniert.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('initialeAufteilen', () {
    const textStil = TextStyle(fontSize: 10, height: 1.5);
    const initialenStil = TextStyle(fontSize: 40);

    InitialenAufteilung aufteilen(String text) => initialeAufteilen(
      text: text,
      textStil: textStil,
      initialenStil: initialenStil,
      breite: 300,
      textScaler: TextScaler.noScaling,
    );

    test('kurzer Text passt komplett neben die Initiale', () {
      final teile = aufteilen('Heute war gut.');

      expect(teile.initiale, 'H');
      expect(teile.daneben, 'eute war gut.');
      expect(teile.darunter, isEmpty);
    });

    test('langer Text wird aufgeteilt – ohne dass Text verloren geht', () {
      final text = 'Heute beim Training war es wieder da. ' * 8;
      final teile = aufteilen(text);

      // Alle drei Teile ergeben zusammen wieder genau den Originaltext.
      expect(teile.initiale + teile.daneben + teile.darunter, text);
      expect(teile.darunter, isNotEmpty);

      // Der Teil neben der Initiale belegt höchstens zwei Zeilen.
      final danebenBreite = 300 - teile.initialenBreite - 8;
      final maler = TextPainter(
        text: TextSpan(text: teile.daneben, style: textStil),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: danebenBreite);
      expect(maler.computeLineMetrics().length, lessThanOrEqualTo(2));
      maler.dispose();
    });

    test('der Bereich neben der Initiale ist genau zwei Zeilen hoch', () {
      final teile = aufteilen('Heute beim Training war es wieder da. ' * 8);
      // Zeilenhöhe = 10 px × 1,5 = 15 px → zwei Zeilen = 30 px.
      expect(teile.blockHoehe, closeTo(30, 0.5));
    });
  });

  group('InitialenText', () {
    testWidgets('die Initiale sitzt auf der Grundlinie der zweiten Zeile – auch wenn '
        'die Umgebung einen großen Zeilenabstand vorgibt', (tester) async {
      // Genau die Situation, die den Fehler „abgerutschte Initiale“ ausgelöst
      // hat: Der Standard-Textstil der Umgebung hat einen großen Zeilenabstand,
      // den die Initiale „erbt“.
      const umgebung = TextStyle(fontSize: 14, height: 3);
      const textStil = TextStyle(fontSize: 10, height: 1.5);
      const initialenStil = TextStyle(fontSize: 40);
      final text = 'Heute beim Training war es wieder da. ' * 8;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultTextStyle(
              style: umgebung,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 300,
                  child: InitialenText(
                    text: text,
                    textStil: textStil,
                    initialenStil: initialenStil,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Dieselbe Vermessung wie im Widget (mit dem gemischten Stil).
      final teile = initialeAufteilen(
        text: text.trim(),
        textStil: umgebung.merge(textStil),
        initialenStil: umgebung.merge(initialenStil),
        breite: 300,
        textScaler: TextScaler.noScaling,
      );

      // Wo liegt die Grundlinie der Initiale auf dem Bildschirm?
      // (Oberkante des angezeigten „H“ + Abstand bis zu seiner Grundlinie.)
      final initialeFinder = find.text('H');
      final initialenMaler = TextPainter(
        text: TextSpan(text: 'H', style: umgebung.merge(initialenStil)),
        textDirection: TextDirection.ltr,
      )..layout();
      final initialeGrundlinie =
          tester.getTopLeft(initialeFinder).dy +
          initialenMaler.computeDistanceToActualBaseline(
            TextBaseline.alphabetic,
          );
      initialenMaler.dispose();

      // Wo liegt die Grundlinie der zweiten Zeile neben der Initiale?
      final danebenFinder = find.text(teile.daneben.trimRight());
      final maler = TextPainter(
        text: TextSpan(
          text: teile.daneben.trimRight(),
          style: umgebung.merge(textStil),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: tester.getSize(danebenFinder).width);
      final zweiteZeile =
          tester.getTopLeft(danebenFinder).dy +
          maler.computeLineMetrics()[1].baseline;
      maler.dispose();

      // Beide Grundlinien müssen (fast pixelgenau) übereinstimmen.
      expect(initialeGrundlinie, closeTo(zweiteZeile, 1));
    });
  });

  group('BuchBildschirm', () {
    late GedankengutDatenbank db;
    late DateTime testZeit;

    setUpAll(() async {
      await initializeDateFormatting('de_DE');
    });

    setUp(() {
      testZeit = DateTime(2026, 11, 23, 21, 0);
      db = GedankengutDatenbank(
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

    testWidgets(
      'öffnet auf der neuesten Seite, blättert zurück und „Bearbeiten“ '
      'öffnet die angezeigte Seite',
      (tester) async {
        // Drei Einträge an drei Tagen.
        await db.eintragSpeichern(inhalt: 'Seite eins');
        testZeit = testZeit.add(const Duration(days: 1));
        await db.eintragSpeichern(inhalt: 'Seite zwei');
        testZeit = testZeit.add(const Duration(days: 1));
        await db.eintragSpeichern(inhalt: 'Seite drei');
        // Einen Tag später die App öffnen → leere Schreibseite.
        testZeit = testZeit.add(const Duration(days: 1));

        await tester.pumpWidget(GedankengutApp(datenbank: db));
        await tester.pumpAndSettle();

        // Übersicht öffnen, dann „Als Buch lesen“.
        await tester.tap(find.byTooltip('Einträge'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Als Buch lesen'));
        await tester.pumpAndSettle();

        // Das Buch zeigt die neueste Seite: Seite 3 mit „Seite drei“.
        // (Die Initiale „S“ steht getrennt, daneben „eite drei“.)
        expect(find.text('— 3 —'), findsOneWidget);
        expect(find.text('eite drei'), findsOneWidget);

        // Blätterrichtung (Wunsch des Nutzers):
        // nach LINKS wischen = ältere Seite …
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
        await tester.pumpAndSettle();
        expect(find.text('— 2 —'), findsOneWidget);
        expect(find.text('eite zwei'), findsOneWidget);

        // … nach RECHTS wischen = wieder die neuere Seite …
        await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
        await tester.pumpAndSettle();
        expect(find.text('— 3 —'), findsOneWidget);

        // … und noch einmal nach links zurück auf Seite 2.
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
        await tester.pumpAndSettle();
        expect(find.text('— 2 —'), findsOneWidget);

        // „Bearbeiten“ → zurück auf der Schreibseite mit genau diesem Eintrag.
        await tester.tap(find.byTooltip('Bearbeiten'));
        await tester.pumpAndSettle();
        expect(find.byType(SchreibBildschirm), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Seite zwei'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}
