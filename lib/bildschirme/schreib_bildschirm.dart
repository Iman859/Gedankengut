// =============================================================================
// schreib_bildschirm.dart – Der Bildschirm, auf dem du schreibst
// =============================================================================
//
// Das ist der Herzschlag der App: Beim Öffnen landest du direkt hier und
// kannst sofort lostippen. Alles wird automatisch gespeichert.
//
// WAS HIER PASSIERT (Überblick):
//   1. Beim Start: Gibt es einen Eintrag, den du vor < 15 Minuten bearbeitet
//      hast? → Diesen laden (weiterschreiben). Sonst: leere Seite.
//   2. Beim Tippen: 0,5 Sekunden nach dem letzten Tastendruck wird gespeichert.
//   3. Beim Verlassen der App (Home-Taste, App-Wechsel): sofort speichern.
//   4. Bei der Rückkehr in die App: Ist die letzte Änderung ≥ 15 Minuten her?
//      → Neue, leere Seite beginnen.
//   5. Knopf „＋“: aktuellen Eintrag speichern und neue Seite beginnen.
//
// NEU IN DIESER DATEI: „StatefulWidget“
//   Bisher kannten wir nur `StatelessWidget` (sieht immer gleich aus).
//   Hier verändert sich aber etwas: dein Text, der Speicherstatus, das Datum.
//   Dafür gibt es `StatefulWidget`. Es besteht aus ZWEI Klassen:
//     - `SchreibBildschirm`       → die unveränderliche „Hülle“ (Einstellungen)
//     - `_SchreibBildschirmState` → der veränderliche „Zustand“ (State)
//   Ändert sich etwas, ruft man `setState(() { ... })` auf. Flutter zeichnet
//   den Bildschirm daraufhin mit den neuen Werten neu.
// =============================================================================

// `dart:async` enthält `Timer` (Zeitgeber) – brauchen wir für die 0,5 Sekunden
// Wartezeit vor dem automatischen Speichern.
import 'dart:async';

// Formatiert Datumsangaben, z. B. „Mittwoch, 25. November“.
import 'package:intl/intl.dart';

// Die Material-Bausteine (Scaffold, TextField, AppBar, …).
import 'package:material_ui/material_ui.dart';

// Unsere Datenbank. `../` heißt: einen Ordner nach oben (von `bildschirme/`
// nach `lib/`), dann in `daten/`.
import '../daten/datenbank.dart';

/// Die möglichen Zustände der Speicheranzeige unten rechts.
///
/// Ein `enum` (Aufzählung) ist eine feste Liste von erlaubten Werten.
/// So kann der Status nur einer dieser drei sein – Tippfehler unmöglich.
enum SpeicherStatus {
  /// Nichts anzuzeigen (z. B. leere Seite, noch nichts geschrieben).
  keiner,

  /// Gerade wird gespeichert.
  speichert,

  /// Alles ist gesichert.
  gespeichert,
}

/// Der Schreib-Bildschirm – die „Hülle“ des StatefulWidgets.
///
/// Er bekommt die [datenbank] von außen übergeben (aus `main.dart`), statt
/// sie selbst zu erzeugen. Vorteil: In Tests können wir eine Test-Datenbank
/// hineingeben.
class SchreibBildschirm extends StatefulWidget {
  const SchreibBildschirm({super.key, required this.datenbank});

  /// Die Datenbank, in der die Einträge gespeichert werden.
  final GedankengutDatenbank datenbank;

  /// Wie lange nach dem letzten Tastendruck gewartet wird, bevor gespeichert
  /// wird. So speichern wir nicht bei JEDEM Buchstaben, sondern erst, wenn
  /// du kurz innehältst. (Fachbegriff: „Debouncing“.)
  static const Duration speicherVerzoegerung = Duration(milliseconds: 500);

  /// Der Hinweistext auf einer leeren Seite.
  static const String hinweisText = 'Was bewegt dich gerade?';

