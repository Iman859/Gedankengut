// =============================================================================
// eintraege_bildschirm.dart – Die Übersicht aller Einträge
// =============================================================================
//
// Zeigt alle Einträge als Liste, die neuesten oben. Von hier aus kannst du:
//   - einen Eintrag ANTIPPEN → er öffnet sich auf der Schreibseite,
//   - einen Eintrag nach LINKS WISCHEN → löschen (mit Sicherheitsabfrage).
//
// NEU IN DIESER DATEI:
//   - `StreamBuilder`: Ein Widget, das einen Stream „abonniert“ und sich
//     automatisch neu zeichnet, sobald neue Daten kommen. Wird ein Eintrag
//     gelöscht, verschwindet er dadurch von selbst aus der Liste.
//   - `Navigator`: Flutters „Bildschirm-Stapel“. Neue Bildschirme werden
//     oben auf den Stapel gelegt (`push`), mit `pop` wird der oberste wieder
//     entfernt – dabei kann man ein Ergebnis zurückgeben. Wir geben die id
//     des angetippten Eintrags an die Schreibseite zurück.
//   - `Dismissible`: Macht ein Listenelement „wegwischbar“.
// =============================================================================

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../daten/datenbank.dart';

/// Die Übersicht – ein StatefulWidget, weil sie sich ein paar Dinge merken
/// muss (den Stream und frisch weggewischte Einträge, siehe unten).
class EintraegeBildschirm extends StatefulWidget {
  const EintraegeBildschirm({super.key, required this.datenbank});

  /// Die Datenbank, aus der die Einträge gelesen werden.
  final GedankengutDatenbank datenbank;

  /// Text, der erscheint, wenn es noch keine Einträge gibt.
  static const String leerText =
      'Noch keine Einträge.\nDein Buch wartet auf seine erste Seite.';

  @override
  State<EintraegeBildschirm> createState() => _EintraegeBildschirmState();
}

class _EintraegeBildschirmState extends State<EintraegeBildschirm> {
  /// Der Stream mit allen Einträgen. Wir erzeugen ihn EINMAL in `initState`
  /// (statt in `build`), weil `build` oft aufgerufen wird und sonst jedes Mal
  /// eine neue Datenbank-Abfrage starten würde.
  late final Stream<List<Eintrag>> _eintraege;

  /// ids von Einträgen, die gerade weggewischt wurden.
  ///
  /// Warum? `Dismissible` verlangt, dass ein weggewischtes Element SOFORT aus
  /// der Liste verschwindet. Die Datenbank meldet die Löschung aber erst einen
  /// Augenblick später über den Stream. Diese Menge überbrückt die Lücke:
  /// Was hier drinsteht, blenden wir sofort aus.
  /// Ein `Set` ist eine Sammlung ohne Duplikate – ideal für „ist drin / nicht drin“.
  final Set<int> _weggewischteIds = {};

  /// Datumsformat für die Liste, z. B. „Mi., 25. November 2026 · 22:41“.
  /// EEE = Wochentag kurz, d = Tag, MMMM = Monat lang, y = Jahr,
  /// HH:mm = Stunden:Minuten im 24-Stunden-Format.
  final DateFormat _datumFormat = DateFormat('EEE, d. MMMM y · HH:mm', 'de_DE');

  @override
  void initState() {
    super.initState();
    _eintraege = widget.datenbank.alleEintraegeBeobachten();
  }

