// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SentenceListsTable extends SentenceLists
    with TableInfo<$SentenceListsTable, SentenceList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SentenceListsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ListKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ListKind>($SentenceListsTable.$converterkind);
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedKeyMeta = const VerificationMeta(
    'seedKey',
  );
  @override
  late final GeneratedColumn<String> seedKey = GeneratedColumn<String>(
    'seed_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seedLanguageMeta = const VerificationMeta(
    'seedLanguage',
  );
  @override
  late final GeneratedColumn<String> seedLanguage = GeneratedColumn<String>(
    'seed_language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    kind,
    pinned,
    position,
    seedKey,
    seedLanguage,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sentence_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<SentenceList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('seed_key')) {
      context.handle(
        _seedKeyMeta,
        seedKey.isAcceptableOrUnknown(data['seed_key']!, _seedKeyMeta),
      );
    }
    if (data.containsKey('seed_language')) {
      context.handle(
        _seedLanguageMeta,
        seedLanguage.isAcceptableOrUnknown(
          data['seed_language']!,
          _seedLanguageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {seedLanguage, seedKey},
  ];
  @override
  SentenceList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SentenceList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      kind: $SentenceListsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      seedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_key'],
      ),
      seedLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_language'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SentenceListsTable createAlias(String alias) {
    return $SentenceListsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ListKind, String, String> $converterkind =
      const EnumNameConverter<ListKind>(ListKind.values);
}

class SentenceList extends DataClass implements Insertable<SentenceList> {
  final int id;
  final String title;
  final ListKind kind;
  final bool pinned;
  final int position;
  final String? seedKey;