  /// `createState` erzeugt das zugehörige State-Objekt. Flutter ruft das
  /// einmal auf, wenn der Bildschirm zum ersten Mal angezeigt wird.
  @override
  State<SchreibBildschirm> createState() => _SchreibBildschirmState();
}

/// Der veränderliche Zustand des Schreib-Bildschirms.
///
/// Der Unterstrich `_` macht die Klasse privat (nur in dieser Datei sichtbar).
class _SchreibBildschirmState extends State<SchreibBildschirm> {
  // ---------------------------------------------------------------------------
  // ZUSTAND (alles, was sich ändern kann)
  // ---------------------------------------------------------------------------

  /// Verwaltet den Text im Eingabefeld. Darüber können wir den Text lesen
  /// (`.text`) und von außen setzen (z. B. beim Laden oder für eine neue Seite).
  final TextEditingController _textController = TextEditingController();

  /// Steuert, ob das Eingabefeld „aktiv“ ist (blinkender Cursor, Tastatur
  /// offen). Damit öffnen wir die Tastatur automatisch.
  final FocusNode _fokus = FocusNode();

  /// Hört auf Ereignisse der App selbst: in den Hintergrund / zurück usw.
  /// `late` = wird erst in `initState` gesetzt.
  late final AppLifecycleListener _lebenszyklus;

  /// Die id des aktuell bearbeiteten Eintrags – `null` bei einer neuen Seite,
  /// die noch nicht gespeichert wurde.
  int? _eintragId;

  /// Das Datum, das oben angezeigt wird (Erstellungsdatum des Eintrags bzw.
  /// „jetzt“ bei einer neuen Seite).
  DateTime _datum = DateTime.now();

  /// Der Text, wie er zuletzt in der Datenbank gespeichert wurde.
  /// Damit erkennen wir, ob sich überhaupt etwas geändert hat. Wichtig: Ohne
  /// diese Prüfung würde z. B. jedes Verlassen der App das Änderungsdatum neu
  /// setzen und die 15-Minuten-Regel verfälschen.
  String _gespeicherterText = '';

  /// Aktueller Zustand der Speicheranzeige.
  SpeicherStatus _status = SpeicherStatus.keiner;

  /// `true`, solange beim Start noch geprüft wird, ob es etwas zum
  /// Weiterschreiben gibt.
  bool _laedt = true;

  /// Der Zeitgeber für das verzögerte Speichern (siehe `speicherVerzoegerung`).
  Timer? _speicherTimer;

  /// Eine „Warteschlange“ für Speichervorgänge: Jeder neue Speichervorgang
  /// wird erst gestartet, wenn der vorherige fertig ist. Sonst könnten bei
  /// schnellem Tippen zwei Vorgänge gleichzeitig einen NEUEN Eintrag anlegen
  /// → doppelter Eintrag. `Future.value()` ist ein bereits erledigter Start.
  Future<void> _speicherWarteschlange = Future.value();

  // ---------------------------------------------------------------------------
  // LEBENSZYKLUS DES BILDSCHIRMS
  // ---------------------------------------------------------------------------

  /// `initState` läuft EINMAL, wenn der Bildschirm erstellt wird –
  /// der richtige Ort für Vorbereitungen.
  @override
  void initState() {
    super.initState(); // immer zuerst die Elternklasse vorbereiten lassen

    _lebenszyklus = AppLifecycleListener(
      // `onHide`: Die App verschwindet vom Bildschirm (Home-Taste, App-Wechsel,
      // Bildschirm aus). → Sofort speichern, damit nichts verloren geht.
      onHide: _sofortSpeichern,
      // `onResume`: Die App ist wieder im Vordergrund.
      onResume: _beiRueckkehr,
    );

    _startEintragLaden();
  }

  /// `dispose` läuft, wenn der Bildschirm endgültig verschwindet. Hier
  /// räumen wir auf, damit kein Speicher „verwaist“ (Speicherleck).
  @override
  void dispose() {
    _sofortSpeichern(); // letzte Änderungen noch sichern
    _lebenszyklus.dispose();
    _textController.dispose();
    _fokus.dispose();
    super.dispose(); // immer zuletzt die Elternklasse aufräumen lassen
  }