  /// Zeigt die Sicherheitsabfrage vor dem Löschen.
  /// Gibt `true` zurück, wenn wirklich gelöscht werden soll.
  Future<bool> _loeschenBestaetigen() async {
    // `showDialog` öffnet ein Dialogfenster über dem Bildschirm und wartet,
    // bis es geschlossen wird. Der Wert, der beim Schließen an `pop`
    // übergeben wird, ist das Ergebnis.
    final bestaetigt = await showDialog<bool>(
      context: context,
      // `dialogContext` ist der Kontext INNERHALB des Dialogs – mit ihm
      // schließen wir genau den Dialog (und nicht die ganze Übersicht).
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text('Das kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    // Wird der Dialog anders geschlossen (z. B. daneben tippen), kommt `null`
    // zurück – das werten wir als „nicht löschen“.
    return bestaetigt ?? false;
  }

  /// Macht aus dem Eintragstext eine kurze, einzeilige Vorschau:
  /// Leerzeichen am Rand weg, Zeilenumbrüche und mehrfache Leerzeichen
  /// werden zu einem einzigen Leerzeichen.
  /// `RegExp(r'\s+')` ist ein Suchmuster: „ein oder mehrere Leerraum-Zeichen“.
  String _vorschau(String inhalt) =>
      inhalt.trim().replaceAll(RegExp(r'\s+'), ' ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Die AppBar bekommt automatisch einen Zurück-Pfeil, weil dieser
      // Bildschirm über einen anderen gelegt wurde (Navigator-Stapel).
      appBar: AppBar(title: const Text('Einträge')),
      body: StreamBuilder<List<Eintrag>>(
        stream: _eintraege,
        // `builder` wird bei JEDEM neuen Wert aus dem Stream aufgerufen.
        // `snapshot` („Momentaufnahme“) enthält den aktuellen Stand.
        builder: (context, snapshot) {
          // Noch keine Daten da (die erste Abfrage läuft noch)?
          // → Vorerst nichts anzeigen; das dauert nur einen Wimpernschlag.
          if (!snapshot.hasData) return const SizedBox.shrink();

          // Alle Einträge – ohne die gerade weggewischten.
          // `where` filtert, `toList()` macht daraus wieder eine Liste.
          final eintraege = snapshot.data!
              .where((e) => !_weggewischteIds.contains(e.id))
              .toList();

          if (eintraege.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  EintraegeBildschirm.leerText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ),
            );
          }

          // `ListView.separated` baut eine scrollbare Liste und setzt
          // zwischen zwei Elemente jeweils einen Trenner (`Divider`).
          // Die Elemente werden erst gebaut, wenn sie sichtbar werden –
          // so bleibt die Liste auch bei tausenden Einträgen flüssig.
          return ListView.separated(
            itemCount: eintraege.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 24, endIndent: 24),
            itemBuilder: (context, index) {
              final eintrag = eintraege[index];
              return _eintragKachel(eintrag, theme);
            },
          );
        },
      ),
    );
  }

  /// Baut ein einzelnes Listenelement (eine „Kachel“) für einen Eintrag.
  Widget _eintragKachel(Eintrag eintrag, ThemeData theme) {
    return Dismissible(
      // Der `key` muss eindeutig sein, damit Flutter weiß, WELCHES Element
      // weggewischt wurde. Die Datenbank-id ist dafür perfekt.
      key: ValueKey(eintrag.id),
      // Nur nach links wischen (von Ende zu Anfang).
      direction: DismissDirection.endToStart,
      // Was beim Wischen hinter dem Element sichtbar wird: rot mit Papierkorb.
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      // Wird VOR dem Entfernen gefragt. Gibt sie `false` zurück, springt das
      // Element zurück an seinen Platz.
      confirmDismiss: (_) => _loeschenBestaetigen(),
      // Wird NACH dem bestätigten Wegwischen aufgerufen.
      onDismissed: (_) {
        setState(() => _weggewischteIds.add(eintrag.id));
        widget.datenbank.eintragLoeschen(eintrag.id);
      },
      // `ListTile` ist ein fertiges Listenelement mit Titel und Untertitel.
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Text(
          _datumFormat.format(eintrag.erstelltAm),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _vorschau(eintrag.inhalt),
            // Höchstens zwei Zeilen, danach „…“.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        // Antippen: Übersicht schließen und die id an die Schreibseite
        // zurückgeben – die öffnet daraufhin genau diesen Eintrag.
        onTap: () => Navigator.of(context).pop(eintrag.id),
      ),
    );
  }
}
