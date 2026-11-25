// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datenbank.dart';

// ignore_for_file: type=lint
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
  @override
  List<GeneratedColumn> get $columns => [id, inhalt, erstelltAm, geaendertAm];
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
  final DateTime geaendertAm;
  const Eintrag({
    required this.id,
    required this.inhalt,
    required this.erstelltAm,
    required this.geaendertAm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['inhalt'] = Variable<String>(inhalt);
    map['erstellt_am'] = Variable<DateTime>(erstelltAm);
    map['geaendert_am'] = Variable<DateTime>(geaendertAm);
    return map;
  }

  EintraegeCompanion toCompanion(bool nullToAbsent) {
    return EintraegeCompanion(
      id: Value(id),
      inhalt: Value(inhalt),
      erstelltAm: Value(erstelltAm),
      geaendertAm: Value(geaendertAm),
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
    };
  }

  Eintrag copyWith({
    int? id,
    String? inhalt,
    DateTime? erstelltAm,
    DateTime? geaendertAm,
  }) => Eintrag(
    id: id ?? this.id,
    inhalt: inhalt ?? this.inhalt,
    erstelltAm: erstelltAm ?? this.erstelltAm,
    geaendertAm: geaendertAm ?? this.geaendertAm,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('Eintrag(')
          ..write('id: $id, ')
          ..write('inhalt: $inhalt, ')
          ..write('erstelltAm: $erstelltAm, ')
          ..write('geaendertAm: $geaendertAm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, inhalt, erstelltAm, geaendertAm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Eintrag &&
          other.id == this.id &&
          other.inhalt == this.inhalt &&
          other.erstelltAm == this.erstelltAm &&
          other.geaendertAm == this.geaendertAm);
}

class EintraegeCompanion extends UpdateCompanion<Eintrag> {
  final Value<int> id;
  final Value<String> inhalt;
  final Value<DateTime> erstelltAm;
  final Value<DateTime> geaendertAm;
  const EintraegeCompanion({
    this.id = const Value.absent(),
    this.inhalt = const Value.absent(),
    this.erstelltAm = const Value.absent(),
    this.geaendertAm = const Value.absent(),
  });
  EintraegeCompanion.insert({
    this.id = const Value.absent(),
    required String inhalt,
    required DateTime erstelltAm,
    required DateTime geaendertAm,
  }) : inhalt = Value(inhalt),
       erstelltAm = Value(erstelltAm),
       geaendertAm = Value(geaendertAm);
  static Insertable<Eintrag> custom({
    Expression<int>? id,
    Expression<String>? inhalt,
    Expression<DateTime>? erstelltAm,
    Expression<DateTime>? geaendertAm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inhalt != null) 'inhalt': inhalt,
      if (erstelltAm != null) 'erstellt_am': erstelltAm,
      if (geaendertAm != null) 'geaendert_am': geaendertAm,
    });
  }

  EintraegeCompanion copyWith({
    Value<int>? id,
    Value<String>? inhalt,
    Value<DateTime>? erstelltAm,
    Value<DateTime>? geaendertAm,
  }) {
    return EintraegeCompanion(
      id: id ?? this.id,
      inhalt: inhalt ?? this.inhalt,
      erstelltAm: erstelltAm ?? this.erstelltAm,
      geaendertAm: geaendertAm ?? this.geaendertAm,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EintraegeCompanion(')
          ..write('id: $id, ')
          ..write('inhalt: $inhalt, ')
          ..write('erstelltAm: $erstelltAm, ')
          ..write('geaendertAm: $geaendertAm')
          ..write(')'))
        .toString();
  }
}

abstract class _$GedankengutDatenbank extends GeneratedDatabase {
  _$GedankengutDatenbank(QueryExecutor e) : super(e);
  $GedankengutDatenbankManager get managers =>
      $GedankengutDatenbankManager(this);
  late final $EintraegeTable eintraege = $EintraegeTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [eintraege];
}

typedef $$EintraegeTableCreateCompanionBuilder = EintraegeCompanion Function({
  Value<int> id,
  required String inhalt,
  required DateTime erstelltAm,
  required DateTime geaendertAm,
});
typedef $$EintraegeTableUpdateCompanionBuilder = EintraegeCompanion Function({
  Value<int> id,
  Value<String> inhalt,
  Value<DateTime> erstelltAm,
  Value<DateTime> geaendertAm,
});

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
          (
            Eintrag,
            BaseReferences<_$GedankengutDatenbank, $EintraegeTable, Eintrag>,
          ),
          Eintrag,
          PrefetchHooks Function()
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
              }) => EintraegeCompanion(
                id: id,
                inhalt: inhalt,
                erstelltAm: erstelltAm,
                geaendertAm: geaendertAm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String inhalt,
                required DateTime erstelltAm,
                required DateTime geaendertAm,
              }) => EintraegeCompanion.insert(
                id: id,
                inhalt: inhalt,
                erstelltAm: erstelltAm,
                geaendertAm: geaendertAm,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EintraegeTable, Eintrag>(table),
                  BaseReferences<
                    _$GedankengutDatenbank,
                    $EintraegeTable,
                    Eintrag
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
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
      (
        Eintrag,
        BaseReferences<_$GedankengutDatenbank, $EintraegeTable, Eintrag>,
      ),
      Eintrag,
      PrefetchHooks Function()
    >;

class $GedankengutDatenbankManager {
  final _$GedankengutDatenbank _db;
  $GedankengutDatenbankManager(this._db);
  $$EintraegeTableTableManager get eintraege =>
      $$EintraegeTableTableManager(_db, _db.eintraege);
}
