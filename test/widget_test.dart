// =============================================================================
// widget_test.dart – Ein erster automatischer Test
// =============================================================================
//
// Tests sind kleine Programme, die prüfen, ob unser Code das tut, was er soll.
// Man startet sie mit dem Befehl `flutter test`. Der große Vorteil: Wenn wir
// später etwas ändern und dabei versehentlich etwas kaputt machen, schlägt
// der Test Alarm – ohne dass wir die App jedes Mal von Hand durchklicken müssen.
// =============================================================================

// Das Test-Werkzeug von Flutter (stellt `testWidgets`, `expect`, `find` bereit).
import 'package:flutter_test/flutter_test.dart';

// Unsere eigene App, damit wir sie im Test starten können.
import 'package:gedankengut/main.dart';

void main() {
  // `testWidgets` definiert einen Test, der echte Widgets „unsichtbar“ aufbaut.
  // Der erste Parameter ist eine Beschreibung, was getestet wird.
  testWidgets('Startbildschirm zeigt den App-Namen', (WidgetTester tester) async {
    // `pumpWidget` baut die App im Test auf (wie beim echten Start).
    // `await` wartet, bis dieser Vorgang abgeschlossen ist.
    await tester.pumpWidget(const GedankengutApp());

    // `expect` prüft eine Erwartung. Hier: Der Text „Gedankengut“ soll genau
    // einmal auf dem Bildschirm zu finden sein. Wenn nicht → Test schlägt fehl.
    expect(find.text('Gedankengut'), findsOneWidget);
  });
}
