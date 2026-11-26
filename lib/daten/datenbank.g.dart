// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datenbank.dart';

// ignore_for_file: type=lint
class $KapitelTabelleTable extends KapitelTabelle
    with TableInfo<$KapitelTabelleTable, Kapitel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KapitelTabelleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titelMeta = const VerificationMeta('titel');
  @override
  late final GeneratedColumn<String> titel = GeneratedColumn<String>(
    'titel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _erstelltAmMeta = const VerificationMeta(
    'erstelltAm',
  );
  @override
  late final GeneratedColumn<DateTime> erstelltAm = GeneratedColumn<DateTime>(
    'erstellt_am',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, titel, erstelltAm];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kapitel';
  @override
  VerificationContext validateIntegrity(
    Insertable<Kapitel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('titel')) {
      context.handle(
        _titelMeta,
        titel.isAcceptableOrUnknown(data['titel']!, _titelMeta),
      );
    } else if (isInserting) {
      context.missing(_titelMeta);
    }
    if (data.containsKey('erstellt_am')) {
      context.handle(
        _erstelltAmMeta,
        erstelltAm.isAcceptableOrUnknown(data['erstellt_am']!, _erstelltAmMeta),
      );
    } else if (isInserting) {
      context.missing(_erstelltAmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Kapitel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Kapitel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      titel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titel'],
      )!,
      erstelltAm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}erstellt_am'],
      )!,
    );
  }

  @override
  $KapitelTabelleTable createAlias(String alias) {
    return $KapitelTabelleTable(attachedDatabase, alias);
  }
}

class Kapitel extends DataClass implements Insertable<Kapitel> {
  /// Eindeutige Nummer des Kapitels (automatisch vergeben).
  final int id;

  /// Name des Kapitels, z. B. „Neuanfänge“.
  final String titel;

