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
//   6. Buch-Knopf oben links: Übersicht aller Einträge öffnen. Tippst du dort
//      einen Eintrag an, wird er hier zum Weiterschreiben geöffnet.
//
// AUSSEHEN (Design „Neon-Eleganz“, Phase 2b):
//   Sternenhimmel im Hintergrund, leuchtende Buchrücken-Linie links,
//   Neon-Knöpfe, Datum in Bodoni, Text in Playfair, Fokus-Modus (aktueller
//   Satz hervorgehoben), unten Wortanzahl und Speicherstatus.
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
// Design-Bausteine: Farben, Schriften, Sternenhimmel, Knöpfe, Leuchtlinien.
import '../design/farben.dart';
import '../design/leuchtlinien.dart';
import '../design/neon_knopf.dart';
import '../design/schriften.dart';
import '../design/sternenhimmel.dart';
// Die Übersicht aller Einträge (wird über den Buch-Knopf oben links geöffnet).
import 'eintraege_bildschirm.dart';
// Der Fokus-Modus (hebt den aktuellen Satz hervor) und der Wortzähler.
import 'fokus_controller.dart';

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
  /// Es ist unser eigener `FokusTextController` – er sorgt zusätzlich dafür,
  /// dass der Satz, an dem du gerade schreibst, hervorgehoben wird.
  final FokusTextController _textController = FokusTextController();

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

    if (eintrag != null) _eintragAnzeigen(eintrag);
    setState(() => _laedt = false);

    // Tastatur öffnen. `requestFocus` aktiviert das Eingabefeld.
    _fokus.requestFocus();
  }

  /// Zeigt einen vorhandenen [eintrag] auf der Schreibseite an, sodass du
  /// darin weiterschreiben kannst. Wird beim Start (15-Minuten-Regel) und
  /// beim Öffnen eines Eintrags aus der Übersicht verwendet.
  void _eintragAnzeigen(Eintrag eintrag) {
    setState(() {
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
    });
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
    _seiteZuruecksetzen();
  }

  /// Leert die Seite OHNE vorher zu speichern. Nur direkt verwenden, wenn
  /// bereits alles gesichert ist (oder der Eintrag gar nicht mehr existiert).
  void _seiteZuruecksetzen() {
    setState(() {
      _eintragId = null;
      _datum = DateTime.now();
      _gespeicherterText = '';
      _textController.clear();
      _status = SpeicherStatus.keiner;
    });
    _fokus.requestFocus();
  }

  // ---------------------------------------------------------------------------
  // ÜBERSICHT ÖFFNEN
  // ---------------------------------------------------------------------------

  /// Öffnet die Übersicht aller Einträge.
  ///
  /// Ablauf:
  ///   1. Aktuellen Text sichern.
  ///   2. Übersicht anzeigen und warten, bis sie wieder geschlossen wird.
  ///   3. Wurde ein Eintrag angetippt, kommt seine id zurück → diesen öffnen.
  ///   4. Sicherheitscheck: Wurde der gerade offene Eintrag in der Übersicht
  ///      gelöscht? → neue Seite, sonst würde ins Leere gespeichert.
  Future<void> _eintraegeOeffnen() async {
    await _sofortSpeichern();
    // Nach einem `await` immer prüfen, ob der Bildschirm noch existiert,
    // bevor wir `context` benutzen.
    if (!mounted) return;

    // `Navigator.push` legt die Übersicht oben auf den Bildschirm-Stapel.
    // `MaterialPageRoute` sorgt für die typische Übergangsanimation.
    // `<int>` = wir erwarten als Ergebnis eine Zahl (die id) – oder `null`,
    // wenn einfach mit dem Zurück-Pfeil geschlossen wurde.
    final gewaehlteId = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => EintraegeBildschirm(datenbank: widget.datenbank),
      ),
    );
    if (!mounted) return;

    // Fall 3: Ein Eintrag wurde angetippt → laden und anzeigen.
    if (gewaehlteId != null) {
      final eintrag = await widget.datenbank.eintragLaden(gewaehlteId);
      if (!mounted) return;
      if (eintrag != null) {
        _eintragAnzeigen(eintrag);
        _fokus.requestFocus();
        return;
      }
    }

    // Fall 4: Existiert der offene Eintrag noch?
    final offeneId = _eintragId;
    if (offeneId != null &&
        await widget.datenbank.eintragLaden(offeneId) == null) {
      if (!mounted) return;
      _seiteZuruecksetzen();
    }
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
  ///
  /// Aufbau in Ebenen (ein `Stack` legt Widgets ÜBEREINANDER, das erste
  /// ganz unten):
  ///   1. Sternenhimmel (Hintergrund)
  ///   2. Buchrücken-Linie am linken Rand
  ///   3. Der eigentliche Inhalt: Kopfzeile, Leuchtlinie, Schreibfeld, Fußzeile
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // `Positioned.fill` = füllt den ganzen Stack aus.
          const Positioned.fill(child: Sternenhimmel()),
          const Buchruecken(),
          // `SafeArea` hält Abstand zu Kamera-Aussparung, Statusleiste usw.
          SafeArea(
            child: Column(
              children: [
                _kopfzeile(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(34, 0, 16, 0),
                  child: Trennleuchtlinie(),
                ),
                // `Expanded` lässt das Schreibfeld den freien Platz füllen.
                Expanded(child: _schreibfeld()),
                _fusszeile(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Die Kopfzeile: links „Einträge“, Mitte Datum, rechts „Neue Seite“.
  Widget _kopfzeile() {
    // Datum auf Deutsch formatieren:
    //   oben klein „MITTWOCH · 22:41“ (EEEE = Wochentag, HH:mm = Uhrzeit),
    //   darunter groß „25. November“ (d = Tag, MMMM = Monat ausgeschrieben).
    final wochentagUndZeit =
        DateFormat('EEEE · HH:mm', 'de_DE').format(_datum).toUpperCase();
    final datum = DateFormat('d. MMMM', 'de_DE').format(_datum);

    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 12, 16, 14),
      // `Row` ordnet Widgets NEBENEINANDER an (das Gegenstück zu `Column`).
      child: Row(
        children: [
          NeonKnopf(
            symbol: Icons.auto_stories, // Buch-Symbol
            hinweis: 'Einträge',
            // Während des Ladens deaktiviert (`null` = ausgegraut).
            beiDruck: _laedt ? null : _eintraegeOeffnen,
          ),
          // Die Mitte nimmt den restlichen Platz ein, Text zentriert.
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wochentagUndZeit,
                  style: GedankengutSchriften.beschriftungLeuchtend,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(datum, style: GedankengutSchriften.datumKopf),
              ],
            ),
          ),
          NeonKnopf(
            symbol: Icons.add,
            hinweis: 'Neue Seite',
            farbe: NeonFarbe.magenta,
            beiDruck: _laedt ? null : _neueSeite,
          ),
        ],
      ),
    );
  }

  /// Das Schreibfeld – hier tippst du deine Gedanken.
  Widget _schreibfeld() {
    return Padding(
      // Links mehr Abstand wegen der Buchrücken-Linie.
      padding: const EdgeInsets.fromLTRB(40, 22, 26, 0),
      child: TextField(
        controller: _textController,
        focusNode: _fokus,
        // Während des Ladens kein Tippen möglich.
        enabled: !_laedt,
        onChanged: _beiTextAenderung,
        // `maxLines: null` + `expands: true` = beliebig viele Zeilen,
        // Feld füllt die ganze Höhe aus.
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        // Satzanfänge automatisch großschreiben.
        textCapitalization: TextCapitalization.sentences,
        // Text oben beginnen (statt vertikal zentriert).
        textAlignVertical: TextAlignVertical.top,
        // Playfair, 18,5 Pixel, etwas dünner, viel Zeilenabstand.
        style: GedankengutSchriften.schreibtext,
        // `InputDecoration.collapsed` = ohne Rahmen und Linie, nur der
        // Hinweistext. Wie ein leeres Blatt Papier.
        decoration: InputDecoration.collapsed(
          hintText: SchreibBildschirm.hinweisText,
          hintStyle: GedankengutSchriften.schreibtext.copyWith(
            color: GedankengutFarben.gedaempft,
          ),
        ),
      ),
    );
  }

  /// Die Fußzeile: links die Wortanzahl, rechts der Speicherstatus.
  Widget _fusszeile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 10, 26, 16),
      child: Row(
        // Links und rechts ausrichten, Platz dazwischen.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // `ValueListenableBuilder` hört direkt auf den Text-Controller und
          // baut NUR diese kleine Anzeige neu, wenn sich der Text ändert –
          // nicht den ganzen Bildschirm. Das hält das Tippen flüssig.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _textController,
            builder: (context, wert, _) {
              final anzahl = woerterZaehlen(wert.text);
              // Leere Seite → keine Anzeige.
              if (anzahl == 0) return const SizedBox.shrink();
              return Text(
                anzahl == 1 ? '1 WORT' : '$anzahl WÖRTER',
                style: GedankengutSchriften.beschriftung,
              );
            },
          ),
          _statusAnzeige(),
        ],
      ),
    );
  }

  /// Baut die Statusanzeige: leuchtender Punkt + „GESPEICHERT“ bzw.
  /// „SPEICHERT …“ – oder nichts, wenn es (noch) nichts zu speichern gibt.
  Widget _statusAnzeige() {
    // `switch` wählt je nach Status den passenden Text.
    final text = switch (_status) {
      SpeicherStatus.keiner => null,
      SpeicherStatus.speichert => 'SPEICHERT …',
      SpeicherStatus.gespeichert => 'GESPEICHERT',
    };
    if (text == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Der kleine leuchtende Punkt in Ultramarin.
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: GedankengutFarben.ultramarin,
            shape: BoxShape.circle,
            boxShadow: GedankengutFarben.flaechenLeuchten(
              GedankengutFarben.ultramarin,
              radius: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: GedankengutSchriften.beschriftung),
      ],
    );
  }
}