  // ---------------------------------------------------------------------------
  // LADEN
  // ---------------------------------------------------------------------------

  /// Prüft beim Start, ob es einen Eintrag zum Weiterschreiben gibt
  /// (15-Minuten-Regel) und lädt ihn – sonst bleibt die Seite leer.
  ///
  /// `async` erlaubt `await` in der Funktion, also auf die Datenbank zu warten.
  Future<void> _startEintragLaden() async {
    final eintrag = await widget.datenbank.eintragZumWeiterschreiben();

    // `mounted` ist `false`, wenn der Bildschirm inzwischen geschlossen wurde.
    // Dann dürfen wir `setState` nicht mehr aufrufen.
    if (!mounted) return;

    setState(() {
      if (eintrag != null) {
        _eintragId = eintrag.id;
        _datum = eintrag.erstelltAm;
        _gespeicherterText = eintrag.inhalt;
        // Text setzen UND den Cursor ans Ende stellen, damit du direkt
        // weiterschreiben kannst.
        _textController.value = TextEditingValue(
          text: eintrag.inhalt,
          selection: TextSelection.collapsed(offset: eintrag.inhalt.length),
        );
        _status = SpeicherStatus.gespeichert;
      }
      _laedt = false;
    });

    // Tastatur öffnen. `requestFocus` aktiviert das Eingabefeld.
    _fokus.requestFocus();
  }

  // ---------------------------------------------------------------------------
  // SPEICHERN
  // ---------------------------------------------------------------------------

  /// Wird bei JEDER Änderung im Eingabefeld aufgerufen (jeder Tastendruck).
  /// Startet den 0,5-Sekunden-Zeitgeber neu. Erst wenn du so lange nicht
  /// getippt hast, läuft er ab und es wird gespeichert.
  void _beiTextAenderung(String _) {
    // `?.` = nur aufrufen, wenn der Timer existiert. `cancel` stoppt ihn.
    _speicherTimer?.cancel();
    _speicherTimer = Timer(
      SchreibBildschirm.speicherVerzoegerung,
      _sofortSpeichern,
    );
  }

  /// Speichert JETZT (ohne Verzögerung) – stellt den Vorgang in die
  /// Warteschlange und gibt ein Future zurück, auf das man warten kann.
  Future<void> _sofortSpeichern() {
    _speicherTimer?.cancel();

    // Den Text JETZT festhalten (nicht erst, wenn der Vorgang an der Reihe ist).
    final text = _textController.text;

    // `.then(...)` hängt den neuen Vorgang hinten an die Warteschlange an.
    _speicherWarteschlange = _speicherWarteschlange.then(
      (_) => _textSpeichern(text),
    );
    return _speicherWarteschlange;
  }

  /// Der eigentliche Speichervorgang (läuft immer nur einer gleichzeitig).
  Future<void> _textSpeichern(String text) async {
    // Nichts geändert? Dann gibt es nichts zu tun.
    if (text == _gespeicherterText) return;

    if (mounted) setState(() => _status = SpeicherStatus.speichert);

    // Die Datenbank entscheidet selbst: anlegen, aktualisieren oder löschen.
    final id = await widget.datenbank.eintragSpeichern(
      id: _eintragId,
      inhalt: text,
    );

    _eintragId = id;
    _gespeicherterText = text;

    if (!mounted) return;
    setState(() {
      // Gibt es (noch) einen Eintrag → „gespeichert“, sonst keine Anzeige.
      _status = id != null ? SpeicherStatus.gespeichert : SpeicherStatus.keiner;
    });
  }

  // ---------------------------------------------------------------------------
  // NEUE SEITE & RÜCKKEHR IN DIE APP
  // ---------------------------------------------------------------------------