  /// Wann das Kapitel angelegt wurde (bestimmt die Reihenfolge im Buch).
  final DateTime erstelltAm;
  const Kapitel({
    required this.id,
    required this.titel,
    required this.erstelltAm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['titel'] = Variable<String>(titel);
    map['erstellt_am'] = Variable<DateTime>(erstelltAm);
    return map;
  }

  KapitelTabelleCompanion toCompanion(bool nullToAbsent) {
    return KapitelTabelleCompanion(
      id: Value(id),
      titel: Value(titel),
      erstelltAm: Value(erstelltAm),
    );
  }

  factory Kapitel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Kapitel(
      id: serializer.fromJson<int>(json['id']),
      titel: serializer.fromJson<String>(json['titel']),
      erstelltAm: serializer.fromJson<DateTime>(json['erstelltAm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'titel': serializer.toJson<String>(titel),
      'erstelltAm': serializer.toJson<DateTime>(erstelltAm),
    };
  }

  Kapitel copyWith({int? id, String? titel, DateTime? erstelltAm}) => Kapitel(
    id: id ?? this.id,
    titel: titel ?? this.titel,
    erstelltAm: erstelltAm ?? this.erstelltAm,
  );
  Kapitel copyWithCompanion(KapitelTabelleCompanion data) {
    return Kapitel(
      id: data.id.present ? data.id.value : this.id,
      titel: data.titel.present ? data.titel.value : this.titel,
      erstelltAm: data.erstelltAm.present
          ? data.erstelltAm.value
          : this.erstelltAm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Kapitel(')
          ..write('id: $id, ')
          ..write('titel: $titel, ')
          ..write('erstelltAm: $erstelltAm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, titel, erstelltAm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Kapitel &&
          other.id == this.id &&
          other.titel == this.titel &&
          other.erstelltAm == this.erstelltAm);
}

class KapitelTabelleCompanion extends UpdateCompanion<Kapitel> {
  final Value<int> id;
  final Value<String> titel;
  final Value<DateTime> erstelltAm;
  const KapitelTabelleCompanion({
    this.id = const Value.absent(),
    this.titel = const Value.absent(),
    this.erstelltAm = const Value.absent(),
  });
  KapitelTabelleCompanion.insert({
    this.id = const Value.absent(),
    required String titel,
    required DateTime erstelltAm,
  }) : titel = Value(titel),
       erstelltAm = Value(erstelltAm);
  static Insertable<Kapitel> custom({
    Expression<int>? id,
    Expression<String>? titel,
    Expression<DateTime>? erstelltAm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titel != null) 'titel': titel,
      if (erstelltAm != null) 'erstellt_am': erstelltAm,
    });
  }

  KapitelTabelleCompanion copyWith({
    Value<int>? id,
    Value<String>? titel,
    Value<DateTime>? erstelltAm,
  }) {
    return KapitelTabelleCompanion(
      id: id ?? this.id,
      titel: titel ?? this.titel,
      erstelltAm: erstelltAm ?? this.erstelltAm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (titel.present) {
      map['titel'] = Variable<String>(titel.value);
    }
    if (erstelltAm.present) {
      map['erstellt_am'] = Variable<DateTime>(erstelltAm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KapitelTabelleCompanion(')
          ..write('id: $id, ')
          ..write('titel: $titel, ')
          ..write('erstelltAm: $erstelltAm')
          ..write(')'))
        .toString();
  }
}

class $EintraegeTable extends Eintraege
    with TableInfo<$EintraegeTable, Eintrag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EintraegeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _inhaltMeta = const VerificationMeta('inhalt');
  @override
  late final GeneratedColumn<String> inhalt = GeneratedColumn<String>(
    'inhalt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _erstelltAmMeta = const VerificationMeta(
    'erstelltAm',
  );
  @override
  late final GeneratedColumn<DateTime> erstelltAm = GeneratedColumn<DateTime>(
    'erstellt_am',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _geaendertAmMeta = const VerificationMeta(
    'geaendertAm',
  );
  @override
  late final GeneratedColumn<DateTime> geaendertAm = GeneratedColumn<DateTime>(
    'geaendert_am',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titelMeta = const VerificationMeta('titel');
  @override
  late final GeneratedColumn<String> titel = GeneratedColumn<String>(
    'titel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kapitelIdMeta = const VerificationMeta(
    'kapitelId',
  );
  @override
  late final GeneratedColumn<int> kapitelId = GeneratedColumn<int>(
    'kapitel_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kapitel (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _buchFassungMeta = const VerificationMeta(
    'buchFassung',
  );
  @override
  late final GeneratedColumn<String> buchFassung = GeneratedColumn<String>(
    'buch_fassung',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buchFassungAmMeta = const VerificationMeta(
    'buchFassungAm',
  );
  @override
  late final GeneratedColumn<DateTime> buchFassungAm =
      GeneratedColumn<DateTime>(
        'buch_fassung_am',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inhalt,
    erstelltAm,
    geaendertAm,
    titel,
    kapitelId,
    buchFassung,
    buchFassungAm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eintraege';
  @override
  VerificationContext validateIntegrity(
    Insertable<Eintrag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('inhalt')) {
      context.handle(
        _inhaltMeta,
        inhalt.isAcceptableOrUnknown(data['inhalt']!, _inhaltMeta),
      );
    } else if (isInserting) {
      context.missing(_inhaltMeta);
    }
    if (data.containsKey('erstellt_am')) {
      context.handle(
        _erstelltAmMeta,
        erstelltAm.isAcceptableOrUnknown(data['erstellt_am']!, _erstelltAmMeta),
      );
    } else if (isInserting) {
      context.missing(_erstelltAmMeta);
    }
    if (data.containsKey('geaendert_am')) {
      context.handle(
        _geaendertAmMeta,
        geaendertAm.isAcceptableOrUnknown(
          data['geaendert_am']!,
          _geaendertAmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_geaendertAmMeta);
    }
    if (data.containsKey('titel')) {
      context.handle(
        _titelMeta,
        titel.isAcceptableOrUnknown(data['titel']!, _titelMeta),
      );
    }
    if (data.containsKey('kapitel_id')) {
      context.handle(
        _kapitelIdMeta,
        kapitelId.isAcceptableOrUnknown(data['kapitel_id']!, _kapitelIdMeta),
      );
    }
    if (data.containsKey('buch_fassung')) {
      context.handle(
        _buchFassungMeta,
        buchFassung.isAcceptableOrUnknown(
          data['buch_fassung']!,
          _buchFassungMeta,
        ),
      );
    }
    if (data.containsKey('buch_fassung_am')) {
      context.handle(
        _buchFassungAmMeta,
        buchFassungAm.isAcceptableOrUnknown(
          data['buch_fassung_am']!,
          _buchFassungAmMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Eintrag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Eintrag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      inhalt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inhalt'],
      )!,
      erstelltAm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}erstellt_am'],
      )!,
      geaendertAm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}geaendert_am'],
      )!,
      titel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titel'],
      ),
      kapitelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kapitel_id'],
      ),
      buchFassung: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buch_fassung'],
      ),
      buchFassungAm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}buch_fassung_am'],
      ),
    );
  }

  @override
  $EintraegeTable createAlias(String alias) {
    return $EintraegeTable(attachedDatabase, alias);
  }
}

class Eintrag extends DataClass implements Insertable<Eintrag> {
  /// Eindeutige Nummer jedes Eintrags. `autoIncrement` heißt: Die Datenbank
  /// vergibt sie automatisch und zählt dabei hoch (1, 2, 3, …).
  final int id;