  /// Seed file the list came from (`hu`, `en`, ...); null for user lists and
  /// history. The same seed list can exist once per language.
  final String? seedLanguage;
  final DateTime createdAt;
  const SentenceList({
    required this.id,
    required this.title,
    required this.kind,
    required this.pinned,
    required this.position,
    this.seedKey,
    this.seedLanguage,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    {
      map['kind'] = Variable<String>(
        $SentenceListsTable.$converterkind.toSql(kind),
      );
    }
    map['pinned'] = Variable<bool>(pinned);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || seedKey != null) {
      map['seed_key'] = Variable<String>(seedKey);
    }
    if (!nullToAbsent || seedLanguage != null) {
      map['seed_language'] = Variable<String>(seedLanguage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SentenceListsCompanion toCompanion(bool nullToAbsent) {
    return SentenceListsCompanion(
      id: Value(id),
      title: Value(title),
      kind: Value(kind),
      pinned: Value(pinned),
      position: Value(position),
      seedKey: seedKey == null && nullToAbsent
          ? const Value.absent()
          : Value(seedKey),
      seedLanguage: seedLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(seedLanguage),
      createdAt: Value(createdAt),
    );
  }

  factory SentenceList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SentenceList(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      kind: $SentenceListsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      pinned: serializer.fromJson<bool>(json['pinned']),
      position: serializer.fromJson<int>(json['position']),
      seedKey: serializer.fromJson<String?>(json['seedKey']),
      seedLanguage: serializer.fromJson<String?>(json['seedLanguage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'kind': serializer.toJson<String>(
        $SentenceListsTable.$converterkind.toJson(kind),
      ),
      'pinned': serializer.toJson<bool>(pinned),
      'position': serializer.toJson<int>(position),
      'seedKey': serializer.toJson<String?>(seedKey),
      'seedLanguage': serializer.toJson<String?>(seedLanguage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SentenceList copyWith({
    int? id,
    String? title,
    ListKind? kind,
    bool? pinned,
    int? position,
    Value<String?> seedKey = const Value.absent(),
    Value<String?> seedLanguage = const Value.absent(),
    DateTime? createdAt,
  }) => SentenceList(
    id: id ?? this.id,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    pinned: pinned ?? this.pinned,
    position: position ?? this.position,
    seedKey: seedKey.present ? seedKey.value : this.seedKey,
    seedLanguage: seedLanguage.present ? seedLanguage.value : this.seedLanguage,
    createdAt: createdAt ?? this.createdAt,
  );
  SentenceList copyWithCompanion(SentenceListsCompanion data) {
    return SentenceList(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      position: data.position.present ? data.position.value : this.position,
      seedKey: data.seedKey.present ? data.seedKey.value : this.seedKey,
      seedLanguage: data.seedLanguage.present
          ? data.seedLanguage.value
          : this.seedLanguage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SentenceList(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('pinned: $pinned, ')
          ..write('position: $position, ')
          ..write('seedKey: $seedKey, ')
          ..write('seedLanguage: $seedLanguage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    kind,
    pinned,
    position,
    seedKey,
    seedLanguage,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SentenceList &&
          other.id == this.id &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.pinned == this.pinned &&
          other.position == this.position &&
          other.seedKey == this.seedKey &&
          other.seedLanguage == this.seedLanguage &&
          other.createdAt == this.createdAt);
}

class SentenceListsCompanion extends UpdateCompanion<SentenceList> {
  final Value<int> id;
  final Value<String> title;
  final Value<ListKind> kind;
  final Value<bool> pinned;
  final Value<int> position;
  final Value<String?> seedKey;
  final Value<String?> seedLanguage;
  final Value<DateTime> createdAt;
  const SentenceListsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.pinned = const Value.absent(),
    this.position = const Value.absent(),
    this.seedKey = const Value.absent(),
    this.seedLanguage = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SentenceListsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required ListKind kind,
    this.pinned = const Value.absent(),
    required int position,
    this.seedKey = const Value.absent(),
    this.seedLanguage = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       kind = Value(kind),
       position = Value(position);
  static Insertable<SentenceList> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<bool>? pinned,
    Expression<int>? position,
    Expression<String>? seedKey,
    Expression<String>? seedLanguage,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (pinned != null) 'pinned': pinned,
      if (position != null) 'position': position,
      if (seedKey != null) 'seed_key': seedKey,
      if (seedLanguage != null) 'seed_language': seedLanguage,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SentenceListsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<ListKind>? kind,
    Value<bool>? pinned,
    Value<int>? position,
    Value<String?>? seedKey,
    Value<String?>? seedLanguage,
    Value<DateTime>? createdAt,
  }) {
    return SentenceListsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      pinned: pinned ?? this.pinned,
      position: position ?? this.position,
      seedKey: seedKey ?? this.seedKey,
      seedLanguage: seedLanguage ?? this.seedLanguage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SentenceListsTable.$converterkind.toSql(kind.value),
      );
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (seedKey.present) {
      map['seed_key'] = Variable<String>(seedKey.value);
    }
    if (seedLanguage.present) {
      map['seed_language'] = Variable<String>(seedLanguage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SentenceListsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('pinned: $pinned, ')
          ..write('position: $position, ')
          ..write('seedKey: $seedKey, ')
          ..write('seedLanguage: $seedLanguage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SentencesTable extends Sentences
    with TableInfo<$SentencesTable, Sentence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SentencesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sentence_lists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saidMeta = const VerificationMeta('said');
  @override
  late final GeneratedColumn<bool> said = GeneratedColumn<bool>(
    'said',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("said" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recordingPathMeta = const VerificationMeta(
    'recordingPath',
  );
  @override
  late final GeneratedColumn<String> recordingPath = GeneratedColumn<String>(
    'recording_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seedKeyMeta = const VerificationMeta(
    'seedKey',
  );
  @override
  late final GeneratedColumn<String> seedKey = GeneratedColumn<String>(
    'seed_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spokenAtMeta = const VerificationMeta(
    'spokenAt',
  );
  @override
  late final GeneratedColumn<DateTime> spokenAt = GeneratedColumn<DateTime>(
    'spoken_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    body,
    position,
    said,
    recordingPath,
    seedKey,
    spokenAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sentences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sentence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('said')) {
      context.handle(
        _saidMeta,
        said.isAcceptableOrUnknown(data['said']!, _saidMeta),
      );
    }
    if (data.containsKey('recording_path')) {
      context.handle(
        _recordingPathMeta,
        recordingPath.isAcceptableOrUnknown(
          data['recording_path']!,
          _recordingPathMeta,
        ),
      );
    }
    if (data.containsKey('seed_key')) {
      context.handle(
        _seedKeyMeta,
        seedKey.isAcceptableOrUnknown(data['seed_key']!, _seedKeyMeta),
      );
    }
    if (data.containsKey('spoken_at')) {
      context.handle(
        _spokenAtMeta,
        spokenAt.isAcceptableOrUnknown(data['spoken_at']!, _spokenAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {listId, seedKey},
  ];
  @override
  Sentence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sentence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}list_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      said: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}said'],
      )!,
      recordingPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_path'],
      ),
      seedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_key'],
      ),
      spokenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}spoken_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SentencesTable createAlias(String alias) {
    return $SentencesTable(attachedDatabase, alias);
  }
}

class Sentence extends DataClass implements Insertable<Sentence> {
  final int id;
  final int listId;
  final String body;
  final int position;
  final bool said;
  final String? recordingPath;
  final String? seedKey;
  final DateTime? spokenAt;
  final DateTime createdAt;
  const Sentence({
    required this.id,
    required this.listId,
    required this.body,
    required this.position,
    required this.said,
    this.recordingPath,
    this.seedKey,
    this.spokenAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['list_id'] = Variable<int>(listId);
    map['body'] = Variable<String>(body);
    map['position'] = Variable<int>(position);
    map['said'] = Variable<bool>(said);
    if (!nullToAbsent || recordingPath != null) {
      map['recording_path'] = Variable<String>(recordingPath);
    }
    if (!nullToAbsent || seedKey != null) {
      map['seed_key'] = Variable<String>(seedKey);
    }
    if (!nullToAbsent || spokenAt != null) {
      map['spoken_at'] = Variable<DateTime>(spokenAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SentencesCompanion toCompanion(bool nullToAbsent) {
    return SentencesCompanion(
      id: Value(id),
      listId: Value(listId),
      body: Value(body),
      position: Value(position),
      said: Value(said),
      recordingPath: recordingPath == null && nullToAbsent
          ? const Value.absent()
          : Value(recordingPath),
      seedKey: seedKey == null && nullToAbsent
          ? const Value.absent()
          : Value(seedKey),
      spokenAt: spokenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(spokenAt),
      createdAt: Value(createdAt),
    );
  }

  factory Sentence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sentence(
      id: serializer.fromJson<int>(json['id']),
      listId: serializer.fromJson<int>(json['listId']),
      body: serializer.fromJson<String>(json['body']),
      position: serializer.fromJson<int>(json['position']),
      said: serializer.fromJson<bool>(json['said']),
      recordingPath: serializer.fromJson<String?>(json['recordingPath']),
      seedKey: serializer.fromJson<String?>(json['seedKey']),
      spokenAt: serializer.fromJson<DateTime?>(json['spokenAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'listId': serializer.toJson<int>(listId),
      'body': serializer.toJson<String>(body),
      'position': serializer.toJson<int>(position),
      'said': serializer.toJson<bool>(said),
      'recordingPath': serializer.toJson<String?>(recordingPath),
      'seedKey': serializer.toJson<String?>(seedKey),
      'spokenAt': serializer.toJson<DateTime?>(spokenAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Sentence copyWith({
    int? id,
    int? listId,
    String? body,
    int? position,
    bool? said,
    Value<String?> recordingPath = const Value.absent(),
    Value<String?> seedKey = const Value.absent(),
    Value<DateTime?> spokenAt = const Value.absent(),
    DateTime? createdAt,
  }) => Sentence(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    body: body ?? this.body,
    position: position ?? this.position,
    said: said ?? this.said,
    recordingPath: recordingPath.present
        ? recordingPath.value
        : this.recordingPath,
    seedKey: seedKey.present ? seedKey.value : this.seedKey,
    spokenAt: spokenAt.present ? spokenAt.value : this.spokenAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Sentence copyWithCompanion(SentencesCompanion data) {
    return Sentence(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      body: data.body.present ? data.body.value : this.body,
      position: data.position.present ? data.position.value : this.position,
      said: data.said.present ? data.said.value : this.said,
      recordingPath: data.recordingPath.present
          ? data.recordingPath.value
          : this.recordingPath,
      seedKey: data.seedKey.present ? data.seedKey.value : this.seedKey,
      spokenAt: data.spokenAt.present ? data.spokenAt.value : this.spokenAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sentence(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('body: $body, ')
          ..write('position: $position, ')
          ..write('said: $said, ')
          ..write('recordingPath: $recordingPath, ')
          ..write('seedKey: $seedKey, ')
          ..write('spokenAt: $spokenAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listId,
    body,
    position,
    said,
    recordingPath,
    seedKey,
    spokenAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sentence &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.body == this.body &&
          other.position == this.position &&
          other.said == this.said &&
          other.recordingPath == this.recordingPath &&
          other.seedKey == this.seedKey &&
          other.spokenAt == this.spokenAt &&
          other.createdAt == this.createdAt);
}

class SentencesCompanion extends UpdateCompanion<Sentence> {
  final Value<int> id;
  final Value<int> listId;
  final Value<String> body;
  final Value<int> position;
  final Value<bool> said;
  final Value<String?> recordingPath;
  final Value<String?> seedKey;
  final Value<DateTime?> spokenAt;
  final Value<DateTime> createdAt;
  const SentencesCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.body = const Value.absent(),
    this.position = const Value.absent(),
    this.said = const Value.absent(),
    this.recordingPath = const Value.absent(),
    this.seedKey = const Value.absent(),
    this.spokenAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SentencesCompanion.insert({
    this.id = const Value.absent(),
    required int listId,
    required String body,
    required int position,
    this.said = const Value.absent(),
    this.recordingPath = const Value.absent(),
    this.seedKey = const Value.absent(),
    this.spokenAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : listId = Value(listId),
       body = Value(body),
       position = Value(position);
  static Insertable<Sentence> custom({
    Expression<int>? id,
    Expression<int>? listId,
    Expression<String>? body,
    Expression<int>? position,
    Expression<bool>? said,
    Expression<String>? recordingPath,
    Expression<String>? seedKey,
    Expression<DateTime>? spokenAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (body != null) 'body': body,
      if (position != null) 'position': position,
      if (said != null) 'said': said,
      if (recordingPath != null) 'recording_path': recordingPath,
      if (seedKey != null) 'seed_key': seedKey,
      if (spokenAt != null) 'spoken_at': spokenAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SentencesCompanion copyWith({
    Value<int>? id,
    Value<int>? listId,
    Value<String>? body,
    Value<int>? position,
    Value<bool>? said,
    Value<String?>? recordingPath,
    Value<String?>? seedKey,
    Value<DateTime?>? spokenAt,
    Value<DateTime>? createdAt,
  }) {
    return SentencesCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      body: body ?? this.body,
      position: position ?? this.position,
      said: said ?? this.said,
      recordingPath: recordingPath ?? this.recordingPath,
      seedKey: seedKey ?? this.seedKey,
      spokenAt: spokenAt ?? this.spokenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (said.present) {
      map['said'] = Variable<bool>(said.value);
    }
    if (recordingPath.present) {
      map['recording_path'] = Variable<String>(recordingPath.value);
    }
    if (seedKey.present) {
      map['seed_key'] = Variable<String>(seedKey.value);
    }
    if (spokenAt.present) {
      map['spoken_at'] = Variable<DateTime>(spokenAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SentencesCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('body: $body, ')
          ..write('position: $position, ')
          ..write('said: $said, ')
          ..write('recordingPath: $recordingPath, ')
          ..write('seedKey: $seedKey, ')
          ..write('spokenAt: $spokenAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final String key;
  final String value;
  const AppMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetaData copyWith({String? key, String? value}) =>
      AppMetaData(key: key ?? this.key, value: value ?? this.value);
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SentenceListsTable sentenceLists = $SentenceListsTable(this);
  late final $SentencesTable sentences = $SentencesTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sentenceLists,
    sentences,
    appMeta,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sentence_lists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sentences', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SentenceListsTableCreateCompanionBuilder =
    SentenceListsCompanion Function({
      Value<int> id,
      required String title,
      required ListKind kind,
      Value<bool> pinned,
      required int position,
      Value<String?> seedKey,
      Value<String?> seedLanguage,
      Value<DateTime> createdAt,
    });
typedef $$SentenceListsTableUpdateCompanionBuilder =
    SentenceListsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<ListKind> kind,
      Value<bool> pinned,
      Value<int> position,
      Value<String?> seedKey,
      Value<String?> seedLanguage,
      Value<DateTime> createdAt,
    });

final class $$SentenceListsTableReferences
    extends BaseReferences<_$AppDatabase, $SentenceListsTable, SentenceList> {
  $$SentenceListsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SentencesTable, List<Sentence>>
  _sentencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sentences,
    aliasName: 'sentence_lists__id__sentences__list_id',
  );

  $$SentencesTableProcessedTableManager get sentencesRefs {
    final manager = $$SentencesTableTableManager(
      $_db,
      $_db.sentences,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sentencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SentenceListsTableFilterComposer
    extends Composer<_$AppDatabase, $SentenceListsTable> {
  $$SentenceListsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ListKind, ListKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seedKey => $composableBuilder(
    column: $table.seedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seedLanguage => $composableBuilder(
    column: $table.seedLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sentencesRefs(
    Expression<bool> Function($$SentencesTableFilterComposer f) f,
  ) {
    final $$SentencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableFilterComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SentenceListsTableOrderingComposer
    extends Composer<_$AppDatabase, $SentenceListsTable> {
  $$SentenceListsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seedKey => $composableBuilder(
    column: $table.seedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seedLanguage => $composableBuilder(
    column: $table.seedLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SentenceListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SentenceListsTable> {
  $$SentenceListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ListKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get seedKey =>
      $composableBuilder(column: $table.seedKey, builder: (column) => column);

  GeneratedColumn<String> get seedLanguage => $composableBuilder(
    column: $table.seedLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> sentencesRefs<T extends Object>(
    Expression<T> Function($$SentencesTableAnnotationComposer a) f,
  ) {
    final $$SentencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableAnnotationComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SentenceListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SentenceListsTable,
          SentenceList,
          $$SentenceListsTableFilterComposer,
          $$SentenceListsTableOrderingComposer,
          $$SentenceListsTableAnnotationComposer,
          $$SentenceListsTableCreateCompanionBuilder,
          $$SentenceListsTableUpdateCompanionBuilder,
          (SentenceList, $$SentenceListsTableReferences),
          SentenceList,
          PrefetchHooks Function({bool sentencesRefs})
        > {
  $$SentenceListsTableTableManager(_$AppDatabase db, $SentenceListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SentenceListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SentenceListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SentenceListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<ListKind> kind = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> seedKey = const Value.absent(),
                Value<String?> seedLanguage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SentenceListsCompanion(
                id: id,
                title: title,
                kind: kind,
                pinned: pinned,
                position: position,
                seedKey: seedKey,
                seedLanguage: seedLanguage,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required ListKind kind,
                Value<bool> pinned = const Value.absent(),
                required int position,
                Value<String?> seedKey = const Value.absent(),
                Value<String?> seedLanguage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SentenceListsCompanion.insert(
                id: id,
                title: title,
                kind: kind,
                pinned: pinned,
                position: position,
                seedKey: seedKey,
                seedLanguage: seedLanguage,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SentenceListsTable, SentenceList>(table),
                  $$SentenceListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sentencesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sentencesRefs) db.sentences],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sentencesRefs)
                    await $_getPrefetchedDataByColumns<
                      SentenceList,
                      $SentenceListsTable,
                      Sentence,
                      $SentencesTable
                    >(
                      currentTable: table,
                      referencedTable: $$SentenceListsTableReferences
                          ._sentencesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SentenceListsTableReferences(
                            db,
                            table,
                            p0,
                          ).sentencesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'list_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SentenceListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SentenceListsTable,
      SentenceList,
      $$SentenceListsTableFilterComposer,
      $$SentenceListsTableOrderingComposer,
      $$SentenceListsTableAnnotationComposer,
      $$SentenceListsTableCreateCompanionBuilder,
      $$SentenceListsTableUpdateCompanionBuilder,
      (SentenceList, $$SentenceListsTableReferences),
      SentenceList,
      PrefetchHooks Function({bool sentencesRefs})
    >;
typedef $$SentencesTableCreateCompanionBuilder = SentencesCompanion Function({
  Value<int> id,
  required int listId,
  required String body,
  required int position,
  Value<bool> said,
  Value<String?> recordingPath,
  Value<String?> seedKey,
  Value<DateTime?> spokenAt,
  Value<DateTime> createdAt,
});
typedef $$SentencesTableUpdateCompanionBuilder = SentencesCompanion Function({
  Value<int> id,
  Value<int> listId,
  Value<String> body,
  Value<int> position,
  Value<bool> said,
  Value<String?> recordingPath,
  Value<String?> seedKey,
  Value<DateTime?> spokenAt,
  Value<DateTime> createdAt,
});

final class $$SentencesTableReferences
    extends BaseReferences<_$AppDatabase, $SentencesTable, Sentence> {
  $$SentencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SentenceListsTable _listIdTable(_$AppDatabase db) =>
      db.sentenceLists.createAlias('sentences__list_id__sentence_lists__id');

  $$SentenceListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<int>('list_id')!;

    final manager = $$SentenceListsTableTableManager(
      $_db,
      $_db.sentenceLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SentencesTableFilterComposer
    extends Composer<_$AppDatabase, $SentencesTable> {
  $$SentencesTableFilterComposer({
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

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get said => $composableBuilder(
    column: $table.said,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordingPath => $composableBuilder(
    column: $table.recordingPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seedKey => $composableBuilder(
    column: $table.seedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get spokenAt => $composableBuilder(
    column: $table.spokenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SentenceListsTableFilterComposer get listId {
    final $$SentenceListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.sentenceLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentenceListsTableFilterComposer(
            $db: $db,
            $table: $db.sentenceLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencesTableOrderingComposer
    extends Composer<_$AppDatabase, $SentencesTable> {
  $$SentencesTableOrderingComposer({
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

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get said => $composableBuilder(
    column: $table.said,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordingPath => $composableBuilder(
    column: $table.recordingPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seedKey => $composableBuilder(
    column: $table.seedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get spokenAt => $composableBuilder(
    column: $table.spokenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SentenceListsTableOrderingComposer get listId {
    final $$SentenceListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.sentenceLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentenceListsTableOrderingComposer(
            $db: $db,
            $table: $db.sentenceLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SentencesTable> {
  $$SentencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get said =>
      $composableBuilder(column: $table.said, builder: (column) => column);

  GeneratedColumn<String> get recordingPath => $composableBuilder(
    column: $table.recordingPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seedKey =>
      $composableBuilder(column: $table.seedKey, builder: (column) => column);

  GeneratedColumn<DateTime> get spokenAt =>
      $composableBuilder(column: $table.spokenAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SentenceListsTableAnnotationComposer get listId {
    final $$SentenceListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.sentenceLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentenceListsTableAnnotationComposer(
            $db: $db,
            $table: $db.sentenceLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SentencesTable,
          Sentence,
          $$SentencesTableFilterComposer,
          $$SentencesTableOrderingComposer,
          $$SentencesTableAnnotationComposer,
          $$SentencesTableCreateCompanionBuilder,
          $$SentencesTableUpdateCompanionBuilder,
          (Sentence, $$SentencesTableReferences),
          Sentence,
          PrefetchHooks Function({bool listId})
        > {
  $$SentencesTableTableManager(_$AppDatabase db, $SentencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SentencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SentencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SentencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> listId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> said = const Value.absent(),
                Value<String?> recordingPath = const Value.absent(),
                Value<String?> seedKey = const Value.absent(),
                Value<DateTime?> spokenAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SentencesCompanion(
                id: id,
                listId: listId,
                body: body,
                position: position,
                said: said,
                recordingPath: recordingPath,
                seedKey: seedKey,
                spokenAt: spokenAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int listId,
                required String body,
                required int position,
                Value<bool> said = const Value.absent(),
                Value<String?> recordingPath = const Value.absent(),
                Value<String?> seedKey = const Value.absent(),
                Value<DateTime?> spokenAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SentencesCompanion.insert(
                id: id,
                listId: listId,
                body: body,
                position: position,
                said: said,
                recordingPath: recordingPath,
                seedKey: seedKey,
                spokenAt: spokenAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SentencesTable, Sentence>(table),
                  $$SentencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listId = false}) {
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
                    if (listId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.listId,
                        referencedTable: $$SentencesTableReferences
                            ._listIdTable(db),
                        referencedColumn: $$SentencesTableReferences
                            ._listIdTable(db)
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

typedef $$SentencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SentencesTable,
      Sentence,
      $$SentencesTableFilterComposer,
      $$SentencesTableOrderingComposer,
      $$SentencesTableAnnotationComposer,
      $$SentencesTableCreateCompanionBuilder,
      $$SentencesTableUpdateCompanionBuilder,
      (Sentence, $$SentencesTableReferences),
      Sentence,
      PrefetchHooks Function({bool listId})
    >;
typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaData,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaData,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>,
          ),
          AppMetaData,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppMetaTable, AppMetaData>(table),
                  BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaData,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
      AppMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SentenceListsTableTableManager get sentenceLists =>
      $$SentenceListsTableTableManager(_db, _db.sentenceLists);
  $$SentencesTableTableManager get sentences =>
      $$SentencesTableTableManager(_db, _db.sentences);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