  /// Speichert den aktuellen Eintrag und beginnt eine neue, leere Seite.
  Future<void> _neueSeite() async {
    await _sofortSpeichern(); // erst sichern, dann leeren

    if (!mounted) return;
    setState(() {
      _eintragId = null;
      _datum = DateTime.now();
      _gespeicherterText = '';
      _textController.clear();
      _status = SpeicherStatus.keiner;
    });
    _fokus.requestFocus();
  }

  /// Wird aufgerufen, wenn du in die App zurückkehrst.
  /// Fragt die Datenbank, ob der zuletzt bearbeitete Eintrag noch im
  /// 15-Minuten-Fenster liegt. Wenn nicht → neue Seite.
  Future<void> _beiRueckkehr() async {
    // Ist die Seite ohnehin leer und ungespeichert, ist nichts zu tun.
    if (_eintragId == null) return;

    await _speicherWarteschlange; // laufende Speichervorgänge abwarten
    final weiterschreiben = await widget.datenbank.eintragZumWeiterschreiben();

    if (weiterschreiben?.id != _eintragId) {
      await _neueSeite();
    }
  }

  // ---------------------------------------------------------------------------
  // AUSSEHEN
  // ---------------------------------------------------------------------------

  /// Baut den Bildschirm. Wird bei jedem `setState` erneut aufgerufen.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Datum auf Deutsch formatieren, z. B. „Mittwoch, 25. November“.
    // EEEE = Wochentag ausgeschrieben, d = Tag, MMMM = Monat ausgeschrieben.
    final datumText = DateFormat('EEEE, d. MMMM', 'de_DE').format(_datum);

    return Scaffold(
      // Die Kopfleiste oben.
      appBar: AppBar(
        title: Text(datumText, style: theme.textTheme.titleMedium),
        // `actions` = Knöpfe auf der rechten Seite der Kopfleiste.
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            // `tooltip` erscheint bei langem Drücken – und hilft Screenreadern.
            tooltip: 'Neue Seite',
            // Während des Ladens deaktiviert (`null` = Knopf ausgegraut).
            onPressed: _laedt ? null : _neueSeite,
          ),
        ],
      ),
      // `SafeArea` hält Abstand zu Kamera-Aussparung, Navigationsleiste usw.
      body: SafeArea(
        child: Column(
          children: [
            // `Expanded` lässt das Eingabefeld den ganzen freien Platz füllen.
            Expanded(
              child: Padding(
                // Abstand links/rechts 24, oben 8 – damit der Text „atmet“.
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: TextField(
                  controller: _textController,
                  focusNode: _fokus,
                  // Während des Ladens kein Tippen möglich.
                  enabled: !_laedt,
                  onChanged: _beiTextAenderung,
                  // `maxLines: null` + `expands: true` = beliebig viele
                  // Zeilen, Feld füllt die ganze Höhe aus.
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  // Satzanfänge automatisch großschreiben.
                  textCapitalization: TextCapitalization.sentences,
                  // Text oben beginnen (statt vertikal zentriert).
                  textAlignVertical: TextAlignVertical.top,
                  // Etwas größere Schrift und viel Zeilenabstand (`height`
                  // = 1,6-fache Schriftgröße) für angenehmes Lesen/Schreiben.
                  // VORLÄUFIG – das richtige Design kommt in Phase 2.
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    height: 1.6,
                  ),
                  // `InputDecoration.collapsed` = ohne Rahmen und Linie,
                  // nur der Hinweistext. Wie ein leeres Blatt Papier.
                  decoration: InputDecoration.collapsed(
                    hintText: SchreibBildschirm.hinweisText,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      height: 1.6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            // Die Statusanzeige unten rechts.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: _statusAnzeige(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Baut die kleine Statusanzeige („speichert …“ / „✓ gespeichert“).
  /// In eine eigene Methode ausgelagert, damit `build` übersichtlich bleibt.
  Widget _statusAnzeige(ThemeData theme) {
    // `switch` wählt je nach Status den passenden Text.
    final text = switch (_status) {
      SpeicherStatus.keiner => '',
      SpeicherStatus.speichert => 'speichert …',
      SpeicherStatus.gespeichert => '✓ gespeichert',
    };

    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