  /// Der eigentliche Text, den du geschrieben hast.
  final String inhalt;

  /// Wann der Eintrag angelegt wurde (ändert sich danach nie mehr).
  final DateTime erstelltAm;

  /// Wann der Eintrag zuletzt verändert wurde (wird bei jedem Speichern
  /// aktualisiert). Damit erkennen wir z. B., ob du gerade erst daran
  /// geschrieben hast (→ „15-Minuten-Regel“, siehe unten).
  /// WICHTIG: Zählt NUR dein eigenes Schreiben – Titel, Kapitel oder
  /// Buch-Fassung zu setzen ändert dieses Datum NICHT.
  final DateTime geaendertAm;

  /// Titel des Eintrags im Buch (z. B. „Die leise Frage“). Später von der
  /// KI vorgeschlagen; leer = Buch zeigt das Datum als Titel.
  final String? titel;

  /// Zu welchem Kapitel der Eintrag gehört (die `id` aus der Kapitel-Tabelle).
  ///
  /// `references(...)` macht daraus einen „Fremdschlüssel“: Die Datenbank
  /// prüft, dass es das Kapitel wirklich gibt. `onDelete: setNull` heißt:
  /// Wird das Kapitel gelöscht, wird dieses Feld automatisch geleert – der
  /// Eintrag selbst bleibt erhalten.
  final int? kapitelId;

  /// Die BUCH-FASSUNG: die geordnete, korrigierte, schön formatierte Version
  /// des Eintrags (später von der KI erstellt). Die Rohfassung in [inhalt]
  /// bleibt davon IMMER unberührt.
  final String? buchFassung;

  /// Wann die Buch-Fassung erstellt wurde. Ist die Rohfassung danach noch
  /// geändert worden (`geaendertAm` später), ist die Buch-Fassung veraltet.
  final DateTime? buchFassungAm;
  const Eintrag({
    required this.id,
    required this.inhalt,
    required this.erstelltAm,
    required this.geaendertAm,
    this.titel,
    this.kapitelId,
    this.buchFassung,
    this.buchFassungAm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['inhalt'] = Variable<String>(inhalt);
    map['erstellt_am'] = Variable<DateTime>(erstelltAm);
    map['geaendert_am'] = Variable<DateTime>(geaendertAm);
    if (!nullToAbsent || titel != null) {
      map['titel'] = Variable<String>(titel);
    }
    if (!nullToAbsent || kapitelId != null) {
      map['kapitel_id'] = Variable<int>(kapitelId);
    }
    if (!nullToAbsent || buchFassung != null) {
      map['buch_fassung'] = Variable<String>(buchFassung);
    }
    if (!nullToAbsent || buchFassungAm != null) {
      map['buch_fassung_am'] = Variable<DateTime>(buchFassungAm);
    }
    return map;
  }

  EintraegeCompanion toCompanion(bool nullToAbsent) {
    return EintraegeCompanion(
      id: Value(id),
      inhalt: Value(inhalt),
      erstelltAm: Value(erstelltAm),
      geaendertAm: Value(geaendertAm),
      titel: titel == null && nullToAbsent
          ? const Value.absent()
          : Value(titel),
      kapitelId: kapitelId == null && nullToAbsent
          ? const Value.absent()
          : Value(kapitelId),
      buchFassung: buchFassung == null && nullToAbsent
          ? const Value.absent()
          : Value(buchFassung),
      buchFassungAm: buchFassungAm == null && nullToAbsent
          ? const Value.absent()
          : Value(buchFassungAm),
    );
  }

  factory Eintrag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Eintrag(
      id: serializer.fromJson<int>(json['id']),
      inhalt: serializer.fromJson<String>(json['inhalt']),
      erstelltAm: serializer.fromJson<DateTime>(json['erstelltAm']),
      geaendertAm: serializer.fromJson<DateTime>(json['geaendertAm']),
      titel: serializer.fromJson<String?>(json['titel']),
      kapitelId: serializer.fromJson<int?>(json['kapitelId']),
      buchFassung: serializer.fromJson<String?>(json['buchFassung']),
      buchFassungAm: serializer.fromJson<DateTime?>(json['buchFassungAm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'inhalt': serializer.toJson<String>(inhalt),
      'erstelltAm': serializer.toJson<DateTime>(erstelltAm),
      'geaendertAm': serializer.toJson<DateTime>(geaendertAm),
      'titel': serializer.toJson<String?>(titel),
      'kapitelId': serializer.toJson<int?>(kapitelId),
      'buchFassung': serializer.toJson<String?>(buchFassung),
      'buchFassungAm': serializer.toJson<DateTime?>(buchFassungAm),
    };
  }

  Eintrag copyWith({
    int? id,
    String? inhalt,
    DateTime? erstelltAm,
    DateTime? geaendertAm,
    Value<String?> titel = const Value.absent(),
    Value<int?> kapitelId = const Value.absent(),
    Value<String?> buchFassung = const Value.absent(),
    Value<DateTime?> buchFassungAm = const Value.absent(),
  }) => Eintrag(
    id: id ?? this.id,
    inhalt: inhalt ?? this.inhalt,
    erstelltAm: erstelltAm ?? this.erstelltAm,
    geaendertAm: geaendertAm ?? this.geaendertAm,
    titel: titel.present ? titel.value : this.titel,
    kapitelId: kapitelId.present ? kapitelId.value : this.kapitelId,
    buchFassung: buchFassung.present ? buchFassung.value : this.buchFassung,
    buchFassungAm: buchFassungAm.present
        ? buchFassungAm.value
        : this.buchFassungAm,
  );
  Eintrag copyWithCompanion(EintraegeCompanion data) {
    return Eintrag(
      id: data.id.present ? data.id.value : this.id,
      inhalt: data.inhalt.present ? data.inhalt.value : this.inhalt,
      erstelltAm: data.erstelltAm.present
          ? data.erstelltAm.value
          : this.erstelltAm,
      geaendertAm: data.geaendertAm.present
          ? data.geaendertAm.value
          : this.geaendertAm,
      titel: data.titel.present ? data.titel.value : this.titel,
      kapitelId: data.kapitelId.present ? data.kapitelId.value : this.kapitelId,
      buchFassung: data.buchFassung.present
          ? data.buchFassung.value
          : this.buchFassung,
      buchFassungAm: data.buchFassungAm.present
          ? data.buchFassungAm.value
          : this.buchFassungAm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Eintrag(')
          ..write('id: $id, ')
          ..write('inhalt: $inhalt, ')
          ..write('erstelltAm: $erstelltAm, ')
          ..write('geaendertAm: $geaendertAm, ')
          ..write('titel: $titel, ')
          ..write('kapitelId: $kapitelId, ')
          ..write('buchFassung: $buchFassung, ')
          ..write('buchFassungAm: $buchFassungAm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inhalt,
    erstelltAm,
    geaendertAm,
    titel,
    kapitelId,
    buchFassung,
    buchFassungAm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Eintrag &&
          other.id == this.id &&
          other.inhalt == this.inhalt &&
          other.erstelltAm == this.erstelltAm &&
          other.geaendertAm == this.geaendertAm &&
          other.titel == this.titel &&
          other.kapitelId == this.kapitelId &&
          other.buchFassung == this.buchFassung &&
          other.buchFassungAm == this.buchFassungAm);
}

class EintraegeCompanion extends UpdateCompanion<Eintrag> {
  final Value<int> id;
  final Value<String> inhalt;
  final Value<DateTime> erstelltAm;
  final Value<DateTime> geaendertAm;
  final Value<String?> titel;
  final Value<int?> kapitelId;
  final Value<String?> buchFassung;
  final Value<DateTime?> buchFassungAm;
  const EintraegeCompanion({
    this.id = const Value.absent(),
    this.inhalt = const Value.absent(),
    this.erstelltAm = const Value.absent(),
    this.geaendertAm = const Value.absent(),
    this.titel = const Value.absent(),
    this.kapitelId = const Value.absent(),
    this.buchFassung = const Value.absent(),
    this.buchFassungAm = const Value.absent(),
  });
  EintraegeCompanion.insert({
    this.id = const Value.absent(),
    required String inhalt,
    required DateTime erstelltAm,
    required DateTime geaendertAm,
    this.titel = const Value.absent(),
    this.kapitelId = const Value.absent(),
    this.buchFassung = const Value.absent(),
    this.buchFassungAm = const Value.absent(),
  }) : inhalt = Value(inhalt),
       erstelltAm = Value(erstelltAm),
       geaendertAm = Value(geaendertAm);
  static Insertable<Eintrag> custom({
    Expression<int>? id,
    Expression<String>? inhalt,
    Expression<DateTime>? erstelltAm,
    Expression<DateTime>? geaendertAm,
    Expression<String>? titel,
    Expression<int>? kapitelId,
    Expression<String>? buchFassung,
    Expression<DateTime>? buchFassungAm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inhalt != null) 'inhalt': inhalt,
      if (erstelltAm != null) 'erstellt_am': erstelltAm,
      if (geaendertAm != null) 'geaendert_am': geaendertAm,
      if (titel != null) 'titel': titel,
      if (kapitelId != null) 'kapitel_id': kapitelId,
      if (buchFassung != null) 'buch_fassung': buchFassung,
      if (buchFassungAm != null) 'buch_fassung_am': buchFassungAm,
    });
  }

  EintraegeCompanion copyWith({
    Value<int>? id,
    Value<String>? inhalt,
    Value<DateTime>? erstelltAm,
    Value<DateTime>? geaendertAm,
    Value<String?>? titel,
    Value<int?>? kapitelId,
    Value<String?>? buchFassung,
    Value<DateTime?>? buchFassungAm,
  }) {
    return EintraegeCompanion(
      id: id ?? this.id,
      inhalt: inhalt ?? this.inhalt,
      erstelltAm: erstelltAm ?? this.erstelltAm,
      geaendertAm: geaendertAm ?? this.geaendertAm,
      titel: titel ?? this.titel,
      kapitelId: kapitelId ?? this.kapitelId,
      buchFassung: buchFassung ?? this.buchFassung,
      buchFassungAm: buchFassungAm ?? this.buchFassungAm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (inhalt.present) {
      map['inhalt'] = Variable<String>(inhalt.value);
    }
    if (erstelltAm.present) {
      map['erstellt_am'] = Variable<DateTime>(erstelltAm.value);
    }
    if (geaendertAm.present) {
      map['geaendert_am'] = Variable<DateTime>(geaendertAm.value);
    }
    if (titel.present) {
      map['titel'] = Variable<String>(titel.value);
    }
    if (kapitelId.present) {
      map['kapitel_id'] = Variable<int>(kapitelId.value);
    }
    if (buchFassung.present) {
      map['buch_fassung'] = Variable<String>(buchFassung.value);
    }
    if (buchFassungAm.present) {
      map['buch_fassung_am'] = Variable<DateTime>(buchFassungAm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EintraegeCompanion(')
          ..write('id: $id, ')
          ..write('inhalt: $inhalt, ')
          ..write('erstelltAm: $erstelltAm, ')
          ..write('geaendertAm: $geaendertAm, ')
          ..write('titel: $titel, ')
          ..write('kapitelId: $kapitelId, ')
          ..write('buchFassung: $buchFassung, ')
          ..write('buchFassungAm: $buchFassungAm')
          ..write(')'))
        .toString();
  }
}

abstract class _$GedankengutDatenbank extends GeneratedDatabase {
  _$GedankengutDatenbank(QueryExecutor e) : super(e);
  $GedankengutDatenbankManager get managers =>
      $GedankengutDatenbankManager(this);
  late final $KapitelTabelleTable kapitelTabelle = $KapitelTabelleTable(this);
  late final $EintraegeTable eintraege = $EintraegeTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    kapitelTabelle,
    eintraege,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'kapitel',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('eintraege', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$KapitelTabelleTableCreateCompanionBuilder =
    KapitelTabelleCompanion Function({
      Value<int> id,
      required String titel,
      required DateTime erstelltAm,
    });
typedef $$KapitelTabelleTableUpdateCompanionBuilder =
    KapitelTabelleCompanion Function({
      Value<int> id,
      Value<String> titel,
      Value<DateTime> erstelltAm,
    });

final class $$KapitelTabelleTableReferences
    extends
        BaseReferences<_$GedankengutDatenbank, $KapitelTabelleTable, Kapitel> {
  $$KapitelTabelleTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$EintraegeTable, List<Eintrag>>
  _eintraegeRefsTable(_$GedankengutDatenbank db) =>
      MultiTypedResultKey.fromTable(
        db.eintraege,
        aliasName: 'kapitel__id__eintraege__kapitel_id',
      );

  $$EintraegeTableProcessedTableManager get eintraegeRefs {
    final manager = $$EintraegeTableTableManager(
      $_db,
      $_db.eintraege,
    ).filter((f) => f.kapitelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eintraegeRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KapitelTabelleTableFilterComposer
    extends Composer<_$GedankengutDatenbank, $KapitelTabelleTable> {
  $$KapitelTabelleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titel => $composableBuilder(
    column: $table.titel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eintraegeRefs(
    Expression<bool> Function($$EintraegeTableFilterComposer f) f,
  ) {
    final $$EintraegeTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eintraege,
      getReferencedColumn: (t) => t.kapitelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EintraegeTableFilterComposer(
            $db: $db,
            $table: $db.eintraege,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KapitelTabelleTableOrderingComposer
    extends Composer<_$GedankengutDatenbank, $KapitelTabelleTable> {
  $$KapitelTabelleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titel => $composableBuilder(
    column: $table.titel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KapitelTabelleTableAnnotationComposer
    extends Composer<_$GedankengutDatenbank, $KapitelTabelleTable> {
  $$KapitelTabelleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titel =>
      $composableBuilder(column: $table.titel, builder: (column) => column);

  GeneratedColumn<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => column,
  );

  Expression<T> eintraegeRefs<T extends Object>(
    Expression<T> Function($$EintraegeTableAnnotationComposer a) f,
  ) {
    final $$EintraegeTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eintraege,
      getReferencedColumn: (t) => t.kapitelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EintraegeTableAnnotationComposer(
            $db: $db,
            $table: $db.eintraege,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KapitelTabelleTableTableManager
    extends
        RootTableManager<
          _$GedankengutDatenbank,
          $KapitelTabelleTable,
          Kapitel,
          $$KapitelTabelleTableFilterComposer,
          $$KapitelTabelleTableOrderingComposer,
          $$KapitelTabelleTableAnnotationComposer,
          $$KapitelTabelleTableCreateCompanionBuilder,
          $$KapitelTabelleTableUpdateCompanionBuilder,
          (Kapitel, $$KapitelTabelleTableReferences),
          Kapitel,
          PrefetchHooks Function({bool eintraegeRefs})
        > {
  $$KapitelTabelleTableTableManager(
    _$GedankengutDatenbank db,
    $KapitelTabelleTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KapitelTabelleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KapitelTabelleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KapitelTabelleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> titel = const Value.absent(),
                Value<DateTime> erstelltAm = const Value.absent(),
              }) => KapitelTabelleCompanion(
                id: id,
                titel: titel,
                erstelltAm: erstelltAm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String titel,
                required DateTime erstelltAm,
              }) => KapitelTabelleCompanion.insert(
                id: id,
                titel: titel,
                erstelltAm: erstelltAm,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KapitelTabelleTable, Kapitel>(table),
                  $$KapitelTabelleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eintraegeRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (eintraegeRefs) db.eintraege],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eintraegeRefs)
                    await $_getPrefetchedDataByColumns<
                      Kapitel,
                      $KapitelTabelleTable,
                      Eintrag,
                      $EintraegeTable
                    >(
                      currentTable: table,
                      referencedTable: $$KapitelTabelleTableReferences
                          ._eintraegeRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$KapitelTabelleTableReferences(
                            db,
                            table,
                            p0,
                          ).eintraegeRefs,
                      currentColumn: 'id',
                      referencedColumn: 'kapitel_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$KapitelTabelleTableProcessedTableManager =
    ProcessedTableManager<
      _$GedankengutDatenbank,
      $KapitelTabelleTable,
      Kapitel,
      $$KapitelTabelleTableFilterComposer,
      $$KapitelTabelleTableOrderingComposer,
      $$KapitelTabelleTableAnnotationComposer,
      $$KapitelTabelleTableCreateCompanionBuilder,
      $$KapitelTabelleTableUpdateCompanionBuilder,
      (Kapitel, $$KapitelTabelleTableReferences),
      Kapitel,
      PrefetchHooks Function({bool eintraegeRefs})
    >;
typedef $$EintraegeTableCreateCompanionBuilder = EintraegeCompanion Function({
  Value<int> id,
  required String inhalt,
  required DateTime erstelltAm,
  required DateTime geaendertAm,
  Value<String?> titel,
  Value<int?> kapitelId,
  Value<String?> buchFassung,
  Value<DateTime?> buchFassungAm,
});
typedef $$EintraegeTableUpdateCompanionBuilder = EintraegeCompanion Function({
  Value<int> id,
  Value<String> inhalt,
  Value<DateTime> erstelltAm,
  Value<DateTime> geaendertAm,
  Value<String?> titel,
  Value<int?> kapitelId,
  Value<String?> buchFassung,
  Value<DateTime?> buchFassungAm,
});

final class $$EintraegeTableReferences
    extends BaseReferences<_$GedankengutDatenbank, $EintraegeTable, Eintrag> {
  $$EintraegeTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KapitelTabelleTable _kapitelIdTable(_$GedankengutDatenbank db) =>
      db.kapitelTabelle.createAlias('eintraege__kapitel_id__kapitel__id');

  $$KapitelTabelleTableProcessedTableManager? get kapitelId {
    final $_column = $_itemColumn<int>('kapitel_id');
    if ($_column == null) return null;
    final manager = $$KapitelTabelleTableTableManager(
      $_db,
      $_db.kapitelTabelle,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_kapitelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EintraegeTableFilterComposer
    extends Composer<_$GedankengutDatenbank, $EintraegeTable> {
  $$EintraegeTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inhalt => $composableBuilder(
    column: $table.inhalt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get geaendertAm => $composableBuilder(
    column: $table.geaendertAm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titel => $composableBuilder(
    column: $table.titel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buchFassung => $composableBuilder(
    column: $table.buchFassung,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get buchFassungAm => $composableBuilder(
    column: $table.buchFassungAm,
    builder: (column) => ColumnFilters(column),
  );

  $$KapitelTabelleTableFilterComposer get kapitelId {
    final $$KapitelTabelleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.kapitelId,
      referencedTable: $db.kapitelTabelle,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KapitelTabelleTableFilterComposer(
            $db: $db,
            $table: $db.kapitelTabelle,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EintraegeTableOrderingComposer
    extends Composer<_$GedankengutDatenbank, $EintraegeTable> {
  $$EintraegeTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inhalt => $composableBuilder(
    column: $table.inhalt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get geaendertAm => $composableBuilder(
    column: $table.geaendertAm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titel => $composableBuilder(
    column: $table.titel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buchFassung => $composableBuilder(
    column: $table.buchFassung,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get buchFassungAm => $composableBuilder(
    column: $table.buchFassungAm,
    builder: (column) => ColumnOrderings(column),
  );

  $$KapitelTabelleTableOrderingComposer get kapitelId {
    final $$KapitelTabelleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.kapitelId,
      referencedTable: $db.kapitelTabelle,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KapitelTabelleTableOrderingComposer(
            $db: $db,
            $table: $db.kapitelTabelle,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EintraegeTableAnnotationComposer
    extends Composer<_$GedankengutDatenbank, $EintraegeTable> {
  $$EintraegeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inhalt =>
      $composableBuilder(column: $table.inhalt, builder: (column) => column);

  GeneratedColumn<DateTime> get erstelltAm => $composableBuilder(
    column: $table.erstelltAm,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get geaendertAm => $composableBuilder(
    column: $table.geaendertAm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titel =>
      $composableBuilder(column: $table.titel, builder: (column) => column);

  GeneratedColumn<String> get buchFassung => $composableBuilder(
    column: $table.buchFassung,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get buchFassungAm => $composableBuilder(
    column: $table.buchFassungAm,
    builder: (column) => column,
  );

  $$KapitelTabelleTableAnnotationComposer get kapitelId {
    final $$KapitelTabelleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.kapitelId,
      referencedTable: $db.kapitelTabelle,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KapitelTabelleTableAnnotationComposer(
            $db: $db,
            $table: $db.kapitelTabelle,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EintraegeTableTableManager
    extends
        RootTableManager<
          _$GedankengutDatenbank,
          $EintraegeTable,
          Eintrag,
          $$EintraegeTableFilterComposer,
          $$EintraegeTableOrderingComposer,
          $$EintraegeTableAnnotationComposer,
          $$EintraegeTableCreateCompanionBuilder,
          $$EintraegeTableUpdateCompanionBuilder,
          (Eintrag, $$EintraegeTableReferences),
          Eintrag,
          PrefetchHooks Function({bool kapitelId})
        > {
  $$EintraegeTableTableManager(_$GedankengutDatenbank db, $EintraegeTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EintraegeTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EintraegeTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EintraegeTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> inhalt = const Value.absent(),
                Value<DateTime> erstelltAm = const Value.absent(),
                Value<DateTime> geaendertAm = const Value.absent(),
                Value<String?> titel = const Value.absent(),
                Value<int?> kapitelId = const Value.absent(),
                Value<String?> buchFassung = const Value.absent(),
                Value<DateTime?> buchFassungAm = const Value.absent(),
              }) => EintraegeCompanion(
                id: id,
                inhalt: inhalt,
                erstelltAm: erstelltAm,
                geaendertAm: geaendertAm,
                titel: titel,
                kapitelId: kapitelId,
                buchFassung: buchFassung,
                buchFassungAm: buchFassungAm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String inhalt,
                required DateTime erstelltAm,
                required DateTime geaendertAm,
                Value<String?> titel = const Value.absent(),
                Value<int?> kapitelId = const Value.absent(),
                Value<String?> buchFassung = const Value.absent(),
                Value<DateTime?> buchFassungAm = const Value.absent(),
              }) => EintraegeCompanion.insert(
                id: id,
                inhalt: inhalt,
                erstelltAm: erstelltAm,
                geaendertAm: geaendertAm,
                titel: titel,
                kapitelId: kapitelId,
                buchFassung: buchFassung,
                buchFassungAm: buchFassungAm,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EintraegeTable, Eintrag>(table),
                  $$EintraegeTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({kapitelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (kapitelId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.kapitelId,
                        referencedTable: $$EintraegeTableReferences
                            ._kapitelIdTable(db),
                        referencedColumn: $$EintraegeTableReferences
                            ._kapitelIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EintraegeTableProcessedTableManager =
    ProcessedTableManager<
      _$GedankengutDatenbank,
      $EintraegeTable,
      Eintrag,
      $$EintraegeTableFilterComposer,
      $$EintraegeTableOrderingComposer,
      $$EintraegeTableAnnotationComposer,
      $$EintraegeTableCreateCompanionBuilder,
      $$EintraegeTableUpdateCompanionBuilder,
      (Eintrag, $$EintraegeTableReferences),
      Eintrag,
      PrefetchHooks Function({bool kapitelId})
    >;

class $GedankengutDatenbankManager {
  final _$GedankengutDatenbank _db;
  $GedankengutDatenbankManager(this._db);
  $$KapitelTabelleTableTableManager get kapitelTabelle =>
      $$KapitelTabelleTableTableManager(_db, _db.kapitelTabelle);
  $$EintraegeTableTableManager get eintraege =>
      $$EintraegeTableTableManager(_db, _db.eintraege);
}
