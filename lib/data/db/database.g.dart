// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $HouseholdTable extends Household
    with TableInfo<$HouseholdTable, HouseholdRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'household';
  @override
  VerificationContext validateIntegrity(
    Insertable<HouseholdRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HouseholdRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HouseholdRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $HouseholdTable createAlias(String alias) {
    return $HouseholdTable(attachedDatabase, alias);
  }
}

class HouseholdRow extends DataClass implements Insertable<HouseholdRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final int schemaVersion;
  const HouseholdRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  HouseholdCompanion toCompanion(bool nullToAbsent) {
    return HouseholdCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory HouseholdRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HouseholdRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  HouseholdRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    int? schemaVersion,
  }) => HouseholdRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  HouseholdRow copyWithCompanion(HouseholdCompanion data) {
    return HouseholdRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.schemaVersion == this.schemaVersion);
}

class HouseholdCompanion extends UpdateCompanion<HouseholdRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const HouseholdCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       schemaVersion = Value(schemaVersion);
  static Insertable<HouseholdRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return HouseholdCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialBalanceMeta = const VerificationMeta(
    'initialBalance',
  );
  @override
  late final GeneratedColumn<int> initialBalance = GeneratedColumn<int>(
    'initial_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialDateMeta = const VerificationMeta(
    'initialDate',
  );
  @override
  late final GeneratedColumn<String> initialDate = GeneratedColumn<String>(
    'initial_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    name,
    kind,
    initialBalance,
    initialDate,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
        _initialBalanceMeta,
        initialBalance.isAcceptableOrUnknown(
          data['initial_balance']!,
          _initialBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialBalanceMeta);
    }
    if (data.containsKey('initial_date')) {
      context.handle(
        _initialDateMeta,
        initialDate.isAcceptableOrUnknown(
          data['initial_date']!,
          _initialDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialDateMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      initialBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_balance'],
      )!,
      initialDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initial_date'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String name;

  /// cash / bank / securities / other
  final String kind;
  final int initialBalance;
  final String initialDate;
  final int sortOrder;
  const AccountRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.name,
    required this.kind,
    required this.initialBalance,
    required this.initialDate,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['initial_balance'] = Variable<int>(initialBalance);
    map['initial_date'] = Variable<String>(initialDate);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      kind: Value(kind),
      initialBalance: Value(initialBalance),
      initialDate: Value(initialDate),
      sortOrder: Value(sortOrder),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      initialBalance: serializer.fromJson<int>(json['initialBalance']),
      initialDate: serializer.fromJson<String>(json['initialDate']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'initialBalance': serializer.toJson<int>(initialBalance),
      'initialDate': serializer.toJson<String>(initialDate),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AccountRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? name,
    String? kind,
    int? initialBalance,
    String? initialDate,
    int? sortOrder,
  }) => AccountRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    initialBalance: initialBalance ?? this.initialBalance,
    initialDate: initialDate ?? this.initialDate,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      initialDate: data.initialDate.present
          ? data.initialDate.value
          : this.initialDate,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('initialDate: $initialDate, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    name,
    kind,
    initialBalance,
    initialDate,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.initialBalance == this.initialBalance &&
          other.initialDate == this.initialDate &&
          other.sortOrder == this.sortOrder);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> name;
  final Value<String> kind;
  final Value<int> initialBalance;
  final Value<String> initialDate;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.initialDate = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String name,
    required String kind,
    required int initialBalance,
    required String initialDate,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       name = Value(name),
       kind = Value(kind),
       initialBalance = Value(initialBalance),
       initialDate = Value(initialDate),
       sortOrder = Value(sortOrder);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? initialBalance,
    Expression<String>? initialDate,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (initialDate != null) 'initial_date': initialDate,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? name,
    Value<String>? kind,
    Value<int>? initialBalance,
    Value<String>? initialDate,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      initialBalance: initialBalance ?? this.initialBalance,
      initialDate: initialDate ?? this.initialDate,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<int>(initialBalance.value);
    }
    if (initialDate.present) {
      map['initial_date'] = Variable<String>(initialDate.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('initialDate: $initialDate, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultValuationMeta = const VerificationMeta(
    'defaultValuation',
  );
  @override
  late final GeneratedColumn<String> defaultValuation = GeneratedColumn<String>(
    'default_valuation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _saleTaxDefaultMeta = const VerificationMeta(
    'saleTaxDefault',
  );
  @override
  late final GeneratedColumn<int> saleTaxDefault = GeneratedColumn<int>(
    'sale_tax_default',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    name,
    kind,
    color,
    defaultValuation,
    saleTaxDefault,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('default_valuation')) {
      context.handle(
        _defaultValuationMeta,
        defaultValuation.isAcceptableOrUnknown(
          data['default_valuation']!,
          _defaultValuationMeta,
        ),
      );
    }
    if (data.containsKey('sale_tax_default')) {
      context.handle(
        _saleTaxDefaultMeta,
        saleTaxDefault.isAcceptableOrUnknown(
          data['sale_tax_default']!,
          _saleTaxDefaultMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      defaultValuation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_valuation'],
      ),
      saleTaxDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sale_tax_default'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String name;

  /// income / expense / asset
  final String kind;
  final String color;

  /// asset のみ。quantity / value
  final String? defaultValuation;

  /// asset のみ。1 なら売却時に税額の初期値を出す
  final int? saleTaxDefault;
  final int sortOrder;
  const CategoryRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.name,
    required this.kind,
    required this.color,
    this.defaultValuation,
    this.saleTaxDefault,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['color'] = Variable<String>(color);
    if (!nullToAbsent || defaultValuation != null) {
      map['default_valuation'] = Variable<String>(defaultValuation);
    }
    if (!nullToAbsent || saleTaxDefault != null) {
      map['sale_tax_default'] = Variable<int>(saleTaxDefault);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      kind: Value(kind),
      color: Value(color),
      defaultValuation: defaultValuation == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultValuation),
      saleTaxDefault: saleTaxDefault == null && nullToAbsent
          ? const Value.absent()
          : Value(saleTaxDefault),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      color: serializer.fromJson<String>(json['color']),
      defaultValuation: serializer.fromJson<String?>(json['defaultValuation']),
      saleTaxDefault: serializer.fromJson<int?>(json['saleTaxDefault']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'color': serializer.toJson<String>(color),
      'defaultValuation': serializer.toJson<String?>(defaultValuation),
      'saleTaxDefault': serializer.toJson<int?>(saleTaxDefault),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? name,
    String? kind,
    String? color,
    Value<String?> defaultValuation = const Value.absent(),
    Value<int?> saleTaxDefault = const Value.absent(),
    int? sortOrder,
  }) => CategoryRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    color: color ?? this.color,
    defaultValuation: defaultValuation.present
        ? defaultValuation.value
        : this.defaultValuation,
    saleTaxDefault: saleTaxDefault.present
        ? saleTaxDefault.value
        : this.saleTaxDefault,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      color: data.color.present ? data.color.value : this.color,
      defaultValuation: data.defaultValuation.present
          ? data.defaultValuation.value
          : this.defaultValuation,
      saleTaxDefault: data.saleTaxDefault.present
          ? data.saleTaxDefault.value
          : this.saleTaxDefault,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('color: $color, ')
          ..write('defaultValuation: $defaultValuation, ')
          ..write('saleTaxDefault: $saleTaxDefault, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    name,
    kind,
    color,
    defaultValuation,
    saleTaxDefault,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.color == this.color &&
          other.defaultValuation == this.defaultValuation &&
          other.saleTaxDefault == this.saleTaxDefault &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> color;
  final Value<String?> defaultValuation;
  final Value<int?> saleTaxDefault;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.color = const Value.absent(),
    this.defaultValuation = const Value.absent(),
    this.saleTaxDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String name,
    required String kind,
    required String color,
    this.defaultValuation = const Value.absent(),
    this.saleTaxDefault = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       name = Value(name),
       kind = Value(kind),
       color = Value(color),
       sortOrder = Value(sortOrder);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? color,
    Expression<String>? defaultValuation,
    Expression<int>? saleTaxDefault,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (color != null) 'color': color,
      if (defaultValuation != null) 'default_valuation': defaultValuation,
      if (saleTaxDefault != null) 'sale_tax_default': saleTaxDefault,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? color,
    Value<String?>? defaultValuation,
    Value<int?>? saleTaxDefault,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      color: color ?? this.color,
      defaultValuation: defaultValuation ?? this.defaultValuation,
      saleTaxDefault: saleTaxDefault ?? this.saleTaxDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (defaultValuation.present) {
      map['default_valuation'] = Variable<String>(defaultValuation.value);
    }
    if (saleTaxDefault.present) {
      map['sale_tax_default'] = Variable<int>(saleTaxDefault.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('color: $color, ')
          ..write('defaultValuation: $defaultValuation, ')
          ..write('saleTaxDefault: $saleTaxDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TxnsTable extends Txns with TableInfo<$TxnsTable, TxnRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TxnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetActionMeta = const VerificationMeta(
    'assetAction',
  );
  @override
  late final GeneratedColumn<String> assetAction = GeneratedColumn<String>(
    'asset_action',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityX1e4Meta = const VerificationMeta(
    'quantityX1e4',
  );
  @override
  late final GeneratedColumn<int> quantityX1e4 = GeneratedColumn<int>(
    'quantity_x1e4',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentTxnIdMeta = const VerificationMeta(
    'parentTxnId',
  );
  @override
  late final GeneratedColumn<String> parentTxnId = GeneratedColumn<String>(
    'parent_txn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupItemIdMeta = const VerificationMeta(
    'groupItemId',
  );
  @override
  late final GeneratedColumn<String> groupItemId = GeneratedColumn<String>(
    'group_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    date,
    kind,
    amount,
    categoryId,
    accountId,
    toAccountId,
    assetId,
    assetAction,
    quantityX1e4,
    eventId,
    parentTxnId,
    memo,
    groupId,
    groupItemId,
    entryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'txn';
  @override
  VerificationContext validateIntegrity(
    Insertable<TxnRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    if (data.containsKey('asset_action')) {
      context.handle(
        _assetActionMeta,
        assetAction.isAcceptableOrUnknown(
          data['asset_action']!,
          _assetActionMeta,
        ),
      );
    }
    if (data.containsKey('quantity_x1e4')) {
      context.handle(
        _quantityX1e4Meta,
        quantityX1e4.isAcceptableOrUnknown(
          data['quantity_x1e4']!,
          _quantityX1e4Meta,
        ),
      );
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    }
    if (data.containsKey('parent_txn_id')) {
      context.handle(
        _parentTxnIdMeta,
        parentTxnId.isAcceptableOrUnknown(
          data['parent_txn_id']!,
          _parentTxnIdMeta,
        ),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('group_item_id')) {
      context.handle(
        _groupItemIdMeta,
        groupItemId.isAcceptableOrUnknown(
          data['group_item_id']!,
          _groupItemIdMeta,
        ),
      );
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TxnRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TxnRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      ),
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      ),
      assetAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_action'],
      ),
      quantityX1e4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_x1e4'],
      ),
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      ),
      parentTxnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_txn_id'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      groupItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_item_id'],
      ),
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      ),
    );
  }

  @override
  $TxnsTable createAlias(String alias) {
    return $TxnsTable(attachedDatabase, alias);
  }
}

class TxnRow extends DataClass implements Insertable<TxnRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String planId;
  final String date;

  /// income / expense / transfer
  final String kind;
  final int amount;
  final String? categoryId;
  final String accountId;
  final String? toAccountId;
  final String? assetId;

  /// buy / sell / income / cost
  final String? assetAction;
  final int? quantityX1e4;
  final String? eventId;
  final String? parentTxnId;
  final String? memo;
  final String? groupId;
  final String? groupItemId;
  final String? entryId;
  const TxnRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.planId,
    required this.date,
    required this.kind,
    required this.amount,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.assetId,
    this.assetAction,
    this.quantityX1e4,
    this.eventId,
    this.parentTxnId,
    this.memo,
    this.groupId,
    this.groupItemId,
    this.entryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['plan_id'] = Variable<String>(planId);
    map['date'] = Variable<String>(date);
    map['kind'] = Variable<String>(kind);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<String>(assetId);
    }
    if (!nullToAbsent || assetAction != null) {
      map['asset_action'] = Variable<String>(assetAction);
    }
    if (!nullToAbsent || quantityX1e4 != null) {
      map['quantity_x1e4'] = Variable<int>(quantityX1e4);
    }
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    if (!nullToAbsent || parentTxnId != null) {
      map['parent_txn_id'] = Variable<String>(parentTxnId);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || groupItemId != null) {
      map['group_item_id'] = Variable<String>(groupItemId);
    }
    if (!nullToAbsent || entryId != null) {
      map['entry_id'] = Variable<String>(entryId);
    }
    return map;
  }

  TxnsCompanion toCompanion(bool nullToAbsent) {
    return TxnsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      planId: Value(planId),
      date: Value(date),
      kind: Value(kind),
      amount: Value(amount),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      assetAction: assetAction == null && nullToAbsent
          ? const Value.absent()
          : Value(assetAction),
      quantityX1e4: quantityX1e4 == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityX1e4),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
      parentTxnId: parentTxnId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentTxnId),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      groupItemId: groupItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupItemId),
      entryId: entryId == null && nullToAbsent
          ? const Value.absent()
          : Value(entryId),
    );
  }

  factory TxnRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TxnRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      planId: serializer.fromJson<String>(json['planId']),
      date: serializer.fromJson<String>(json['date']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<int>(json['amount']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      assetId: serializer.fromJson<String?>(json['assetId']),
      assetAction: serializer.fromJson<String?>(json['assetAction']),
      quantityX1e4: serializer.fromJson<int?>(json['quantityX1e4']),
      eventId: serializer.fromJson<String?>(json['eventId']),
      parentTxnId: serializer.fromJson<String?>(json['parentTxnId']),
      memo: serializer.fromJson<String?>(json['memo']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      groupItemId: serializer.fromJson<String?>(json['groupItemId']),
      entryId: serializer.fromJson<String?>(json['entryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'planId': serializer.toJson<String>(planId),
      'date': serializer.toJson<String>(date),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<int>(amount),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String>(accountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'assetId': serializer.toJson<String?>(assetId),
      'assetAction': serializer.toJson<String?>(assetAction),
      'quantityX1e4': serializer.toJson<int?>(quantityX1e4),
      'eventId': serializer.toJson<String?>(eventId),
      'parentTxnId': serializer.toJson<String?>(parentTxnId),
      'memo': serializer.toJson<String?>(memo),
      'groupId': serializer.toJson<String?>(groupId),
      'groupItemId': serializer.toJson<String?>(groupItemId),
      'entryId': serializer.toJson<String?>(entryId),
    };
  }

  TxnRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? planId,
    String? date,
    String? kind,
    int? amount,
    Value<String?> categoryId = const Value.absent(),
    String? accountId,
    Value<String?> toAccountId = const Value.absent(),
    Value<String?> assetId = const Value.absent(),
    Value<String?> assetAction = const Value.absent(),
    Value<int?> quantityX1e4 = const Value.absent(),
    Value<String?> eventId = const Value.absent(),
    Value<String?> parentTxnId = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    Value<String?> groupItemId = const Value.absent(),
    Value<String?> entryId = const Value.absent(),
  }) => TxnRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    planId: planId ?? this.planId,
    date: date ?? this.date,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    assetId: assetId.present ? assetId.value : this.assetId,
    assetAction: assetAction.present ? assetAction.value : this.assetAction,
    quantityX1e4: quantityX1e4.present ? quantityX1e4.value : this.quantityX1e4,
    eventId: eventId.present ? eventId.value : this.eventId,
    parentTxnId: parentTxnId.present ? parentTxnId.value : this.parentTxnId,
    memo: memo.present ? memo.value : this.memo,
    groupId: groupId.present ? groupId.value : this.groupId,
    groupItemId: groupItemId.present ? groupItemId.value : this.groupItemId,
    entryId: entryId.present ? entryId.value : this.entryId,
  );
  TxnRow copyWithCompanion(TxnsCompanion data) {
    return TxnRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      planId: data.planId.present ? data.planId.value : this.planId,
      date: data.date.present ? data.date.value : this.date,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      assetAction: data.assetAction.present
          ? data.assetAction.value
          : this.assetAction,
      quantityX1e4: data.quantityX1e4.present
          ? data.quantityX1e4.value
          : this.quantityX1e4,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      parentTxnId: data.parentTxnId.present
          ? data.parentTxnId.value
          : this.parentTxnId,
      memo: data.memo.present ? data.memo.value : this.memo,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      groupItemId: data.groupItemId.present
          ? data.groupItemId.value
          : this.groupItemId,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TxnRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('assetId: $assetId, ')
          ..write('assetAction: $assetAction, ')
          ..write('quantityX1e4: $quantityX1e4, ')
          ..write('eventId: $eventId, ')
          ..write('parentTxnId: $parentTxnId, ')
          ..write('memo: $memo, ')
          ..write('groupId: $groupId, ')
          ..write('groupItemId: $groupItemId, ')
          ..write('entryId: $entryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    date,
    kind,
    amount,
    categoryId,
    accountId,
    toAccountId,
    assetId,
    assetAction,
    quantityX1e4,
    eventId,
    parentTxnId,
    memo,
    groupId,
    groupItemId,
    entryId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TxnRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.planId == this.planId &&
          other.date == this.date &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.assetId == this.assetId &&
          other.assetAction == this.assetAction &&
          other.quantityX1e4 == this.quantityX1e4 &&
          other.eventId == this.eventId &&
          other.parentTxnId == this.parentTxnId &&
          other.memo == this.memo &&
          other.groupId == this.groupId &&
          other.groupItemId == this.groupItemId &&
          other.entryId == this.entryId);
}

class TxnsCompanion extends UpdateCompanion<TxnRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> planId;
  final Value<String> date;
  final Value<String> kind;
  final Value<int> amount;
  final Value<String?> categoryId;
  final Value<String> accountId;
  final Value<String?> toAccountId;
  final Value<String?> assetId;
  final Value<String?> assetAction;
  final Value<int?> quantityX1e4;
  final Value<String?> eventId;
  final Value<String?> parentTxnId;
  final Value<String?> memo;
  final Value<String?> groupId;
  final Value<String?> groupItemId;
  final Value<String?> entryId;
  final Value<int> rowid;
  const TxnsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.planId = const Value.absent(),
    this.date = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetAction = const Value.absent(),
    this.quantityX1e4 = const Value.absent(),
    this.eventId = const Value.absent(),
    this.parentTxnId = const Value.absent(),
    this.memo = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupItemId = const Value.absent(),
    this.entryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TxnsCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String planId,
    required String date,
    required String kind,
    required int amount,
    this.categoryId = const Value.absent(),
    required String accountId,
    this.toAccountId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetAction = const Value.absent(),
    this.quantityX1e4 = const Value.absent(),
    this.eventId = const Value.absent(),
    this.parentTxnId = const Value.absent(),
    this.memo = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupItemId = const Value.absent(),
    this.entryId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       planId = Value(planId),
       date = Value(date),
       kind = Value(kind),
       amount = Value(amount),
       accountId = Value(accountId);
  static Insertable<TxnRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? planId,
    Expression<String>? date,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<String>? toAccountId,
    Expression<String>? assetId,
    Expression<String>? assetAction,
    Expression<int>? quantityX1e4,
    Expression<String>? eventId,
    Expression<String>? parentTxnId,
    Expression<String>? memo,
    Expression<String>? groupId,
    Expression<String>? groupItemId,
    Expression<String>? entryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (planId != null) 'plan_id': planId,
      if (date != null) 'date': date,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (assetId != null) 'asset_id': assetId,
      if (assetAction != null) 'asset_action': assetAction,
      if (quantityX1e4 != null) 'quantity_x1e4': quantityX1e4,
      if (eventId != null) 'event_id': eventId,
      if (parentTxnId != null) 'parent_txn_id': parentTxnId,
      if (memo != null) 'memo': memo,
      if (groupId != null) 'group_id': groupId,
      if (groupItemId != null) 'group_item_id': groupItemId,
      if (entryId != null) 'entry_id': entryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TxnsCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? planId,
    Value<String>? date,
    Value<String>? kind,
    Value<int>? amount,
    Value<String?>? categoryId,
    Value<String>? accountId,
    Value<String?>? toAccountId,
    Value<String?>? assetId,
    Value<String?>? assetAction,
    Value<int?>? quantityX1e4,
    Value<String?>? eventId,
    Value<String?>? parentTxnId,
    Value<String?>? memo,
    Value<String?>? groupId,
    Value<String?>? groupItemId,
    Value<String?>? entryId,
    Value<int>? rowid,
  }) {
    return TxnsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      planId: planId ?? this.planId,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      assetId: assetId ?? this.assetId,
      assetAction: assetAction ?? this.assetAction,
      quantityX1e4: quantityX1e4 ?? this.quantityX1e4,
      eventId: eventId ?? this.eventId,
      parentTxnId: parentTxnId ?? this.parentTxnId,
      memo: memo ?? this.memo,
      groupId: groupId ?? this.groupId,
      groupItemId: groupItemId ?? this.groupItemId,
      entryId: entryId ?? this.entryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (assetAction.present) {
      map['asset_action'] = Variable<String>(assetAction.value);
    }
    if (quantityX1e4.present) {
      map['quantity_x1e4'] = Variable<int>(quantityX1e4.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (parentTxnId.present) {
      map['parent_txn_id'] = Variable<String>(parentTxnId.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (groupItemId.present) {
      map['group_item_id'] = Variable<String>(groupItemId.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TxnsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('assetId: $assetId, ')
          ..write('assetAction: $assetAction, ')
          ..write('quantityX1e4: $quantityX1e4, ')
          ..write('eventId: $eventId, ')
          ..write('parentTxnId: $parentTxnId, ')
          ..write('memo: $memo, ')
          ..write('groupId: $groupId, ')
          ..write('groupItemId: $groupItemId, ')
          ..write('entryId: $entryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetsTable extends Assets with TableInfo<$AssetsTable, AssetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valuationMeta = const VerificationMeta(
    'valuation',
  );
  @override
  late final GeneratedColumn<String> valuation = GeneratedColumn<String>(
    'valuation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    name,
    categoryId,
    valuation,
    code,
    accountId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('valuation')) {
      context.handle(
        _valuationMeta,
        valuation.isAcceptableOrUnknown(data['valuation']!, _valuationMeta),
      );
    } else if (isInserting) {
      context.missing(_valuationMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      valuation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valuation'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }
}

class AssetRow extends DataClass implements Insertable<AssetRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String planId;
  final String name;
  final String categoryId;

  /// quantity / value
  final String valuation;
  final String? code;
  final String? accountId;
  final int sortOrder;
  const AssetRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.planId,
    required this.name,
    required this.categoryId,
    required this.valuation,
    this.code,
    this.accountId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['plan_id'] = Variable<String>(planId);
    map['name'] = Variable<String>(name);
    map['category_id'] = Variable<String>(categoryId);
    map['valuation'] = Variable<String>(valuation);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      planId: Value(planId),
      name: Value(name),
      categoryId: Value(categoryId),
      valuation: Value(valuation),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      sortOrder: Value(sortOrder),
    );
  }

  factory AssetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      planId: serializer.fromJson<String>(json['planId']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      valuation: serializer.fromJson<String>(json['valuation']),
      code: serializer.fromJson<String?>(json['code']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'planId': serializer.toJson<String>(planId),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<String>(categoryId),
      'valuation': serializer.toJson<String>(valuation),
      'code': serializer.toJson<String?>(code),
      'accountId': serializer.toJson<String?>(accountId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AssetRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? planId,
    String? name,
    String? categoryId,
    String? valuation,
    Value<String?> code = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    int? sortOrder,
  }) => AssetRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    planId: planId ?? this.planId,
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    valuation: valuation ?? this.valuation,
    code: code.present ? code.value : this.code,
    accountId: accountId.present ? accountId.value : this.accountId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AssetRow copyWithCompanion(AssetsCompanion data) {
    return AssetRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      planId: data.planId.present ? data.planId.value : this.planId,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      valuation: data.valuation.present ? data.valuation.value : this.valuation,
      code: data.code.present ? data.code.value : this.code,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('valuation: $valuation, ')
          ..write('code: $code, ')
          ..write('accountId: $accountId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    name,
    categoryId,
    valuation,
    code,
    accountId,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.planId == this.planId &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.valuation == this.valuation &&
          other.code == this.code &&
          other.accountId == this.accountId &&
          other.sortOrder == this.sortOrder);
}

class AssetsCompanion extends UpdateCompanion<AssetRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> planId;
  final Value<String> name;
  final Value<String> categoryId;
  final Value<String> valuation;
  final Value<String?> code;
  final Value<String?> accountId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.planId = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.valuation = const Value.absent(),
    this.code = const Value.absent(),
    this.accountId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String planId,
    required String name,
    required String categoryId,
    required String valuation,
    this.code = const Value.absent(),
    this.accountId = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       planId = Value(planId),
       name = Value(name),
       categoryId = Value(categoryId),
       valuation = Value(valuation),
       sortOrder = Value(sortOrder);
  static Insertable<AssetRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? planId,
    Expression<String>? name,
    Expression<String>? categoryId,
    Expression<String>? valuation,
    Expression<String>? code,
    Expression<String>? accountId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (planId != null) 'plan_id': planId,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (valuation != null) 'valuation': valuation,
      if (code != null) 'code': code,
      if (accountId != null) 'account_id': accountId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? planId,
    Value<String>? name,
    Value<String>? categoryId,
    Value<String>? valuation,
    Value<String?>? code,
    Value<String?>? accountId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      valuation: valuation ?? this.valuation,
      code: code ?? this.code,
      accountId: accountId ?? this.accountId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (valuation.present) {
      map['valuation'] = Variable<String>(valuation.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('valuation: $valuation, ')
          ..write('code: $code, ')
          ..write('accountId: $accountId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetValuesTable extends AssetValues
    with TableInfo<$AssetValuesTable, AssetValueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueDateMeta = const VerificationMeta(
    'valueDate',
  );
  @override
  late final GeneratedColumn<String> valueDate = GeneratedColumn<String>(
    'value_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueX100Meta = const VerificationMeta(
    'valueX100',
  );
  @override
  late final GeneratedColumn<int> valueX100 = GeneratedColumn<int>(
    'value_x100',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    assetId,
    unit,
    valueDate,
    valueX100,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_value';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetValueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('value_date')) {
      context.handle(
        _valueDateMeta,
        valueDate.isAcceptableOrUnknown(data['value_date']!, _valueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_valueDateMeta);
    }
    if (data.containsKey('value_x100')) {
      context.handle(
        _valueX100Meta,
        valueX100.isAcceptableOrUnknown(data['value_x100']!, _valueX100Meta),
      );
    } else if (isInserting) {
      context.missing(_valueX100Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetValueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetValueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      valueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_date'],
      )!,
      valueX100: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value_x100'],
      )!,
    );
  }

  @override
  $AssetValuesTable createAlias(String alias) {
    return $AssetValuesTable(attachedDatabase, alias);
  }
}

class AssetValueRow extends DataClass implements Insertable<AssetValueRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String assetId;

  /// day / month
  final String unit;
  final String valueDate;
  final int valueX100;
  const AssetValueRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.assetId,
    required this.unit,
    required this.valueDate,
    required this.valueX100,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['asset_id'] = Variable<String>(assetId);
    map['unit'] = Variable<String>(unit);
    map['value_date'] = Variable<String>(valueDate);
    map['value_x100'] = Variable<int>(valueX100);
    return map;
  }

  AssetValuesCompanion toCompanion(bool nullToAbsent) {
    return AssetValuesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      assetId: Value(assetId),
      unit: Value(unit),
      valueDate: Value(valueDate),
      valueX100: Value(valueX100),
    );
  }

  factory AssetValueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetValueRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      assetId: serializer.fromJson<String>(json['assetId']),
      unit: serializer.fromJson<String>(json['unit']),
      valueDate: serializer.fromJson<String>(json['valueDate']),
      valueX100: serializer.fromJson<int>(json['valueX100']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'assetId': serializer.toJson<String>(assetId),
      'unit': serializer.toJson<String>(unit),
      'valueDate': serializer.toJson<String>(valueDate),
      'valueX100': serializer.toJson<int>(valueX100),
    };
  }

  AssetValueRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? assetId,
    String? unit,
    String? valueDate,
    int? valueX100,
  }) => AssetValueRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    assetId: assetId ?? this.assetId,
    unit: unit ?? this.unit,
    valueDate: valueDate ?? this.valueDate,
    valueX100: valueX100 ?? this.valueX100,
  );
  AssetValueRow copyWithCompanion(AssetValuesCompanion data) {
    return AssetValueRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      unit: data.unit.present ? data.unit.value : this.unit,
      valueDate: data.valueDate.present ? data.valueDate.value : this.valueDate,
      valueX100: data.valueX100.present ? data.valueX100.value : this.valueX100,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetValueRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('assetId: $assetId, ')
          ..write('unit: $unit, ')
          ..write('valueDate: $valueDate, ')
          ..write('valueX100: $valueX100')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    assetId,
    unit,
    valueDate,
    valueX100,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetValueRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.assetId == this.assetId &&
          other.unit == this.unit &&
          other.valueDate == this.valueDate &&
          other.valueX100 == this.valueX100);
}

class AssetValuesCompanion extends UpdateCompanion<AssetValueRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> assetId;
  final Value<String> unit;
  final Value<String> valueDate;
  final Value<int> valueX100;
  final Value<int> rowid;
  const AssetValuesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.assetId = const Value.absent(),
    this.unit = const Value.absent(),
    this.valueDate = const Value.absent(),
    this.valueX100 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetValuesCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String assetId,
    required String unit,
    required String valueDate,
    required int valueX100,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       assetId = Value(assetId),
       unit = Value(unit),
       valueDate = Value(valueDate),
       valueX100 = Value(valueX100);
  static Insertable<AssetValueRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? assetId,
    Expression<String>? unit,
    Expression<String>? valueDate,
    Expression<int>? valueX100,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (assetId != null) 'asset_id': assetId,
      if (unit != null) 'unit': unit,
      if (valueDate != null) 'value_date': valueDate,
      if (valueX100 != null) 'value_x100': valueX100,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetValuesCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? assetId,
    Value<String>? unit,
    Value<String>? valueDate,
    Value<int>? valueX100,
    Value<int>? rowid,
  }) {
    return AssetValuesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      assetId: assetId ?? this.assetId,
      unit: unit ?? this.unit,
      valueDate: valueDate ?? this.valueDate,
      valueX100: valueX100 ?? this.valueX100,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (valueDate.present) {
      map['value_date'] = Variable<String>(valueDate.value);
    }
    if (valueX100.present) {
      map['value_x100'] = Variable<int>(valueX100.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetValuesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('assetId: $assetId, ')
          ..write('unit: $unit, ')
          ..write('valueDate: $valueDate, ')
          ..write('valueX100: $valueX100, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, TemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityX1e4Meta = const VerificationMeta(
    'quantityX1e4',
  );
  @override
  late final GeneratedColumn<int> quantityX1e4 = GeneratedColumn<int>(
    'quantity_x1e4',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetActionMeta = const VerificationMeta(
    'assetAction',
  );
  @override
  late final GeneratedColumn<String> assetAction = GeneratedColumn<String>(
    'asset_action',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _growthModeMeta = const VerificationMeta(
    'growthMode',
  );
  @override
  late final GeneratedColumn<String> growthMode = GeneratedColumn<String>(
    'growth_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _growthRateMeta = const VerificationMeta(
    'growthRate',
  );
  @override
  late final GeneratedColumn<double> growthRate = GeneratedColumn<double>(
    'growth_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    name,
    kind,
    amount,
    quantityX1e4,
    categoryId,
    accountId,
    toAccountId,
    assetId,
    assetAction,
    memo,
    growthMode,
    growthRate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('quantity_x1e4')) {
      context.handle(
        _quantityX1e4Meta,
        quantityX1e4.isAcceptableOrUnknown(
          data['quantity_x1e4']!,
          _quantityX1e4Meta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    if (data.containsKey('asset_action')) {
      context.handle(
        _assetActionMeta,
        assetAction.isAcceptableOrUnknown(
          data['asset_action']!,
          _assetActionMeta,
        ),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('growth_mode')) {
      context.handle(
        _growthModeMeta,
        growthMode.isAcceptableOrUnknown(data['growth_mode']!, _growthModeMeta),
      );
    } else if (isInserting) {
      context.missing(_growthModeMeta);
    }
    if (data.containsKey('growth_rate')) {
      context.handle(
        _growthRateMeta,
        growthRate.isAcceptableOrUnknown(data['growth_rate']!, _growthRateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      ),
      quantityX1e4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_x1e4'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      ),
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      ),
      assetAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_action'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      growthMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}growth_mode'],
      )!,
      growthRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}growth_rate'],
      ),
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class TemplateRow extends DataClass implements Insertable<TemplateRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String name;
  final String kind;
  final int? amount;
  final int? quantityX1e4;
  final String? categoryId;

  /// 口座を「履歴ごと削除」したときだけ空になる（設計書 3.7）
  final String? accountId;
  final String? toAccountId;
  final String? assetId;
  final String? assetAction;
  final String? memo;

  /// category / template / none
  final String growthMode;
  final double? growthRate;
  const TemplateRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.name,
    required this.kind,
    this.amount,
    this.quantityX1e4,
    this.categoryId,
    this.accountId,
    this.toAccountId,
    this.assetId,
    this.assetAction,
    this.memo,
    required this.growthMode,
    this.growthRate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<int>(amount);
    }
    if (!nullToAbsent || quantityX1e4 != null) {
      map['quantity_x1e4'] = Variable<int>(quantityX1e4);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<String>(assetId);
    }
    if (!nullToAbsent || assetAction != null) {
      map['asset_action'] = Variable<String>(assetAction);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['growth_mode'] = Variable<String>(growthMode);
    if (!nullToAbsent || growthRate != null) {
      map['growth_rate'] = Variable<double>(growthRate);
    }
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      kind: Value(kind),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      quantityX1e4: quantityX1e4 == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityX1e4),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      assetAction: assetAction == null && nullToAbsent
          ? const Value.absent()
          : Value(assetAction),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      growthMode: Value(growthMode),
      growthRate: growthRate == null && nullToAbsent
          ? const Value.absent()
          : Value(growthRate),
    );
  }

  factory TemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<int?>(json['amount']),
      quantityX1e4: serializer.fromJson<int?>(json['quantityX1e4']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      assetId: serializer.fromJson<String?>(json['assetId']),
      assetAction: serializer.fromJson<String?>(json['assetAction']),
      memo: serializer.fromJson<String?>(json['memo']),
      growthMode: serializer.fromJson<String>(json['growthMode']),
      growthRate: serializer.fromJson<double?>(json['growthRate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<int?>(amount),
      'quantityX1e4': serializer.toJson<int?>(quantityX1e4),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String?>(accountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'assetId': serializer.toJson<String?>(assetId),
      'assetAction': serializer.toJson<String?>(assetAction),
      'memo': serializer.toJson<String?>(memo),
      'growthMode': serializer.toJson<String>(growthMode),
      'growthRate': serializer.toJson<double?>(growthRate),
    };
  }

  TemplateRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? name,
    String? kind,
    Value<int?> amount = const Value.absent(),
    Value<int?> quantityX1e4 = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> toAccountId = const Value.absent(),
    Value<String?> assetId = const Value.absent(),
    Value<String?> assetAction = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    String? growthMode,
    Value<double?> growthRate = const Value.absent(),
  }) => TemplateRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    amount: amount.present ? amount.value : this.amount,
    quantityX1e4: quantityX1e4.present ? quantityX1e4.value : this.quantityX1e4,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId.present ? accountId.value : this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    assetId: assetId.present ? assetId.value : this.assetId,
    assetAction: assetAction.present ? assetAction.value : this.assetAction,
    memo: memo.present ? memo.value : this.memo,
    growthMode: growthMode ?? this.growthMode,
    growthRate: growthRate.present ? growthRate.value : this.growthRate,
  );
  TemplateRow copyWithCompanion(TemplatesCompanion data) {
    return TemplateRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      quantityX1e4: data.quantityX1e4.present
          ? data.quantityX1e4.value
          : this.quantityX1e4,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      assetAction: data.assetAction.present
          ? data.assetAction.value
          : this.assetAction,
      memo: data.memo.present ? data.memo.value : this.memo,
      growthMode: data.growthMode.present
          ? data.growthMode.value
          : this.growthMode,
      growthRate: data.growthRate.present
          ? data.growthRate.value
          : this.growthRate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('quantityX1e4: $quantityX1e4, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('assetId: $assetId, ')
          ..write('assetAction: $assetAction, ')
          ..write('memo: $memo, ')
          ..write('growthMode: $growthMode, ')
          ..write('growthRate: $growthRate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    name,
    kind,
    amount,
    quantityX1e4,
    categoryId,
    accountId,
    toAccountId,
    assetId,
    assetAction,
    memo,
    growthMode,
    growthRate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.quantityX1e4 == this.quantityX1e4 &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.assetId == this.assetId &&
          other.assetAction == this.assetAction &&
          other.memo == this.memo &&
          other.growthMode == this.growthMode &&
          other.growthRate == this.growthRate);
}

class TemplatesCompanion extends UpdateCompanion<TemplateRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> name;
  final Value<String> kind;
  final Value<int?> amount;
  final Value<int?> quantityX1e4;
  final Value<String?> categoryId;
  final Value<String?> accountId;
  final Value<String?> toAccountId;
  final Value<String?> assetId;
  final Value<String?> assetAction;
  final Value<String?> memo;
  final Value<String> growthMode;
  final Value<double?> growthRate;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.quantityX1e4 = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetAction = const Value.absent(),
    this.memo = const Value.absent(),
    this.growthMode = const Value.absent(),
    this.growthRate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String name,
    required String kind,
    this.amount = const Value.absent(),
    this.quantityX1e4 = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetAction = const Value.absent(),
    this.memo = const Value.absent(),
    required String growthMode,
    this.growthRate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       name = Value(name),
       kind = Value(kind),
       growthMode = Value(growthMode);
  static Insertable<TemplateRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<int>? quantityX1e4,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<String>? toAccountId,
    Expression<String>? assetId,
    Expression<String>? assetAction,
    Expression<String>? memo,
    Expression<String>? growthMode,
    Expression<double>? growthRate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (quantityX1e4 != null) 'quantity_x1e4': quantityX1e4,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (assetId != null) 'asset_id': assetId,
      if (assetAction != null) 'asset_action': assetAction,
      if (memo != null) 'memo': memo,
      if (growthMode != null) 'growth_mode': growthMode,
      if (growthRate != null) 'growth_rate': growthRate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? name,
    Value<String>? kind,
    Value<int?>? amount,
    Value<int?>? quantityX1e4,
    Value<String?>? categoryId,
    Value<String?>? accountId,
    Value<String?>? toAccountId,
    Value<String?>? assetId,
    Value<String?>? assetAction,
    Value<String?>? memo,
    Value<String>? growthMode,
    Value<double?>? growthRate,
    Value<int>? rowid,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      quantityX1e4: quantityX1e4 ?? this.quantityX1e4,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      assetId: assetId ?? this.assetId,
      assetAction: assetAction ?? this.assetAction,
      memo: memo ?? this.memo,
      growthMode: growthMode ?? this.growthMode,
      growthRate: growthRate ?? this.growthRate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (quantityX1e4.present) {
      map['quantity_x1e4'] = Variable<int>(quantityX1e4.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (assetAction.present) {
      map['asset_action'] = Variable<String>(assetAction.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (growthMode.present) {
      map['growth_mode'] = Variable<String>(growthMode.value);
    }
    if (growthRate.present) {
      map['growth_rate'] = Variable<double>(growthRate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('quantityX1e4: $quantityX1e4, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('assetId: $assetId, ')
          ..write('assetAction: $assetAction, ')
          ..write('memo: $memo, ')
          ..write('growthMode: $growthMode, ')
          ..write('growthRate: $growthRate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateGroupsTable extends TemplateGroups
    with TableInfo<$TemplateGroupsTable, TemplateGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    name,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_group';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TemplateGroupsTable createAlias(String alias) {
    return $TemplateGroupsTable(attachedDatabase, alias);
  }
}

class TemplateGroupRow extends DataClass
    implements Insertable<TemplateGroupRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String name;
  final int sortOrder;
  const TemplateGroupRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TemplateGroupsCompanion toCompanion(bool nullToAbsent) {
    return TemplateGroupsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory TemplateGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateGroupRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TemplateGroupRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? name,
    int? sortOrder,
  }) => TemplateGroupRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TemplateGroupRow copyWithCompanion(TemplateGroupsCompanion data) {
    return TemplateGroupRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateGroupRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    name,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateGroupRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class TemplateGroupsCompanion extends UpdateCompanion<TemplateGroupRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TemplateGroupsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateGroupsCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String name,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<TemplateGroupRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return TemplateGroupsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateGroupsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateGroupItemsTable extends TemplateGroupItems
    with TableInfo<$TemplateGroupItemsTable, TemplateGroupItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateGroupItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountModeMeta = const VerificationMeta(
    'amountMode',
  );
  @override
  late final GeneratedColumn<String> amountMode = GeneratedColumn<String>(
    'amount_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseItemIdMeta = const VerificationMeta(
    'baseItemId',
  );
  @override
  late final GeneratedColumn<String> baseItemId = GeneratedColumn<String>(
    'base_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _percentMeta = const VerificationMeta(
    'percent',
  );
  @override
  late final GeneratedColumn<double> percent = GeneratedColumn<double>(
    'percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalNMeta = const VerificationMeta(
    'intervalN',
  );
  @override
  late final GeneratedColumn<int> intervalN = GeneratedColumn<int>(
    'interval_n',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthsMeta = const VerificationMeta('months');
  @override
  late final GeneratedColumn<String> months = GeneratedColumn<String>(
    'months',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    groupId,
    templateId,
    amountMode,
    baseItemId,
    percent,
    frequency,
    intervalN,
    month,
    weekday,
    months,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_group_item';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateGroupItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('amount_mode')) {
      context.handle(
        _amountModeMeta,
        amountMode.isAcceptableOrUnknown(data['amount_mode']!, _amountModeMeta),
      );
    } else if (isInserting) {
      context.missing(_amountModeMeta);
    }
    if (data.containsKey('base_item_id')) {
      context.handle(
        _baseItemIdMeta,
        baseItemId.isAcceptableOrUnknown(
          data['base_item_id']!,
          _baseItemIdMeta,
        ),
      );
    }
    if (data.containsKey('percent')) {
      context.handle(
        _percentMeta,
        percent.isAcceptableOrUnknown(data['percent']!, _percentMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('interval_n')) {
      context.handle(
        _intervalNMeta,
        intervalN.isAcceptableOrUnknown(data['interval_n']!, _intervalNMeta),
      );
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    }
    if (data.containsKey('months')) {
      context.handle(
        _monthsMeta,
        months.isAcceptableOrUnknown(data['months']!, _monthsMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateGroupItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateGroupItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      amountMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_mode'],
      )!,
      baseItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_item_id'],
      ),
      percent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percent'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      ),
      intervalN: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_n'],
      ),
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      ),
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      ),
      months: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}months'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TemplateGroupItemsTable createAlias(String alias) {
    return $TemplateGroupItemsTable(attachedDatabase, alias);
  }
}

class TemplateGroupItemRow extends DataClass
    implements Insertable<TemplateGroupItemRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String groupId;
  final String templateId;

  /// fixed / percent
  final String amountMode;
  final String? baseItemId;
  final double? percent;

  /// monthly / yearly / every_n_months / every_n_years / weekly / specific_months
  final String? frequency;
  final int? intervalN;
  final int? month;
  final int? weekday;
  final String? months;
  final int sortOrder;
  const TemplateGroupItemRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.groupId,
    required this.templateId,
    required this.amountMode,
    this.baseItemId,
    this.percent,
    this.frequency,
    this.intervalN,
    this.month,
    this.weekday,
    this.months,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['group_id'] = Variable<String>(groupId);
    map['template_id'] = Variable<String>(templateId);
    map['amount_mode'] = Variable<String>(amountMode);
    if (!nullToAbsent || baseItemId != null) {
      map['base_item_id'] = Variable<String>(baseItemId);
    }
    if (!nullToAbsent || percent != null) {
      map['percent'] = Variable<double>(percent);
    }
    if (!nullToAbsent || frequency != null) {
      map['frequency'] = Variable<String>(frequency);
    }
    if (!nullToAbsent || intervalN != null) {
      map['interval_n'] = Variable<int>(intervalN);
    }
    if (!nullToAbsent || month != null) {
      map['month'] = Variable<int>(month);
    }
    if (!nullToAbsent || weekday != null) {
      map['weekday'] = Variable<int>(weekday);
    }
    if (!nullToAbsent || months != null) {
      map['months'] = Variable<String>(months);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TemplateGroupItemsCompanion toCompanion(bool nullToAbsent) {
    return TemplateGroupItemsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      groupId: Value(groupId),
      templateId: Value(templateId),
      amountMode: Value(amountMode),
      baseItemId: baseItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(baseItemId),
      percent: percent == null && nullToAbsent
          ? const Value.absent()
          : Value(percent),
      frequency: frequency == null && nullToAbsent
          ? const Value.absent()
          : Value(frequency),
      intervalN: intervalN == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalN),
      month: month == null && nullToAbsent
          ? const Value.absent()
          : Value(month),
      weekday: weekday == null && nullToAbsent
          ? const Value.absent()
          : Value(weekday),
      months: months == null && nullToAbsent
          ? const Value.absent()
          : Value(months),
      sortOrder: Value(sortOrder),
    );
  }

  factory TemplateGroupItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateGroupItemRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      groupId: serializer.fromJson<String>(json['groupId']),
      templateId: serializer.fromJson<String>(json['templateId']),
      amountMode: serializer.fromJson<String>(json['amountMode']),
      baseItemId: serializer.fromJson<String?>(json['baseItemId']),
      percent: serializer.fromJson<double?>(json['percent']),
      frequency: serializer.fromJson<String?>(json['frequency']),
      intervalN: serializer.fromJson<int?>(json['intervalN']),
      month: serializer.fromJson<int?>(json['month']),
      weekday: serializer.fromJson<int?>(json['weekday']),
      months: serializer.fromJson<String?>(json['months']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'groupId': serializer.toJson<String>(groupId),
      'templateId': serializer.toJson<String>(templateId),
      'amountMode': serializer.toJson<String>(amountMode),
      'baseItemId': serializer.toJson<String?>(baseItemId),
      'percent': serializer.toJson<double?>(percent),
      'frequency': serializer.toJson<String?>(frequency),
      'intervalN': serializer.toJson<int?>(intervalN),
      'month': serializer.toJson<int?>(month),
      'weekday': serializer.toJson<int?>(weekday),
      'months': serializer.toJson<String?>(months),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TemplateGroupItemRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? groupId,
    String? templateId,
    String? amountMode,
    Value<String?> baseItemId = const Value.absent(),
    Value<double?> percent = const Value.absent(),
    Value<String?> frequency = const Value.absent(),
    Value<int?> intervalN = const Value.absent(),
    Value<int?> month = const Value.absent(),
    Value<int?> weekday = const Value.absent(),
    Value<String?> months = const Value.absent(),
    int? sortOrder,
  }) => TemplateGroupItemRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    groupId: groupId ?? this.groupId,
    templateId: templateId ?? this.templateId,
    amountMode: amountMode ?? this.amountMode,
    baseItemId: baseItemId.present ? baseItemId.value : this.baseItemId,
    percent: percent.present ? percent.value : this.percent,
    frequency: frequency.present ? frequency.value : this.frequency,
    intervalN: intervalN.present ? intervalN.value : this.intervalN,
    month: month.present ? month.value : this.month,
    weekday: weekday.present ? weekday.value : this.weekday,
    months: months.present ? months.value : this.months,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TemplateGroupItemRow copyWithCompanion(TemplateGroupItemsCompanion data) {
    return TemplateGroupItemRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      amountMode: data.amountMode.present
          ? data.amountMode.value
          : this.amountMode,
      baseItemId: data.baseItemId.present
          ? data.baseItemId.value
          : this.baseItemId,
      percent: data.percent.present ? data.percent.value : this.percent,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      intervalN: data.intervalN.present ? data.intervalN.value : this.intervalN,
      month: data.month.present ? data.month.value : this.month,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      months: data.months.present ? data.months.value : this.months,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateGroupItemRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('groupId: $groupId, ')
          ..write('templateId: $templateId, ')
          ..write('amountMode: $amountMode, ')
          ..write('baseItemId: $baseItemId, ')
          ..write('percent: $percent, ')
          ..write('frequency: $frequency, ')
          ..write('intervalN: $intervalN, ')
          ..write('month: $month, ')
          ..write('weekday: $weekday, ')
          ..write('months: $months, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    groupId,
    templateId,
    amountMode,
    baseItemId,
    percent,
    frequency,
    intervalN,
    month,
    weekday,
    months,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateGroupItemRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.groupId == this.groupId &&
          other.templateId == this.templateId &&
          other.amountMode == this.amountMode &&
          other.baseItemId == this.baseItemId &&
          other.percent == this.percent &&
          other.frequency == this.frequency &&
          other.intervalN == this.intervalN &&
          other.month == this.month &&
          other.weekday == this.weekday &&
          other.months == this.months &&
          other.sortOrder == this.sortOrder);
}

class TemplateGroupItemsCompanion
    extends UpdateCompanion<TemplateGroupItemRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> groupId;
  final Value<String> templateId;
  final Value<String> amountMode;
  final Value<String?> baseItemId;
  final Value<double?> percent;
  final Value<String?> frequency;
  final Value<int?> intervalN;
  final Value<int?> month;
  final Value<int?> weekday;
  final Value<String?> months;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TemplateGroupItemsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.groupId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.amountMode = const Value.absent(),
    this.baseItemId = const Value.absent(),
    this.percent = const Value.absent(),
    this.frequency = const Value.absent(),
    this.intervalN = const Value.absent(),
    this.month = const Value.absent(),
    this.weekday = const Value.absent(),
    this.months = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateGroupItemsCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String groupId,
    required String templateId,
    required String amountMode,
    this.baseItemId = const Value.absent(),
    this.percent = const Value.absent(),
    this.frequency = const Value.absent(),
    this.intervalN = const Value.absent(),
    this.month = const Value.absent(),
    this.weekday = const Value.absent(),
    this.months = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       groupId = Value(groupId),
       templateId = Value(templateId),
       amountMode = Value(amountMode),
       sortOrder = Value(sortOrder);
  static Insertable<TemplateGroupItemRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? groupId,
    Expression<String>? templateId,
    Expression<String>? amountMode,
    Expression<String>? baseItemId,
    Expression<double>? percent,
    Expression<String>? frequency,
    Expression<int>? intervalN,
    Expression<int>? month,
    Expression<int>? weekday,
    Expression<String>? months,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (groupId != null) 'group_id': groupId,
      if (templateId != null) 'template_id': templateId,
      if (amountMode != null) 'amount_mode': amountMode,
      if (baseItemId != null) 'base_item_id': baseItemId,
      if (percent != null) 'percent': percent,
      if (frequency != null) 'frequency': frequency,
      if (intervalN != null) 'interval_n': intervalN,
      if (month != null) 'month': month,
      if (weekday != null) 'weekday': weekday,
      if (months != null) 'months': months,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateGroupItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? groupId,
    Value<String>? templateId,
    Value<String>? amountMode,
    Value<String?>? baseItemId,
    Value<double?>? percent,
    Value<String?>? frequency,
    Value<int?>? intervalN,
    Value<int?>? month,
    Value<int?>? weekday,
    Value<String?>? months,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return TemplateGroupItemsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      groupId: groupId ?? this.groupId,
      templateId: templateId ?? this.templateId,
      amountMode: amountMode ?? this.amountMode,
      baseItemId: baseItemId ?? this.baseItemId,
      percent: percent ?? this.percent,
      frequency: frequency ?? this.frequency,
      intervalN: intervalN ?? this.intervalN,
      month: month ?? this.month,
      weekday: weekday ?? this.weekday,
      months: months ?? this.months,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (amountMode.present) {
      map['amount_mode'] = Variable<String>(amountMode.value);
    }
    if (baseItemId.present) {
      map['base_item_id'] = Variable<String>(baseItemId.value);
    }
    if (percent.present) {
      map['percent'] = Variable<double>(percent.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (intervalN.present) {
      map['interval_n'] = Variable<int>(intervalN.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (months.present) {
      map['months'] = Variable<String>(months.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateGroupItemsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('groupId: $groupId, ')
          ..write('templateId: $templateId, ')
          ..write('amountMode: $amountMode, ')
          ..write('baseItemId: $baseItemId, ')
          ..write('percent: $percent, ')
          ..write('frequency: $frequency, ')
          ..write('intervalN: $intervalN, ')
          ..write('month: $month, ')
          ..write('weekday: $weekday, ')
          ..write('months: $months, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlansTable extends Plans with TableInfo<$PlansTable, PlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protagonistMemberIdMeta =
      const VerificationMeta('protagonistMemberId');
  @override
  late final GeneratedColumn<String> protagonistMemberId =
      GeneratedColumn<String>(
        'protagonist_member_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _startYearMeta = const VerificationMeta(
    'startYear',
  );
  @override
  late final GeneratedColumn<int> startYear = GeneratedColumn<int>(
    'start_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baselineDateMeta = const VerificationMeta(
    'baselineDate',
  );
  @override
  late final GeneratedColumn<String> baselineDate = GeneratedColumn<String>(
    'baseline_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultInflationRateMeta =
      const VerificationMeta('defaultInflationRate');
  @override
  late final GeneratedColumn<double> defaultInflationRate =
      GeneratedColumn<double>(
        'default_inflation_rate',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _copiedFromPlanIdMeta = const VerificationMeta(
    'copiedFromPlanId',
  );
  @override
  late final GeneratedColumn<String> copiedFromPlanId = GeneratedColumn<String>(
    'copied_from_plan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    name,
    protagonistMemberId,
    startYear,
    baselineDate,
    defaultInflationRate,
    copiedFromPlanId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('protagonist_member_id')) {
      context.handle(
        _protagonistMemberIdMeta,
        protagonistMemberId.isAcceptableOrUnknown(
          data['protagonist_member_id']!,
          _protagonistMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protagonistMemberIdMeta);
    }
    if (data.containsKey('start_year')) {
      context.handle(
        _startYearMeta,
        startYear.isAcceptableOrUnknown(data['start_year']!, _startYearMeta),
      );
    } else if (isInserting) {
      context.missing(_startYearMeta);
    }
    if (data.containsKey('baseline_date')) {
      context.handle(
        _baselineDateMeta,
        baselineDate.isAcceptableOrUnknown(
          data['baseline_date']!,
          _baselineDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baselineDateMeta);
    }
    if (data.containsKey('default_inflation_rate')) {
      context.handle(
        _defaultInflationRateMeta,
        defaultInflationRate.isAcceptableOrUnknown(
          data['default_inflation_rate']!,
          _defaultInflationRateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultInflationRateMeta);
    }
    if (data.containsKey('copied_from_plan_id')) {
      context.handle(
        _copiedFromPlanIdMeta,
        copiedFromPlanId.isAcceptableOrUnknown(
          data['copied_from_plan_id']!,
          _copiedFromPlanIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      protagonistMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protagonist_member_id'],
      )!,
      startYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_year'],
      )!,
      baselineDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}baseline_date'],
      )!,
      defaultInflationRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_inflation_rate'],
      )!,
      copiedFromPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}copied_from_plan_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class PlanRow extends DataClass implements Insertable<PlanRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String name;
  final String protagonistMemberId;
  final int startYear;
  final String baselineDate;
  final double defaultInflationRate;
  final String? copiedFromPlanId;
  final int sortOrder;
  const PlanRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.name,
    required this.protagonistMemberId,
    required this.startYear,
    required this.baselineDate,
    required this.defaultInflationRate,
    this.copiedFromPlanId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['protagonist_member_id'] = Variable<String>(protagonistMemberId);
    map['start_year'] = Variable<int>(startYear);
    map['baseline_date'] = Variable<String>(baselineDate);
    map['default_inflation_rate'] = Variable<double>(defaultInflationRate);
    if (!nullToAbsent || copiedFromPlanId != null) {
      map['copied_from_plan_id'] = Variable<String>(copiedFromPlanId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      protagonistMemberId: Value(protagonistMemberId),
      startYear: Value(startYear),
      baselineDate: Value(baselineDate),
      defaultInflationRate: Value(defaultInflationRate),
      copiedFromPlanId: copiedFromPlanId == null && nullToAbsent
          ? const Value.absent()
          : Value(copiedFromPlanId),
      sortOrder: Value(sortOrder),
    );
  }

  factory PlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      protagonistMemberId: serializer.fromJson<String>(
        json['protagonistMemberId'],
      ),
      startYear: serializer.fromJson<int>(json['startYear']),
      baselineDate: serializer.fromJson<String>(json['baselineDate']),
      defaultInflationRate: serializer.fromJson<double>(
        json['defaultInflationRate'],
      ),
      copiedFromPlanId: serializer.fromJson<String?>(json['copiedFromPlanId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'protagonistMemberId': serializer.toJson<String>(protagonistMemberId),
      'startYear': serializer.toJson<int>(startYear),
      'baselineDate': serializer.toJson<String>(baselineDate),
      'defaultInflationRate': serializer.toJson<double>(defaultInflationRate),
      'copiedFromPlanId': serializer.toJson<String?>(copiedFromPlanId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  PlanRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? name,
    String? protagonistMemberId,
    int? startYear,
    String? baselineDate,
    double? defaultInflationRate,
    Value<String?> copiedFromPlanId = const Value.absent(),
    int? sortOrder,
  }) => PlanRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    protagonistMemberId: protagonistMemberId ?? this.protagonistMemberId,
    startYear: startYear ?? this.startYear,
    baselineDate: baselineDate ?? this.baselineDate,
    defaultInflationRate: defaultInflationRate ?? this.defaultInflationRate,
    copiedFromPlanId: copiedFromPlanId.present
        ? copiedFromPlanId.value
        : this.copiedFromPlanId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  PlanRow copyWithCompanion(PlansCompanion data) {
    return PlanRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      protagonistMemberId: data.protagonistMemberId.present
          ? data.protagonistMemberId.value
          : this.protagonistMemberId,
      startYear: data.startYear.present ? data.startYear.value : this.startYear,
      baselineDate: data.baselineDate.present
          ? data.baselineDate.value
          : this.baselineDate,
      defaultInflationRate: data.defaultInflationRate.present
          ? data.defaultInflationRate.value
          : this.defaultInflationRate,
      copiedFromPlanId: data.copiedFromPlanId.present
          ? data.copiedFromPlanId.value
          : this.copiedFromPlanId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('protagonistMemberId: $protagonistMemberId, ')
          ..write('startYear: $startYear, ')
          ..write('baselineDate: $baselineDate, ')
          ..write('defaultInflationRate: $defaultInflationRate, ')
          ..write('copiedFromPlanId: $copiedFromPlanId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    name,
    protagonistMemberId,
    startYear,
    baselineDate,
    defaultInflationRate,
    copiedFromPlanId,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.protagonistMemberId == this.protagonistMemberId &&
          other.startYear == this.startYear &&
          other.baselineDate == this.baselineDate &&
          other.defaultInflationRate == this.defaultInflationRate &&
          other.copiedFromPlanId == this.copiedFromPlanId &&
          other.sortOrder == this.sortOrder);
}

class PlansCompanion extends UpdateCompanion<PlanRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> name;
  final Value<String> protagonistMemberId;
  final Value<int> startYear;
  final Value<String> baselineDate;
  final Value<double> defaultInflationRate;
  final Value<String?> copiedFromPlanId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.protagonistMemberId = const Value.absent(),
    this.startYear = const Value.absent(),
    this.baselineDate = const Value.absent(),
    this.defaultInflationRate = const Value.absent(),
    this.copiedFromPlanId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlansCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String name,
    required String protagonistMemberId,
    required int startYear,
    required String baselineDate,
    required double defaultInflationRate,
    this.copiedFromPlanId = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       name = Value(name),
       protagonistMemberId = Value(protagonistMemberId),
       startYear = Value(startYear),
       baselineDate = Value(baselineDate),
       defaultInflationRate = Value(defaultInflationRate),
       sortOrder = Value(sortOrder);
  static Insertable<PlanRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? name,
    Expression<String>? protagonistMemberId,
    Expression<int>? startYear,
    Expression<String>? baselineDate,
    Expression<double>? defaultInflationRate,
    Expression<String>? copiedFromPlanId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (protagonistMemberId != null)
        'protagonist_member_id': protagonistMemberId,
      if (startYear != null) 'start_year': startYear,
      if (baselineDate != null) 'baseline_date': baselineDate,
      if (defaultInflationRate != null)
        'default_inflation_rate': defaultInflationRate,
      if (copiedFromPlanId != null) 'copied_from_plan_id': copiedFromPlanId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlansCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? name,
    Value<String>? protagonistMemberId,
    Value<int>? startYear,
    Value<String>? baselineDate,
    Value<double>? defaultInflationRate,
    Value<String?>? copiedFromPlanId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      protagonistMemberId: protagonistMemberId ?? this.protagonistMemberId,
      startYear: startYear ?? this.startYear,
      baselineDate: baselineDate ?? this.baselineDate,
      defaultInflationRate: defaultInflationRate ?? this.defaultInflationRate,
      copiedFromPlanId: copiedFromPlanId ?? this.copiedFromPlanId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (protagonistMemberId.present) {
      map['protagonist_member_id'] = Variable<String>(
        protagonistMemberId.value,
      );
    }
    if (startYear.present) {
      map['start_year'] = Variable<int>(startYear.value);
    }
    if (baselineDate.present) {
      map['baseline_date'] = Variable<String>(baselineDate.value);
    }
    if (defaultInflationRate.present) {
      map['default_inflation_rate'] = Variable<double>(
        defaultInflationRate.value,
      );
    }
    if (copiedFromPlanId.present) {
      map['copied_from_plan_id'] = Variable<String>(copiedFromPlanId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('protagonistMemberId: $protagonistMemberId, ')
          ..write('startYear: $startYear, ')
          ..write('baselineDate: $baselineDate, ')
          ..write('defaultInflationRate: $defaultInflationRate, ')
          ..write('copiedFromPlanId: $copiedFromPlanId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyMembersTable extends FamilyMembers
    with TableInfo<$FamilyMembersTable, FamilyMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationMeta = const VerificationMeta(
    'relation',
  );
  @override
  late final GeneratedColumn<String> relation = GeneratedColumn<String>(
    'relation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
    'birth_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lifeExpectancyMeta = const VerificationMeta(
    'lifeExpectancy',
  );
  @override
  late final GeneratedColumn<int> lifeExpectancy = GeneratedColumn<int>(
    'life_expectancy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    name,
    relation,
    birthDate,
    lifeExpectancy,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_member';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('relation')) {
      context.handle(
        _relationMeta,
        relation.isAcceptableOrUnknown(data['relation']!, _relationMeta),
      );
    } else if (isInserting) {
      context.missing(_relationMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('life_expectancy')) {
      context.handle(
        _lifeExpectancyMeta,
        lifeExpectancy.isAcceptableOrUnknown(
          data['life_expectancy']!,
          _lifeExpectancyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lifeExpectancyMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyMemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      relation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_date'],
      )!,
      lifeExpectancy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}life_expectancy'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $FamilyMembersTable createAlias(String alias) {
    return $FamilyMembersTable(attachedDatabase, alias);
  }
}

class FamilyMemberRow extends DataClass implements Insertable<FamilyMemberRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String planId;
  final String name;

  /// self / spouse / child / parent / other
  final String relation;
  final String birthDate;
  final int lifeExpectancy;
  final int sortOrder;
  const FamilyMemberRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.planId,
    required this.name,
    required this.relation,
    required this.birthDate,
    required this.lifeExpectancy,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['plan_id'] = Variable<String>(planId);
    map['name'] = Variable<String>(name);
    map['relation'] = Variable<String>(relation);
    map['birth_date'] = Variable<String>(birthDate);
    map['life_expectancy'] = Variable<int>(lifeExpectancy);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FamilyMembersCompanion toCompanion(bool nullToAbsent) {
    return FamilyMembersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      planId: Value(planId),
      name: Value(name),
      relation: Value(relation),
      birthDate: Value(birthDate),
      lifeExpectancy: Value(lifeExpectancy),
      sortOrder: Value(sortOrder),
    );
  }

  factory FamilyMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyMemberRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      planId: serializer.fromJson<String>(json['planId']),
      name: serializer.fromJson<String>(json['name']),
      relation: serializer.fromJson<String>(json['relation']),
      birthDate: serializer.fromJson<String>(json['birthDate']),
      lifeExpectancy: serializer.fromJson<int>(json['lifeExpectancy']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'planId': serializer.toJson<String>(planId),
      'name': serializer.toJson<String>(name),
      'relation': serializer.toJson<String>(relation),
      'birthDate': serializer.toJson<String>(birthDate),
      'lifeExpectancy': serializer.toJson<int>(lifeExpectancy),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  FamilyMemberRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? planId,
    String? name,
    String? relation,
    String? birthDate,
    int? lifeExpectancy,
    int? sortOrder,
  }) => FamilyMemberRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    planId: planId ?? this.planId,
    name: name ?? this.name,
    relation: relation ?? this.relation,
    birthDate: birthDate ?? this.birthDate,
    lifeExpectancy: lifeExpectancy ?? this.lifeExpectancy,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  FamilyMemberRow copyWithCompanion(FamilyMembersCompanion data) {
    return FamilyMemberRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      planId: data.planId.present ? data.planId.value : this.planId,
      name: data.name.present ? data.name.value : this.name,
      relation: data.relation.present ? data.relation.value : this.relation,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      lifeExpectancy: data.lifeExpectancy.present
          ? data.lifeExpectancy.value
          : this.lifeExpectancy,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMemberRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('name: $name, ')
          ..write('relation: $relation, ')
          ..write('birthDate: $birthDate, ')
          ..write('lifeExpectancy: $lifeExpectancy, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    name,
    relation,
    birthDate,
    lifeExpectancy,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyMemberRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.planId == this.planId &&
          other.name == this.name &&
          other.relation == this.relation &&
          other.birthDate == this.birthDate &&
          other.lifeExpectancy == this.lifeExpectancy &&
          other.sortOrder == this.sortOrder);
}

class FamilyMembersCompanion extends UpdateCompanion<FamilyMemberRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> planId;
  final Value<String> name;
  final Value<String> relation;
  final Value<String> birthDate;
  final Value<int> lifeExpectancy;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const FamilyMembersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.planId = const Value.absent(),
    this.name = const Value.absent(),
    this.relation = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.lifeExpectancy = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyMembersCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String planId,
    required String name,
    required String relation,
    required String birthDate,
    required int lifeExpectancy,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       planId = Value(planId),
       name = Value(name),
       relation = Value(relation),
       birthDate = Value(birthDate),
       lifeExpectancy = Value(lifeExpectancy),
       sortOrder = Value(sortOrder);
  static Insertable<FamilyMemberRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? planId,
    Expression<String>? name,
    Expression<String>? relation,
    Expression<String>? birthDate,
    Expression<int>? lifeExpectancy,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (planId != null) 'plan_id': planId,
      if (name != null) 'name': name,
      if (relation != null) 'relation': relation,
      if (birthDate != null) 'birth_date': birthDate,
      if (lifeExpectancy != null) 'life_expectancy': lifeExpectancy,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? planId,
    Value<String>? name,
    Value<String>? relation,
    Value<String>? birthDate,
    Value<int>? lifeExpectancy,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return FamilyMembersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      birthDate: birthDate ?? this.birthDate,
      lifeExpectancy: lifeExpectancy ?? this.lifeExpectancy,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (relation.present) {
      map['relation'] = Variable<String>(relation.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (lifeExpectancy.present) {
      map['life_expectancy'] = Variable<int>(lifeExpectancy.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMembersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('name: $name, ')
          ..write('relation: $relation, ')
          ..write('birthDate: $birthDate, ')
          ..write('lifeExpectancy: $lifeExpectancy, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanLinesTable extends PlanLines
    with TableInfo<$PlanLinesTable, PlanLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetActionMeta = const VerificationMeta(
    'assetAction',
  );
  @override
  late final GeneratedColumn<String> assetAction = GeneratedColumn<String>(
    'asset_action',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityX1e4Meta = const VerificationMeta(
    'quantityX1e4',
  );
  @override
  late final GeneratedColumn<int> quantityX1e4 = GeneratedColumn<int>(
    'quantity_x1e4',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupItemIdMeta = const VerificationMeta(
    'groupItemId',
  );
  @override
  late final GeneratedColumn<String> groupItemId = GeneratedColumn<String>(
    'group_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    year,
    month,
    kind,
    amount,
    categoryId,
    accountId,
    toAccountId,
    assetId,
    assetAction,
    quantityX1e4,
    eventId,
    memo,
    source,
    sourceId,
    memberId,
    groupItemId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_line';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    if (data.containsKey('asset_action')) {
      context.handle(
        _assetActionMeta,
        assetAction.isAcceptableOrUnknown(
          data['asset_action']!,
          _assetActionMeta,
        ),
      );
    }
    if (data.containsKey('quantity_x1e4')) {
      context.handle(
        _quantityX1e4Meta,
        quantityX1e4.isAcceptableOrUnknown(
          data['quantity_x1e4']!,
          _quantityX1e4Meta,
        ),
      );
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    }
    if (data.containsKey('group_item_id')) {
      context.handle(
        _groupItemIdMeta,
        groupItemId.isAcceptableOrUnknown(
          data['group_item_id']!,
          _groupItemIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      ),
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      ),
      assetAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_action'],
      ),
      quantityX1e4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_x1e4'],
      ),
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      ),
      groupItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_item_id'],
      ),
    );
  }

  @override
  $PlanLinesTable createAlias(String alias) {
    return $PlanLinesTable(attachedDatabase, alias);
  }
}

class PlanLineRow extends DataClass implements Insertable<PlanLineRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String planId;
  final int year;
  final int month;
  final String kind;
  final int amount;
  final String? categoryId;
  final String accountId;
  final String? toAccountId;
  final String? assetId;
  final String? assetAction;
  final int? quantityX1e4;
  final String? eventId;
  final String? memo;

  /// manual / group / event
  final String source;
  final String? sourceId;
  final String? memberId;
  final String? groupItemId;
  const PlanLineRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.planId,
    required this.year,
    required this.month,
    required this.kind,
    required this.amount,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.assetId,
    this.assetAction,
    this.quantityX1e4,
    this.eventId,
    this.memo,
    required this.source,
    this.sourceId,
    this.memberId,
    this.groupItemId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['plan_id'] = Variable<String>(planId);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['kind'] = Variable<String>(kind);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<String>(assetId);
    }
    if (!nullToAbsent || assetAction != null) {
      map['asset_action'] = Variable<String>(assetAction);
    }
    if (!nullToAbsent || quantityX1e4 != null) {
      map['quantity_x1e4'] = Variable<int>(quantityX1e4);
    }
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    if (!nullToAbsent || groupItemId != null) {
      map['group_item_id'] = Variable<String>(groupItemId);
    }
    return map;
  }

  PlanLinesCompanion toCompanion(bool nullToAbsent) {
    return PlanLinesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      planId: Value(planId),
      year: Value(year),
      month: Value(month),
      kind: Value(kind),
      amount: Value(amount),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      assetAction: assetAction == null && nullToAbsent
          ? const Value.absent()
          : Value(assetAction),
      quantityX1e4: quantityX1e4 == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityX1e4),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      source: Value(source),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      groupItemId: groupItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupItemId),
    );
  }

  factory PlanLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanLineRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      planId: serializer.fromJson<String>(json['planId']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<int>(json['amount']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      assetId: serializer.fromJson<String?>(json['assetId']),
      assetAction: serializer.fromJson<String?>(json['assetAction']),
      quantityX1e4: serializer.fromJson<int?>(json['quantityX1e4']),
      eventId: serializer.fromJson<String?>(json['eventId']),
      memo: serializer.fromJson<String?>(json['memo']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      groupItemId: serializer.fromJson<String?>(json['groupItemId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'planId': serializer.toJson<String>(planId),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<int>(amount),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String>(accountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'assetId': serializer.toJson<String?>(assetId),
      'assetAction': serializer.toJson<String?>(assetAction),
      'quantityX1e4': serializer.toJson<int?>(quantityX1e4),
      'eventId': serializer.toJson<String?>(eventId),
      'memo': serializer.toJson<String?>(memo),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String?>(sourceId),
      'memberId': serializer.toJson<String?>(memberId),
      'groupItemId': serializer.toJson<String?>(groupItemId),
    };
  }

  PlanLineRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? planId,
    int? year,
    int? month,
    String? kind,
    int? amount,
    Value<String?> categoryId = const Value.absent(),
    String? accountId,
    Value<String?> toAccountId = const Value.absent(),
    Value<String?> assetId = const Value.absent(),
    Value<String?> assetAction = const Value.absent(),
    Value<int?> quantityX1e4 = const Value.absent(),
    Value<String?> eventId = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    String? source,
    Value<String?> sourceId = const Value.absent(),
    Value<String?> memberId = const Value.absent(),
    Value<String?> groupItemId = const Value.absent(),
  }) => PlanLineRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    planId: planId ?? this.planId,
    year: year ?? this.year,
    month: month ?? this.month,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    assetId: assetId.present ? assetId.value : this.assetId,
    assetAction: assetAction.present ? assetAction.value : this.assetAction,
    quantityX1e4: quantityX1e4.present ? quantityX1e4.value : this.quantityX1e4,
    eventId: eventId.present ? eventId.value : this.eventId,
    memo: memo.present ? memo.value : this.memo,
    source: source ?? this.source,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    memberId: memberId.present ? memberId.value : this.memberId,
    groupItemId: groupItemId.present ? groupItemId.value : this.groupItemId,
  );
  PlanLineRow copyWithCompanion(PlanLinesCompanion data) {
    return PlanLineRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      planId: data.planId.present ? data.planId.value : this.planId,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      assetAction: data.assetAction.present
          ? data.assetAction.value
          : this.assetAction,
      quantityX1e4: data.quantityX1e4.present
          ? data.quantityX1e4.value
          : this.quantityX1e4,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      memo: data.memo.present ? data.memo.value : this.memo,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      groupItemId: data.groupItemId.present
          ? data.groupItemId.value
          : this.groupItemId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanLineRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('assetId: $assetId, ')
          ..write('assetAction: $assetAction, ')
          ..write('quantityX1e4: $quantityX1e4, ')
          ..write('eventId: $eventId, ')
          ..write('memo: $memo, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('memberId: $memberId, ')
          ..write('groupItemId: $groupItemId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    year,
    month,
    kind,
    amount,
    categoryId,
    accountId,
    toAccountId,
    assetId,
    assetAction,
    quantityX1e4,
    eventId,
    memo,
    source,
    sourceId,
    memberId,
    groupItemId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanLineRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.planId == this.planId &&
          other.year == this.year &&
          other.month == this.month &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.assetId == this.assetId &&
          other.assetAction == this.assetAction &&
          other.quantityX1e4 == this.quantityX1e4 &&
          other.eventId == this.eventId &&
          other.memo == this.memo &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.memberId == this.memberId &&
          other.groupItemId == this.groupItemId);
}

class PlanLinesCompanion extends UpdateCompanion<PlanLineRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> planId;
  final Value<int> year;
  final Value<int> month;
  final Value<String> kind;
  final Value<int> amount;
  final Value<String?> categoryId;
  final Value<String> accountId;
  final Value<String?> toAccountId;
  final Value<String?> assetId;
  final Value<String?> assetAction;
  final Value<int?> quantityX1e4;
  final Value<String?> eventId;
  final Value<String?> memo;
  final Value<String> source;
  final Value<String?> sourceId;
  final Value<String?> memberId;
  final Value<String?> groupItemId;
  final Value<int> rowid;
  const PlanLinesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.planId = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetAction = const Value.absent(),
    this.quantityX1e4 = const Value.absent(),
    this.eventId = const Value.absent(),
    this.memo = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.groupItemId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanLinesCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String planId,
    required int year,
    required int month,
    required String kind,
    required int amount,
    this.categoryId = const Value.absent(),
    required String accountId,
    this.toAccountId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetAction = const Value.absent(),
    this.quantityX1e4 = const Value.absent(),
    this.eventId = const Value.absent(),
    this.memo = const Value.absent(),
    required String source,
    this.sourceId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.groupItemId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       planId = Value(planId),
       year = Value(year),
       month = Value(month),
       kind = Value(kind),
       amount = Value(amount),
       accountId = Value(accountId),
       source = Value(source);
  static Insertable<PlanLineRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? planId,
    Expression<int>? year,
    Expression<int>? month,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<String>? toAccountId,
    Expression<String>? assetId,
    Expression<String>? assetAction,
    Expression<int>? quantityX1e4,
    Expression<String>? eventId,
    Expression<String>? memo,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<String>? memberId,
    Expression<String>? groupItemId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (planId != null) 'plan_id': planId,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (assetId != null) 'asset_id': assetId,
      if (assetAction != null) 'asset_action': assetAction,
      if (quantityX1e4 != null) 'quantity_x1e4': quantityX1e4,
      if (eventId != null) 'event_id': eventId,
      if (memo != null) 'memo': memo,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (memberId != null) 'member_id': memberId,
      if (groupItemId != null) 'group_item_id': groupItemId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? planId,
    Value<int>? year,
    Value<int>? month,
    Value<String>? kind,
    Value<int>? amount,
    Value<String?>? categoryId,
    Value<String>? accountId,
    Value<String?>? toAccountId,
    Value<String?>? assetId,
    Value<String?>? assetAction,
    Value<int?>? quantityX1e4,
    Value<String?>? eventId,
    Value<String?>? memo,
    Value<String>? source,
    Value<String?>? sourceId,
    Value<String?>? memberId,
    Value<String?>? groupItemId,
    Value<int>? rowid,
  }) {
    return PlanLinesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      planId: planId ?? this.planId,
      year: year ?? this.year,
      month: month ?? this.month,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      assetId: assetId ?? this.assetId,
      assetAction: assetAction ?? this.assetAction,
      quantityX1e4: quantityX1e4 ?? this.quantityX1e4,
      eventId: eventId ?? this.eventId,
      memo: memo ?? this.memo,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      memberId: memberId ?? this.memberId,
      groupItemId: groupItemId ?? this.groupItemId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (assetAction.present) {
      map['asset_action'] = Variable<String>(assetAction.value);
    }
    if (quantityX1e4.present) {
      map['quantity_x1e4'] = Variable<int>(quantityX1e4.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (groupItemId.present) {
      map['group_item_id'] = Variable<String>(groupItemId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanLinesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('assetId: $assetId, ')
          ..write('assetAction: $assetAction, ')
          ..write('quantityX1e4: $quantityX1e4, ')
          ..write('eventId: $eventId, ')
          ..write('memo: $memo, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('memberId: $memberId, ')
          ..write('groupItemId: $groupItemId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanEventsTable extends PlanEvents
    with TableInfo<$PlanEventsTable, PlanEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneDateMeta = const VerificationMeta(
    'doneDate',
  );
  @override
  late final GeneratedColumn<String> doneDate = GeneratedColumn<String>(
    'done_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    memberId,
    title,
    year,
    month,
    day,
    status,
    doneDate,
    memo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_event';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('done_date')) {
      context.handle(
        _doneDateMeta,
        doneDate.isAcceptableOrUnknown(data['done_date']!, _doneDateMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      doneDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}done_date'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
    );
  }

  @override
  $PlanEventsTable createAlias(String alias) {
    return $PlanEventsTable(attachedDatabase, alias);
  }
}

class PlanEventRow extends DataClass implements Insertable<PlanEventRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String planId;
  final String memberId;
  final String title;
  final int year;
  final int month;
  final int? day;

  /// planned / done
  final String status;
  final String? doneDate;
  final String? memo;
  const PlanEventRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.planId,
    required this.memberId,
    required this.title,
    required this.year,
    required this.month,
    this.day,
    required this.status,
    this.doneDate,
    this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['plan_id'] = Variable<String>(planId);
    map['member_id'] = Variable<String>(memberId);
    map['title'] = Variable<String>(title);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    if (!nullToAbsent || day != null) {
      map['day'] = Variable<int>(day);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || doneDate != null) {
      map['done_date'] = Variable<String>(doneDate);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  PlanEventsCompanion toCompanion(bool nullToAbsent) {
    return PlanEventsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      planId: Value(planId),
      memberId: Value(memberId),
      title: Value(title),
      year: Value(year),
      month: Value(month),
      day: day == null && nullToAbsent ? const Value.absent() : Value(day),
      status: Value(status),
      doneDate: doneDate == null && nullToAbsent
          ? const Value.absent()
          : Value(doneDate),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory PlanEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanEventRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      planId: serializer.fromJson<String>(json['planId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      title: serializer.fromJson<String>(json['title']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      day: serializer.fromJson<int?>(json['day']),
      status: serializer.fromJson<String>(json['status']),
      doneDate: serializer.fromJson<String?>(json['doneDate']),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'planId': serializer.toJson<String>(planId),
      'memberId': serializer.toJson<String>(memberId),
      'title': serializer.toJson<String>(title),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'day': serializer.toJson<int?>(day),
      'status': serializer.toJson<String>(status),
      'doneDate': serializer.toJson<String?>(doneDate),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  PlanEventRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? planId,
    String? memberId,
    String? title,
    int? year,
    int? month,
    Value<int?> day = const Value.absent(),
    String? status,
    Value<String?> doneDate = const Value.absent(),
    Value<String?> memo = const Value.absent(),
  }) => PlanEventRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    planId: planId ?? this.planId,
    memberId: memberId ?? this.memberId,
    title: title ?? this.title,
    year: year ?? this.year,
    month: month ?? this.month,
    day: day.present ? day.value : this.day,
    status: status ?? this.status,
    doneDate: doneDate.present ? doneDate.value : this.doneDate,
    memo: memo.present ? memo.value : this.memo,
  );
  PlanEventRow copyWithCompanion(PlanEventsCompanion data) {
    return PlanEventRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      planId: data.planId.present ? data.planId.value : this.planId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      title: data.title.present ? data.title.value : this.title,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      day: data.day.present ? data.day.value : this.day,
      status: data.status.present ? data.status.value : this.status,
      doneDate: data.doneDate.present ? data.doneDate.value : this.doneDate,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanEventRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('memberId: $memberId, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('day: $day, ')
          ..write('status: $status, ')
          ..write('doneDate: $doneDate, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    memberId,
    title,
    year,
    month,
    day,
    status,
    doneDate,
    memo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanEventRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.planId == this.planId &&
          other.memberId == this.memberId &&
          other.title == this.title &&
          other.year == this.year &&
          other.month == this.month &&
          other.day == this.day &&
          other.status == this.status &&
          other.doneDate == this.doneDate &&
          other.memo == this.memo);
}

class PlanEventsCompanion extends UpdateCompanion<PlanEventRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> planId;
  final Value<String> memberId;
  final Value<String> title;
  final Value<int> year;
  final Value<int> month;
  final Value<int?> day;
  final Value<String> status;
  final Value<String?> doneDate;
  final Value<String?> memo;
  final Value<int> rowid;
  const PlanEventsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.planId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.day = const Value.absent(),
    this.status = const Value.absent(),
    this.doneDate = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanEventsCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String planId,
    required String memberId,
    required String title,
    required int year,
    required int month,
    this.day = const Value.absent(),
    required String status,
    this.doneDate = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       planId = Value(planId),
       memberId = Value(memberId),
       title = Value(title),
       year = Value(year),
       month = Value(month),
       status = Value(status);
  static Insertable<PlanEventRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? planId,
    Expression<String>? memberId,
    Expression<String>? title,
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? day,
    Expression<String>? status,
    Expression<String>? doneDate,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (planId != null) 'plan_id': planId,
      if (memberId != null) 'member_id': memberId,
      if (title != null) 'title': title,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (day != null) 'day': day,
      if (status != null) 'status': status,
      if (doneDate != null) 'done_date': doneDate,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? planId,
    Value<String>? memberId,
    Value<String>? title,
    Value<int>? year,
    Value<int>? month,
    Value<int?>? day,
    Value<String>? status,
    Value<String?>? doneDate,
    Value<String?>? memo,
    Value<int>? rowid,
  }) {
    return PlanEventsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      planId: planId ?? this.planId,
      memberId: memberId ?? this.memberId,
      title: title ?? this.title,
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      status: status ?? this.status,
      doneDate: doneDate ?? this.doneDate,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (doneDate.present) {
      map['done_date'] = Variable<String>(doneDate.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanEventsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('memberId: $memberId, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('day: $day, ')
          ..write('status: $status, ')
          ..write('doneDate: $doneDate, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanRatesTable extends PlanRates
    with TableInfo<$PlanRatesTable, PlanRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annualRateMeta = const VerificationMeta(
    'annualRate',
  );
  @override
  late final GeneratedColumn<double> annualRate = GeneratedColumn<double>(
    'annual_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    targetType,
    targetId,
    annualRate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_rate';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanRateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('annual_rate')) {
      context.handle(
        _annualRateMeta,
        annualRate.isAcceptableOrUnknown(data['annual_rate']!, _annualRateMeta),
      );
    } else if (isInserting) {
      context.missing(_annualRateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      annualRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}annual_rate'],
      )!,
    );
  }

  @override
  $PlanRatesTable createAlias(String alias) {
    return $PlanRatesTable(attachedDatabase, alias);
  }
}

class PlanRateRow extends DataClass implements Insertable<PlanRateRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String planId;

  /// account / asset / category
  final String targetType;
  final String targetId;
  final double annualRate;
  const PlanRateRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.planId,
    required this.targetType,
    required this.targetId,
    required this.annualRate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['plan_id'] = Variable<String>(planId);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    map['annual_rate'] = Variable<double>(annualRate);
    return map;
  }

  PlanRatesCompanion toCompanion(bool nullToAbsent) {
    return PlanRatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      planId: Value(planId),
      targetType: Value(targetType),
      targetId: Value(targetId),
      annualRate: Value(annualRate),
    );
  }

  factory PlanRateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRateRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      planId: serializer.fromJson<String>(json['planId']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      annualRate: serializer.fromJson<double>(json['annualRate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'planId': serializer.toJson<String>(planId),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'annualRate': serializer.toJson<double>(annualRate),
    };
  }

  PlanRateRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? planId,
    String? targetType,
    String? targetId,
    double? annualRate,
  }) => PlanRateRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    planId: planId ?? this.planId,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    annualRate: annualRate ?? this.annualRate,
  );
  PlanRateRow copyWithCompanion(PlanRatesCompanion data) {
    return PlanRateRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      planId: data.planId.present ? data.planId.value : this.planId,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      annualRate: data.annualRate.present
          ? data.annualRate.value
          : this.annualRate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRateRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('annualRate: $annualRate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    targetType,
    targetId,
    annualRate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRateRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.planId == this.planId &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.annualRate == this.annualRate);
}

class PlanRatesCompanion extends UpdateCompanion<PlanRateRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> planId;
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<double> annualRate;
  final Value<int> rowid;
  const PlanRatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.planId = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.annualRate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanRatesCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String planId,
    required String targetType,
    required String targetId,
    required double annualRate,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       planId = Value(planId),
       targetType = Value(targetType),
       targetId = Value(targetId),
       annualRate = Value(annualRate);
  static Insertable<PlanRateRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? planId,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<double>? annualRate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (planId != null) 'plan_id': planId,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (annualRate != null) 'annual_rate': annualRate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanRatesCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? planId,
    Value<String>? targetType,
    Value<String>? targetId,
    Value<double>? annualRate,
    Value<int>? rowid,
  }) {
    return PlanRatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      planId: planId ?? this.planId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      annualRate: annualRate ?? this.annualRate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (annualRate.present) {
      map['annual_rate'] = Variable<double>(annualRate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanRatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('annualRate: $annualRate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanBaselinesTable extends PlanBaselines
    with TableInfo<$PlanBaselinesTable, PlanBaselineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanBaselinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityX1e4Meta = const VerificationMeta(
    'quantityX1e4',
  );
  @override
  late final GeneratedColumn<int> quantityX1e4 = GeneratedColumn<int>(
    'quantity_x1e4',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceX100Meta = const VerificationMeta(
    'priceX100',
  );
  @override
  late final GeneratedColumn<int> priceX100 = GeneratedColumn<int>(
    'price_x100',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    targetType,
    targetId,
    balance,
    quantityX1e4,
    priceX100,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_baseline';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanBaselineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('quantity_x1e4')) {
      context.handle(
        _quantityX1e4Meta,
        quantityX1e4.isAcceptableOrUnknown(
          data['quantity_x1e4']!,
          _quantityX1e4Meta,
        ),
      );
    }
    if (data.containsKey('price_x100')) {
      context.handle(
        _priceX100Meta,
        priceX100.isAcceptableOrUnknown(data['price_x100']!, _priceX100Meta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanBaselineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanBaselineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance'],
      ),
      quantityX1e4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_x1e4'],
      ),
      priceX100: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_x100'],
      ),
    );
  }

  @override
  $PlanBaselinesTable createAlias(String alias) {
    return $PlanBaselinesTable(attachedDatabase, alias);
  }
}

class PlanBaselineRow extends DataClass implements Insertable<PlanBaselineRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String planId;
  final String targetType;
  final String targetId;
  final int? balance;
  final int? quantityX1e4;
  final int? priceX100;
  const PlanBaselineRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.planId,
    required this.targetType,
    required this.targetId,
    this.balance,
    this.quantityX1e4,
    this.priceX100,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['plan_id'] = Variable<String>(planId);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    if (!nullToAbsent || balance != null) {
      map['balance'] = Variable<int>(balance);
    }
    if (!nullToAbsent || quantityX1e4 != null) {
      map['quantity_x1e4'] = Variable<int>(quantityX1e4);
    }
    if (!nullToAbsent || priceX100 != null) {
      map['price_x100'] = Variable<int>(priceX100);
    }
    return map;
  }

  PlanBaselinesCompanion toCompanion(bool nullToAbsent) {
    return PlanBaselinesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      planId: Value(planId),
      targetType: Value(targetType),
      targetId: Value(targetId),
      balance: balance == null && nullToAbsent
          ? const Value.absent()
          : Value(balance),
      quantityX1e4: quantityX1e4 == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityX1e4),
      priceX100: priceX100 == null && nullToAbsent
          ? const Value.absent()
          : Value(priceX100),
    );
  }

  factory PlanBaselineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanBaselineRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      planId: serializer.fromJson<String>(json['planId']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      balance: serializer.fromJson<int?>(json['balance']),
      quantityX1e4: serializer.fromJson<int?>(json['quantityX1e4']),
      priceX100: serializer.fromJson<int?>(json['priceX100']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'planId': serializer.toJson<String>(planId),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'balance': serializer.toJson<int?>(balance),
      'quantityX1e4': serializer.toJson<int?>(quantityX1e4),
      'priceX100': serializer.toJson<int?>(priceX100),
    };
  }

  PlanBaselineRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? planId,
    String? targetType,
    String? targetId,
    Value<int?> balance = const Value.absent(),
    Value<int?> quantityX1e4 = const Value.absent(),
    Value<int?> priceX100 = const Value.absent(),
  }) => PlanBaselineRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    planId: planId ?? this.planId,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    balance: balance.present ? balance.value : this.balance,
    quantityX1e4: quantityX1e4.present ? quantityX1e4.value : this.quantityX1e4,
    priceX100: priceX100.present ? priceX100.value : this.priceX100,
  );
  PlanBaselineRow copyWithCompanion(PlanBaselinesCompanion data) {
    return PlanBaselineRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      planId: data.planId.present ? data.planId.value : this.planId,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      balance: data.balance.present ? data.balance.value : this.balance,
      quantityX1e4: data.quantityX1e4.present
          ? data.quantityX1e4.value
          : this.quantityX1e4,
      priceX100: data.priceX100.present ? data.priceX100.value : this.priceX100,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanBaselineRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('balance: $balance, ')
          ..write('quantityX1e4: $quantityX1e4, ')
          ..write('priceX100: $priceX100')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    targetType,
    targetId,
    balance,
    quantityX1e4,
    priceX100,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanBaselineRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.planId == this.planId &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.balance == this.balance &&
          other.quantityX1e4 == this.quantityX1e4 &&
          other.priceX100 == this.priceX100);
}

class PlanBaselinesCompanion extends UpdateCompanion<PlanBaselineRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> planId;
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<int?> balance;
  final Value<int?> quantityX1e4;
  final Value<int?> priceX100;
  final Value<int> rowid;
  const PlanBaselinesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.planId = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.balance = const Value.absent(),
    this.quantityX1e4 = const Value.absent(),
    this.priceX100 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanBaselinesCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String planId,
    required String targetType,
    required String targetId,
    this.balance = const Value.absent(),
    this.quantityX1e4 = const Value.absent(),
    this.priceX100 = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       planId = Value(planId),
       targetType = Value(targetType),
       targetId = Value(targetId);
  static Insertable<PlanBaselineRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? planId,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<int>? balance,
    Expression<int>? quantityX1e4,
    Expression<int>? priceX100,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (planId != null) 'plan_id': planId,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (balance != null) 'balance': balance,
      if (quantityX1e4 != null) 'quantity_x1e4': quantityX1e4,
      if (priceX100 != null) 'price_x100': priceX100,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanBaselinesCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? planId,
    Value<String>? targetType,
    Value<String>? targetId,
    Value<int?>? balance,
    Value<int?>? quantityX1e4,
    Value<int?>? priceX100,
    Value<int>? rowid,
  }) {
    return PlanBaselinesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      planId: planId ?? this.planId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      balance: balance ?? this.balance,
      quantityX1e4: quantityX1e4 ?? this.quantityX1e4,
      priceX100: priceX100 ?? this.priceX100,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (quantityX1e4.present) {
      map['quantity_x1e4'] = Variable<int>(quantityX1e4.value);
    }
    if (priceX100.present) {
      map['price_x100'] = Variable<int>(priceX100.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanBaselinesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('balance: $balance, ')
          ..write('quantityX1e4: $quantityX1e4, ')
          ..write('priceX100: $priceX100, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanGroupsTable extends PlanGroups
    with TableInfo<$PlanGroupsTable, PlanGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startYmMeta = const VerificationMeta(
    'startYm',
  );
  @override
  late final GeneratedColumn<String> startYm = GeneratedColumn<String>(
    'start_ym',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endYmMeta = const VerificationMeta('endYm');
  @override
  late final GeneratedColumn<String> endYm = GeneratedColumn<String>(
    'end_ym',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    groupId,
    startYm,
    endYm,
    memo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_group';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('start_ym')) {
      context.handle(
        _startYmMeta,
        startYm.isAcceptableOrUnknown(data['start_ym']!, _startYmMeta),
      );
    } else if (isInserting) {
      context.missing(_startYmMeta);
    }
    if (data.containsKey('end_ym')) {
      context.handle(
        _endYmMeta,
        endYm.isAcceptableOrUnknown(data['end_ym']!, _endYmMeta),
      );
    } else if (isInserting) {
      context.missing(_endYmMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      startYm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_ym'],
      )!,
      endYm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_ym'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
    );
  }

  @override
  $PlanGroupsTable createAlias(String alias) {
    return $PlanGroupsTable(attachedDatabase, alias);
  }
}

class PlanGroupRow extends DataClass implements Insertable<PlanGroupRow> {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String updatedBy;
  final String? deletedAt;
  final String planId;
  final String groupId;
  final String startYm;
  final String endYm;
  final String? memo;
  const PlanGroupRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.planId,
    required this.groupId,
    required this.startYm,
    required this.endYm,
    this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['plan_id'] = Variable<String>(planId);
    map['group_id'] = Variable<String>(groupId);
    map['start_ym'] = Variable<String>(startYm);
    map['end_ym'] = Variable<String>(endYm);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  PlanGroupsCompanion toCompanion(bool nullToAbsent) {
    return PlanGroupsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      planId: Value(planId),
      groupId: Value(groupId),
      startYm: Value(startYm),
      endYm: Value(endYm),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory PlanGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanGroupRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      planId: serializer.fromJson<String>(json['planId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      startYm: serializer.fromJson<String>(json['startYm']),
      endYm: serializer.fromJson<String>(json['endYm']),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'planId': serializer.toJson<String>(planId),
      'groupId': serializer.toJson<String>(groupId),
      'startYm': serializer.toJson<String>(startYm),
      'endYm': serializer.toJson<String>(endYm),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  PlanGroupRow copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? updatedBy,
    Value<String?> deletedAt = const Value.absent(),
    String? planId,
    String? groupId,
    String? startYm,
    String? endYm,
    Value<String?> memo = const Value.absent(),
  }) => PlanGroupRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    planId: planId ?? this.planId,
    groupId: groupId ?? this.groupId,
    startYm: startYm ?? this.startYm,
    endYm: endYm ?? this.endYm,
    memo: memo.present ? memo.value : this.memo,
  );
  PlanGroupRow copyWithCompanion(PlanGroupsCompanion data) {
    return PlanGroupRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      planId: data.planId.present ? data.planId.value : this.planId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      startYm: data.startYm.present ? data.startYm.value : this.startYm,
      endYm: data.endYm.present ? data.endYm.value : this.endYm,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanGroupRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('groupId: $groupId, ')
          ..write('startYm: $startYm, ')
          ..write('endYm: $endYm, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    updatedBy,
    deletedAt,
    planId,
    groupId,
    startYm,
    endYm,
    memo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanGroupRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.planId == this.planId &&
          other.groupId == this.groupId &&
          other.startYm == this.startYm &&
          other.endYm == this.endYm &&
          other.memo == this.memo);
}

class PlanGroupsCompanion extends UpdateCompanion<PlanGroupRow> {
  final Value<String> id;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> updatedBy;
  final Value<String?> deletedAt;
  final Value<String> planId;
  final Value<String> groupId;
  final Value<String> startYm;
  final Value<String> endYm;
  final Value<String?> memo;
  final Value<int> rowid;
  const PlanGroupsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.planId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.startYm = const Value.absent(),
    this.endYm = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanGroupsCompanion.insert({
    required String id,
    required String createdAt,
    required String updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required String planId,
    required String groupId,
    required String startYm,
    required String endYm,
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       planId = Value(planId),
       groupId = Value(groupId),
       startYm = Value(startYm),
       endYm = Value(endYm);
  static Insertable<PlanGroupRow> custom({
    Expression<String>? id,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? deletedAt,
    Expression<String>? planId,
    Expression<String>? groupId,
    Expression<String>? startYm,
    Expression<String>? endYm,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (planId != null) 'plan_id': planId,
      if (groupId != null) 'group_id': groupId,
      if (startYm != null) 'start_ym': startYm,
      if (endYm != null) 'end_ym': endYm,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? updatedBy,
    Value<String?>? deletedAt,
    Value<String>? planId,
    Value<String>? groupId,
    Value<String>? startYm,
    Value<String>? endYm,
    Value<String?>? memo,
    Value<int>? rowid,
  }) {
    return PlanGroupsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      planId: planId ?? this.planId,
      groupId: groupId ?? this.groupId,
      startYm: startYm ?? this.startYm,
      endYm: endYm ?? this.endYm,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (startYm.present) {
      map['start_ym'] = Variable<String>(startYm.value);
    }
    if (endYm.present) {
      map['end_ym'] = Variable<String>(endYm.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanGroupsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('planId: $planId, ')
          ..write('groupId: $groupId, ')
          ..write('startYm: $startYm, ')
          ..write('endYm: $endYm, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceSettingsTable extends DeviceSettings
    with TableInfo<$DeviceSettingsTable, DeviceSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedPlanIdMeta = const VerificationMeta(
    'selectedPlanId',
  );
  @override
  late final GeneratedColumn<String> selectedPlanId = GeneratedColumn<String>(
    'selected_plan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _redisHostMeta = const VerificationMeta(
    'redisHost',
  );
  @override
  late final GeneratedColumn<String> redisHost = GeneratedColumn<String>(
    'redis_host',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _redisPortMeta = const VerificationMeta(
    'redisPort',
  );
  @override
  late final GeneratedColumn<int> redisPort = GeneratedColumn<int>(
    'redis_port',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<String> lastSyncAt = GeneratedColumn<String>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    selectedPlanId,
    redisHost,
    redisPort,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_setting';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('selected_plan_id')) {
      context.handle(
        _selectedPlanIdMeta,
        selectedPlanId.isAcceptableOrUnknown(
          data['selected_plan_id']!,
          _selectedPlanIdMeta,
        ),
      );
    }
    if (data.containsKey('redis_host')) {
      context.handle(
        _redisHostMeta,
        redisHost.isAcceptableOrUnknown(data['redis_host']!, _redisHostMeta),
      );
    }
    if (data.containsKey('redis_port')) {
      context.handle(
        _redisPortMeta,
        redisPort.isAcceptableOrUnknown(data['redis_port']!, _redisPortMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  DeviceSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceSettingRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      selectedPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_plan_id'],
      ),
      redisHost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}redis_host'],
      ),
      redisPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}redis_port'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $DeviceSettingsTable createAlias(String alias) {
    return $DeviceSettingsTable(attachedDatabase, alias);
  }
}

class DeviceSettingRow extends DataClass
    implements Insertable<DeviceSettingRow> {
  final String deviceId;
  final String? selectedPlanId;
  final String? redisHost;
  final int? redisPort;
  final String? lastSyncAt;
  const DeviceSettingRow({
    required this.deviceId,
    this.selectedPlanId,
    this.redisHost,
    this.redisPort,
    this.lastSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || selectedPlanId != null) {
      map['selected_plan_id'] = Variable<String>(selectedPlanId);
    }
    if (!nullToAbsent || redisHost != null) {
      map['redis_host'] = Variable<String>(redisHost);
    }
    if (!nullToAbsent || redisPort != null) {
      map['redis_port'] = Variable<int>(redisPort);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<String>(lastSyncAt);
    }
    return map;
  }

  DeviceSettingsCompanion toCompanion(bool nullToAbsent) {
    return DeviceSettingsCompanion(
      deviceId: Value(deviceId),
      selectedPlanId: selectedPlanId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedPlanId),
      redisHost: redisHost == null && nullToAbsent
          ? const Value.absent()
          : Value(redisHost),
      redisPort: redisPort == null && nullToAbsent
          ? const Value.absent()
          : Value(redisPort),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory DeviceSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceSettingRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      selectedPlanId: serializer.fromJson<String?>(json['selectedPlanId']),
      redisHost: serializer.fromJson<String?>(json['redisHost']),
      redisPort: serializer.fromJson<int?>(json['redisPort']),
      lastSyncAt: serializer.fromJson<String?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'selectedPlanId': serializer.toJson<String?>(selectedPlanId),
      'redisHost': serializer.toJson<String?>(redisHost),
      'redisPort': serializer.toJson<int?>(redisPort),
      'lastSyncAt': serializer.toJson<String?>(lastSyncAt),
    };
  }

  DeviceSettingRow copyWith({
    String? deviceId,
    Value<String?> selectedPlanId = const Value.absent(),
    Value<String?> redisHost = const Value.absent(),
    Value<int?> redisPort = const Value.absent(),
    Value<String?> lastSyncAt = const Value.absent(),
  }) => DeviceSettingRow(
    deviceId: deviceId ?? this.deviceId,
    selectedPlanId: selectedPlanId.present
        ? selectedPlanId.value
        : this.selectedPlanId,
    redisHost: redisHost.present ? redisHost.value : this.redisHost,
    redisPort: redisPort.present ? redisPort.value : this.redisPort,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  DeviceSettingRow copyWithCompanion(DeviceSettingsCompanion data) {
    return DeviceSettingRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      selectedPlanId: data.selectedPlanId.present
          ? data.selectedPlanId.value
          : this.selectedPlanId,
      redisHost: data.redisHost.present ? data.redisHost.value : this.redisHost,
      redisPort: data.redisPort.present ? data.redisPort.value : this.redisPort,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceSettingRow(')
          ..write('deviceId: $deviceId, ')
          ..write('selectedPlanId: $selectedPlanId, ')
          ..write('redisHost: $redisHost, ')
          ..write('redisPort: $redisPort, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(deviceId, selectedPlanId, redisHost, redisPort, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceSettingRow &&
          other.deviceId == this.deviceId &&
          other.selectedPlanId == this.selectedPlanId &&
          other.redisHost == this.redisHost &&
          other.redisPort == this.redisPort &&
          other.lastSyncAt == this.lastSyncAt);
}

class DeviceSettingsCompanion extends UpdateCompanion<DeviceSettingRow> {
  final Value<String> deviceId;
  final Value<String?> selectedPlanId;
  final Value<String?> redisHost;
  final Value<int?> redisPort;
  final Value<String?> lastSyncAt;
  final Value<int> rowid;
  const DeviceSettingsCompanion({
    this.deviceId = const Value.absent(),
    this.selectedPlanId = const Value.absent(),
    this.redisHost = const Value.absent(),
    this.redisPort = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceSettingsCompanion.insert({
    required String deviceId,
    this.selectedPlanId = const Value.absent(),
    this.redisHost = const Value.absent(),
    this.redisPort = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId);
  static Insertable<DeviceSettingRow> custom({
    Expression<String>? deviceId,
    Expression<String>? selectedPlanId,
    Expression<String>? redisHost,
    Expression<int>? redisPort,
    Expression<String>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (selectedPlanId != null) 'selected_plan_id': selectedPlanId,
      if (redisHost != null) 'redis_host': redisHost,
      if (redisPort != null) 'redis_port': redisPort,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceSettingsCompanion copyWith({
    Value<String>? deviceId,
    Value<String?>? selectedPlanId,
    Value<String?>? redisHost,
    Value<int?>? redisPort,
    Value<String?>? lastSyncAt,
    Value<int>? rowid,
  }) {
    return DeviceSettingsCompanion(
      deviceId: deviceId ?? this.deviceId,
      selectedPlanId: selectedPlanId ?? this.selectedPlanId,
      redisHost: redisHost ?? this.redisHost,
      redisPort: redisPort ?? this.redisPort,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (selectedPlanId.present) {
      map['selected_plan_id'] = Variable<String>(selectedPlanId.value);
    }
    if (redisHost.present) {
      map['redis_host'] = Variable<String>(redisHost.value);
    }
    if (redisPort.present) {
      map['redis_port'] = Variable<int>(redisPort.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<String>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceSettingsCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('selectedPlanId: $selectedPlanId, ')
          ..write('redisHost: $redisHost, ')
          ..write('redisPort: $redisPort, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryRulesTable extends CategoryRules
    with TableInfo<$CategoryRulesTable, CategoryRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, content, categoryId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_rule';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, content};
  @override
  CategoryRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRuleRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoryRulesTable createAlias(String alias) {
    return $CategoryRulesTable(attachedDatabase, alias);
  }
}

class CategoryRuleRow extends DataClass implements Insertable<CategoryRuleRow> {
  /// income / expense
  final String kind;

  /// 明細の内容（店名・商品名）。読み取ったままの文字列
  final String content;
  final String categoryId;
  final String updatedAt;
  const CategoryRuleRow({
    required this.kind,
    required this.content,
    required this.categoryId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['content'] = Variable<String>(content);
    map['category_id'] = Variable<String>(categoryId);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CategoryRulesCompanion toCompanion(bool nullToAbsent) {
    return CategoryRulesCompanion(
      kind: Value(kind),
      content: Value(content),
      categoryId: Value(categoryId),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRuleRow(
      kind: serializer.fromJson<String>(json['kind']),
      content: serializer.fromJson<String>(json['content']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'content': serializer.toJson<String>(content),
      'categoryId': serializer.toJson<String>(categoryId),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  CategoryRuleRow copyWith({
    String? kind,
    String? content,
    String? categoryId,
    String? updatedAt,
  }) => CategoryRuleRow(
    kind: kind ?? this.kind,
    content: content ?? this.content,
    categoryId: categoryId ?? this.categoryId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryRuleRow copyWithCompanion(CategoryRulesCompanion data) {
    return CategoryRuleRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      content: data.content.present ? data.content.value : this.content,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRuleRow(')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('categoryId: $categoryId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, content, categoryId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRuleRow &&
          other.kind == this.kind &&
          other.content == this.content &&
          other.categoryId == this.categoryId &&
          other.updatedAt == this.updatedAt);
}

class CategoryRulesCompanion extends UpdateCompanion<CategoryRuleRow> {
  final Value<String> kind;
  final Value<String> content;
  final Value<String> categoryId;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CategoryRulesCompanion({
    this.kind = const Value.absent(),
    this.content = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryRulesCompanion.insert({
    required String kind,
    required String content,
    required String categoryId,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       content = Value(content),
       categoryId = Value(categoryId),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryRuleRow> custom({
    Expression<String>? kind,
    Expression<String>? content,
    Expression<String>? categoryId,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (content != null) 'content': content,
      if (categoryId != null) 'category_id': categoryId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryRulesCompanion copyWith({
    Value<String>? kind,
    Value<String>? content,
    Value<String>? categoryId,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoryRulesCompanion(
      kind: kind ?? this.kind,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRulesCompanion(')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('categoryId: $categoryId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicePrefsTable extends DevicePrefs
    with TableInfo<$DevicePrefsTable, DevicePrefRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicePrefsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'device_pref';
  @override
  VerificationContext validateIntegrity(
    Insertable<DevicePrefRow> instance, {
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
  DevicePrefRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DevicePrefRow(
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
  $DevicePrefsTable createAlias(String alias) {
    return $DevicePrefsTable(attachedDatabase, alias);
  }
}

class DevicePrefRow extends DataClass implements Insertable<DevicePrefRow> {
  final String key;
  final String value;
  const DevicePrefRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  DevicePrefsCompanion toCompanion(bool nullToAbsent) {
    return DevicePrefsCompanion(key: Value(key), value: Value(value));
  }

  factory DevicePrefRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DevicePrefRow(
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

  DevicePrefRow copyWith({String? key, String? value}) =>
      DevicePrefRow(key: key ?? this.key, value: value ?? this.value);
  DevicePrefRow copyWithCompanion(DevicePrefsCompanion data) {
    return DevicePrefRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DevicePrefRow(')
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
      (other is DevicePrefRow &&
          other.key == this.key &&
          other.value == this.value);
}

class DevicePrefsCompanion extends UpdateCompanion<DevicePrefRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const DevicePrefsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicePrefsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<DevicePrefRow> custom({
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

  DevicePrefsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return DevicePrefsCompanion(
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
    return (StringBuffer('DevicePrefsCompanion(')
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
  late final $HouseholdTable household = $HouseholdTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TxnsTable txns = $TxnsTable(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $AssetValuesTable assetValues = $AssetValuesTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $TemplateGroupsTable templateGroups = $TemplateGroupsTable(this);
  late final $TemplateGroupItemsTable templateGroupItems =
      $TemplateGroupItemsTable(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $FamilyMembersTable familyMembers = $FamilyMembersTable(this);
  late final $PlanLinesTable planLines = $PlanLinesTable(this);
  late final $PlanEventsTable planEvents = $PlanEventsTable(this);
  late final $PlanRatesTable planRates = $PlanRatesTable(this);
  late final $PlanBaselinesTable planBaselines = $PlanBaselinesTable(this);
  late final $PlanGroupsTable planGroups = $PlanGroupsTable(this);
  late final $DeviceSettingsTable deviceSettings = $DeviceSettingsTable(this);
  late final $CategoryRulesTable categoryRules = $CategoryRulesTable(this);
  late final $DevicePrefsTable devicePrefs = $DevicePrefsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    household,
    accounts,
    categories,
    txns,
    assets,
    assetValues,
    templates,
    templateGroups,
    templateGroupItems,
    plans,
    familyMembers,
    planLines,
    planEvents,
    planRates,
    planBaselines,
    planGroups,
    deviceSettings,
    categoryRules,
    devicePrefs,
  ];
}

typedef $$HouseholdTableCreateCompanionBuilder = HouseholdCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required int schemaVersion,
  Value<int> rowid,
});
typedef $$HouseholdTableUpdateCompanionBuilder = HouseholdCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<int> schemaVersion,
  Value<int> rowid,
});

class $$HouseholdTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdTable> {
  $$HouseholdTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HouseholdTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdTable> {
  $$HouseholdTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HouseholdTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdTable> {
  $$HouseholdTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );
}

class $$HouseholdTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HouseholdTable,
          HouseholdRow,
          $$HouseholdTableFilterComposer,
          $$HouseholdTableOrderingComposer,
          $$HouseholdTableAnnotationComposer,
          $$HouseholdTableCreateCompanionBuilder,
          $$HouseholdTableUpdateCompanionBuilder,
          (
            HouseholdRow,
            BaseReferences<_$AppDatabase, $HouseholdTable, HouseholdRow>,
          ),
          HouseholdRow,
          PrefetchHooks Function()
        > {
  $$HouseholdTableTableManager(_$AppDatabase db, $HouseholdTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => HouseholdCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HouseholdTable, HouseholdRow>(table),
                  BaseReferences<_$AppDatabase, $HouseholdTable, HouseholdRow>(
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

typedef $$HouseholdTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HouseholdTable,
      HouseholdRow,
      $$HouseholdTableFilterComposer,
      $$HouseholdTableOrderingComposer,
      $$HouseholdTableAnnotationComposer,
      $$HouseholdTableCreateCompanionBuilder,
      $$HouseholdTableUpdateCompanionBuilder,
      (
        HouseholdRow,
        BaseReferences<_$AppDatabase, $HouseholdTable, HouseholdRow>,
      ),
      HouseholdRow,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required String name,
  required String kind,
  required int initialBalance,
  required String initialDate,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<String> name,
  Value<String> kind,
  Value<int> initialBalance,
  Value<String> initialDate,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initialDate => $composableBuilder(
    column: $table.initialDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initialDate => $composableBuilder(
    column: $table.initialDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get initialDate => $composableBuilder(
    column: $table.initialDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (
            AccountRow,
            BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>,
          ),
          AccountRow,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> initialBalance = const Value.absent(),
                Value<String> initialDate = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                name: name,
                kind: kind,
                initialBalance: initialBalance,
                initialDate: initialDate,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String name,
                required String kind,
                required int initialBalance,
                required String initialDate,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                name: name,
                kind: kind,
                initialBalance: initialBalance,
                initialDate: initialDate,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, AccountRow>(table),
                  BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>(
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

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>),
      AccountRow,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required String name,
  required String kind,
  required String color,
  Value<String?> defaultValuation,
  Value<int?> saleTaxDefault,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<String> name,
  Value<String> kind,
  Value<String> color,
  Value<String?> defaultValuation,
  Value<int?> saleTaxDefault,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultValuation => $composableBuilder(
    column: $table.defaultValuation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saleTaxDefault => $composableBuilder(
    column: $table.saleTaxDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultValuation => $composableBuilder(
    column: $table.defaultValuation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saleTaxDefault => $composableBuilder(
    column: $table.saleTaxDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get defaultValuation => $composableBuilder(
    column: $table.defaultValuation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get saleTaxDefault => $composableBuilder(
    column: $table.saleTaxDefault,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> defaultValuation = const Value.absent(),
                Value<int?> saleTaxDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                name: name,
                kind: kind,
                color: color,
                defaultValuation: defaultValuation,
                saleTaxDefault: saleTaxDefault,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String name,
                required String kind,
                required String color,
                Value<String?> defaultValuation = const Value.absent(),
                Value<int?> saleTaxDefault = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                name: name,
                kind: kind,
                color: color,
                defaultValuation: defaultValuation,
                saleTaxDefault: saleTaxDefault,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>(
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

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$TxnsTableCreateCompanionBuilder = TxnsCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required String planId,
  required String date,
  required String kind,
  required int amount,
  Value<String?> categoryId,
  required String accountId,
  Value<String?> toAccountId,
  Value<String?> assetId,
  Value<String?> assetAction,
  Value<int?> quantityX1e4,
  Value<String?> eventId,
  Value<String?> parentTxnId,
  Value<String?> memo,
  Value<String?> groupId,
  Value<String?> groupItemId,
  Value<String?> entryId,
  Value<int> rowid,
});
typedef $$TxnsTableUpdateCompanionBuilder = TxnsCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<String> planId,
  Value<String> date,
  Value<String> kind,
  Value<int> amount,
  Value<String?> categoryId,
  Value<String> accountId,
  Value<String?> toAccountId,
  Value<String?> assetId,
  Value<String?> assetAction,
  Value<int?> quantityX1e4,
  Value<String?> eventId,
  Value<String?> parentTxnId,
  Value<String?> memo,
  Value<String?> groupId,
  Value<String?> groupItemId,
  Value<String?> entryId,
  Value<int> rowid,
});

class $$TxnsTableFilterComposer extends Composer<_$AppDatabase, $TxnsTable> {
  $$TxnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetAction => $composableBuilder(
    column: $table.assetAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentTxnId => $composableBuilder(
    column: $table.parentTxnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupItemId => $composableBuilder(
    column: $table.groupItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TxnsTableOrderingComposer extends Composer<_$AppDatabase, $TxnsTable> {
  $$TxnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetAction => $composableBuilder(
    column: $table.assetAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentTxnId => $composableBuilder(
    column: $table.parentTxnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupItemId => $composableBuilder(
    column: $table.groupItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TxnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TxnsTable> {
  $$TxnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get assetAction => $composableBuilder(
    column: $table.assetAction,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get parentTxnId => $composableBuilder(
    column: $table.parentTxnId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get groupItemId => $composableBuilder(
    column: $table.groupItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);
}

class $$TxnsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TxnsTable,
          TxnRow,
          $$TxnsTableFilterComposer,
          $$TxnsTableOrderingComposer,
          $$TxnsTableAnnotationComposer,
          $$TxnsTableCreateCompanionBuilder,
          $$TxnsTableUpdateCompanionBuilder,
          (TxnRow, BaseReferences<_$AppDatabase, $TxnsTable, TxnRow>),
          TxnRow,
          PrefetchHooks Function()
        > {
  $$TxnsTableTableManager(_$AppDatabase db, $TxnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TxnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TxnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TxnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<String?> assetAction = const Value.absent(),
                Value<int?> quantityX1e4 = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<String?> parentTxnId = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> groupItemId = const Value.absent(),
                Value<String?> entryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TxnsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                date: date,
                kind: kind,
                amount: amount,
                categoryId: categoryId,
                accountId: accountId,
                toAccountId: toAccountId,
                assetId: assetId,
                assetAction: assetAction,
                quantityX1e4: quantityX1e4,
                eventId: eventId,
                parentTxnId: parentTxnId,
                memo: memo,
                groupId: groupId,
                groupItemId: groupItemId,
                entryId: entryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String planId,
                required String date,
                required String kind,
                required int amount,
                Value<String?> categoryId = const Value.absent(),
                required String accountId,
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<String?> assetAction = const Value.absent(),
                Value<int?> quantityX1e4 = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<String?> parentTxnId = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> groupItemId = const Value.absent(),
                Value<String?> entryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TxnsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                date: date,
                kind: kind,
                amount: amount,
                categoryId: categoryId,
                accountId: accountId,
                toAccountId: toAccountId,
                assetId: assetId,
                assetAction: assetAction,
                quantityX1e4: quantityX1e4,
                eventId: eventId,
                parentTxnId: parentTxnId,
                memo: memo,
                groupId: groupId,
                groupItemId: groupItemId,
                entryId: entryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TxnsTable, TxnRow>(table),
                  BaseReferences<_$AppDatabase, $TxnsTable, TxnRow>(
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

typedef $$TxnsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TxnsTable,
      TxnRow,
      $$TxnsTableFilterComposer,
      $$TxnsTableOrderingComposer,
      $$TxnsTableAnnotationComposer,
      $$TxnsTableCreateCompanionBuilder,
      $$TxnsTableUpdateCompanionBuilder,
      (TxnRow, BaseReferences<_$AppDatabase, $TxnsTable, TxnRow>),
      TxnRow,
      PrefetchHooks Function()
    >;
typedef $$AssetsTableCreateCompanionBuilder = AssetsCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required String planId,
  required String name,
  required String categoryId,
  required String valuation,
  Value<String?> code,
  Value<String?> accountId,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$AssetsTableUpdateCompanionBuilder = AssetsCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<String> planId,
  Value<String> name,
  Value<String> categoryId,
  Value<String> valuation,
  Value<String?> code,
  Value<String?> accountId,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$AssetsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valuation => $composableBuilder(
    column: $table.valuation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valuation => $composableBuilder(
    column: $table.valuation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valuation =>
      $composableBuilder(column: $table.valuation, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetsTable,
          AssetRow,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (AssetRow, BaseReferences<_$AppDatabase, $AssetsTable, AssetRow>),
          AssetRow,
          PrefetchHooks Function()
        > {
  $$AssetsTableTableManager(_$AppDatabase db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> valuation = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                name: name,
                categoryId: categoryId,
                valuation: valuation,
                code: code,
                accountId: accountId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String planId,
                required String name,
                required String categoryId,
                required String valuation,
                Value<String?> code = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                name: name,
                categoryId: categoryId,
                valuation: valuation,
                code: code,
                accountId: accountId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetsTable, AssetRow>(table),
                  BaseReferences<_$AppDatabase, $AssetsTable, AssetRow>(
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

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetsTable,
      AssetRow,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (AssetRow, BaseReferences<_$AppDatabase, $AssetsTable, AssetRow>),
      AssetRow,
      PrefetchHooks Function()
    >;
typedef $$AssetValuesTableCreateCompanionBuilder =
    AssetValuesCompanion Function({
      required String id,
      required String createdAt,
      required String updatedAt,
      required String updatedBy,
      Value<String?> deletedAt,
      required String assetId,
      required String unit,
      required String valueDate,
      required int valueX100,
      Value<int> rowid,
    });
typedef $$AssetValuesTableUpdateCompanionBuilder =
    AssetValuesCompanion Function({
      Value<String> id,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String> updatedBy,
      Value<String?> deletedAt,
      Value<String> assetId,
      Value<String> unit,
      Value<String> valueDate,
      Value<int> valueX100,
      Value<int> rowid,
    });

class $$AssetValuesTableFilterComposer
    extends Composer<_$AppDatabase, $AssetValuesTable> {
  $$AssetValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueDate => $composableBuilder(
    column: $table.valueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valueX100 => $composableBuilder(
    column: $table.valueX100,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssetValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetValuesTable> {
  $$AssetValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueDate => $composableBuilder(
    column: $table.valueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valueX100 => $composableBuilder(
    column: $table.valueX100,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetValuesTable> {
  $$AssetValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get valueDate =>
      $composableBuilder(column: $table.valueDate, builder: (column) => column);

  GeneratedColumn<int> get valueX100 =>
      $composableBuilder(column: $table.valueX100, builder: (column) => column);
}

class $$AssetValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetValuesTable,
          AssetValueRow,
          $$AssetValuesTableFilterComposer,
          $$AssetValuesTableOrderingComposer,
          $$AssetValuesTableAnnotationComposer,
          $$AssetValuesTableCreateCompanionBuilder,
          $$AssetValuesTableUpdateCompanionBuilder,
          (
            AssetValueRow,
            BaseReferences<_$AppDatabase, $AssetValuesTable, AssetValueRow>,
          ),
          AssetValueRow,
          PrefetchHooks Function()
        > {
  $$AssetValuesTableTableManager(_$AppDatabase db, $AssetValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> valueDate = const Value.absent(),
                Value<int> valueX100 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetValuesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                assetId: assetId,
                unit: unit,
                valueDate: valueDate,
                valueX100: valueX100,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String assetId,
                required String unit,
                required String valueDate,
                required int valueX100,
                Value<int> rowid = const Value.absent(),
              }) => AssetValuesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                assetId: assetId,
                unit: unit,
                valueDate: valueDate,
                valueX100: valueX100,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetValuesTable, AssetValueRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AssetValuesTable,
                    AssetValueRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssetValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetValuesTable,
      AssetValueRow,
      $$AssetValuesTableFilterComposer,
      $$AssetValuesTableOrderingComposer,
      $$AssetValuesTableAnnotationComposer,
      $$AssetValuesTableCreateCompanionBuilder,
      $$AssetValuesTableUpdateCompanionBuilder,
      (
        AssetValueRow,
        BaseReferences<_$AppDatabase, $AssetValuesTable, AssetValueRow>,
      ),
      AssetValueRow,
      PrefetchHooks Function()
    >;
typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required String name,
  required String kind,
  Value<int?> amount,
  Value<int?> quantityX1e4,
  Value<String?> categoryId,
  Value<String?> accountId,
  Value<String?> toAccountId,
  Value<String?> assetId,
  Value<String?> assetAction,
  Value<String?> memo,
  required String growthMode,
  Value<double?> growthRate,
  Value<int> rowid,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<String> name,
  Value<String> kind,
  Value<int?> amount,
  Value<int?> quantityX1e4,
  Value<String?> categoryId,
  Value<String?> accountId,
  Value<String?> toAccountId,
  Value<String?> assetId,
  Value<String?> assetAction,
  Value<String?> memo,
  Value<String> growthMode,
  Value<double?> growthRate,
  Value<int> rowid,
});

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetAction => $composableBuilder(
    column: $table.assetAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get growthMode => $composableBuilder(
    column: $table.growthMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get growthRate => $composableBuilder(
    column: $table.growthRate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetAction => $composableBuilder(
    column: $table.assetAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get growthMode => $composableBuilder(
    column: $table.growthMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get growthRate => $composableBuilder(
    column: $table.growthRate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get assetAction => $composableBuilder(
    column: $table.assetAction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get growthMode => $composableBuilder(
    column: $table.growthMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get growthRate => $composableBuilder(
    column: $table.growthRate,
    builder: (column) => column,
  );
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          TemplateRow,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (
            TemplateRow,
            BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow>,
          ),
          TemplateRow,
          PrefetchHooks Function()
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> amount = const Value.absent(),
                Value<int?> quantityX1e4 = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<String?> assetAction = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String> growthMode = const Value.absent(),
                Value<double?> growthRate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                name: name,
                kind: kind,
                amount: amount,
                quantityX1e4: quantityX1e4,
                categoryId: categoryId,
                accountId: accountId,
                toAccountId: toAccountId,
                assetId: assetId,
                assetAction: assetAction,
                memo: memo,
                growthMode: growthMode,
                growthRate: growthRate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String name,
                required String kind,
                Value<int?> amount = const Value.absent(),
                Value<int?> quantityX1e4 = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<String?> assetAction = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                required String growthMode,
                Value<double?> growthRate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                name: name,
                kind: kind,
                amount: amount,
                quantityX1e4: quantityX1e4,
                categoryId: categoryId,
                accountId: accountId,
                toAccountId: toAccountId,
                assetId: assetId,
                assetAction: assetAction,
                memo: memo,
                growthMode: growthMode,
                growthRate: growthRate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplatesTable, TemplateRow>(table),
                  BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow>(
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

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      TemplateRow,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (
        TemplateRow,
        BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow>,
      ),
      TemplateRow,
      PrefetchHooks Function()
    >;
typedef $$TemplateGroupsTableCreateCompanionBuilder =
    TemplateGroupsCompanion Function({
      required String id,
      required String createdAt,
      required String updatedAt,
      required String updatedBy,
      Value<String?> deletedAt,
      required String name,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$TemplateGroupsTableUpdateCompanionBuilder =
    TemplateGroupsCompanion Function({
      Value<String> id,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String> updatedBy,
      Value<String?> deletedAt,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$TemplateGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateGroupsTable> {
  $$TemplateGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TemplateGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateGroupsTable> {
  $$TemplateGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplateGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateGroupsTable> {
  $$TemplateGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$TemplateGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateGroupsTable,
          TemplateGroupRow,
          $$TemplateGroupsTableFilterComposer,
          $$TemplateGroupsTableOrderingComposer,
          $$TemplateGroupsTableAnnotationComposer,
          $$TemplateGroupsTableCreateCompanionBuilder,
          $$TemplateGroupsTableUpdateCompanionBuilder,
          (
            TemplateGroupRow,
            BaseReferences<
              _$AppDatabase,
              $TemplateGroupsTable,
              TemplateGroupRow
            >,
          ),
          TemplateGroupRow,
          PrefetchHooks Function()
        > {
  $$TemplateGroupsTableTableManager(
    _$AppDatabase db,
    $TemplateGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateGroupsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String name,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => TemplateGroupsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplateGroupsTable, TemplateGroupRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TemplateGroupsTable,
                    TemplateGroupRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TemplateGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateGroupsTable,
      TemplateGroupRow,
      $$TemplateGroupsTableFilterComposer,
      $$TemplateGroupsTableOrderingComposer,
      $$TemplateGroupsTableAnnotationComposer,
      $$TemplateGroupsTableCreateCompanionBuilder,
      $$TemplateGroupsTableUpdateCompanionBuilder,
      (
        TemplateGroupRow,
        BaseReferences<_$AppDatabase, $TemplateGroupsTable, TemplateGroupRow>,
      ),
      TemplateGroupRow,
      PrefetchHooks Function()
    >;
typedef $$TemplateGroupItemsTableCreateCompanionBuilder =
    TemplateGroupItemsCompanion Function({
      required String id,
      required String createdAt,
      required String updatedAt,
      required String updatedBy,
      Value<String?> deletedAt,
      required String groupId,
      required String templateId,
      required String amountMode,
      Value<String?> baseItemId,
      Value<double?> percent,
      Value<String?> frequency,
      Value<int?> intervalN,
      Value<int?> month,
      Value<int?> weekday,
      Value<String?> months,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$TemplateGroupItemsTableUpdateCompanionBuilder =
    TemplateGroupItemsCompanion Function({
      Value<String> id,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String> updatedBy,
      Value<String?> deletedAt,
      Value<String> groupId,
      Value<String> templateId,
      Value<String> amountMode,
      Value<String?> baseItemId,
      Value<double?> percent,
      Value<String?> frequency,
      Value<int?> intervalN,
      Value<int?> month,
      Value<int?> weekday,
      Value<String?> months,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$TemplateGroupItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateGroupItemsTable> {
  $$TemplateGroupItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amountMode => $composableBuilder(
    column: $table.amountMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseItemId => $composableBuilder(
    column: $table.baseItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalN => $composableBuilder(
    column: $table.intervalN,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get months => $composableBuilder(
    column: $table.months,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TemplateGroupItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateGroupItemsTable> {
  $$TemplateGroupItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountMode => $composableBuilder(
    column: $table.amountMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseItemId => $composableBuilder(
    column: $table.baseItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalN => $composableBuilder(
    column: $table.intervalN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get months => $composableBuilder(
    column: $table.months,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplateGroupItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateGroupItemsTable> {
  $$TemplateGroupItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get amountMode => $composableBuilder(
    column: $table.amountMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseItemId => $composableBuilder(
    column: $table.baseItemId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get percent =>
      $composableBuilder(column: $table.percent, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get intervalN =>
      $composableBuilder(column: $table.intervalN, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<String> get months =>
      $composableBuilder(column: $table.months, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$TemplateGroupItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateGroupItemsTable,
          TemplateGroupItemRow,
          $$TemplateGroupItemsTableFilterComposer,
          $$TemplateGroupItemsTableOrderingComposer,
          $$TemplateGroupItemsTableAnnotationComposer,
          $$TemplateGroupItemsTableCreateCompanionBuilder,
          $$TemplateGroupItemsTableUpdateCompanionBuilder,
          (
            TemplateGroupItemRow,
            BaseReferences<
              _$AppDatabase,
              $TemplateGroupItemsTable,
              TemplateGroupItemRow
            >,
          ),
          TemplateGroupItemRow,
          PrefetchHooks Function()
        > {
  $$TemplateGroupItemsTableTableManager(
    _$AppDatabase db,
    $TemplateGroupItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateGroupItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateGroupItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateGroupItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> amountMode = const Value.absent(),
                Value<String?> baseItemId = const Value.absent(),
                Value<double?> percent = const Value.absent(),
                Value<String?> frequency = const Value.absent(),
                Value<int?> intervalN = const Value.absent(),
                Value<int?> month = const Value.absent(),
                Value<int?> weekday = const Value.absent(),
                Value<String?> months = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateGroupItemsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                groupId: groupId,
                templateId: templateId,
                amountMode: amountMode,
                baseItemId: baseItemId,
                percent: percent,
                frequency: frequency,
                intervalN: intervalN,
                month: month,
                weekday: weekday,
                months: months,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String groupId,
                required String templateId,
                required String amountMode,
                Value<String?> baseItemId = const Value.absent(),
                Value<double?> percent = const Value.absent(),
                Value<String?> frequency = const Value.absent(),
                Value<int?> intervalN = const Value.absent(),
                Value<int?> month = const Value.absent(),
                Value<int?> weekday = const Value.absent(),
                Value<String?> months = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => TemplateGroupItemsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                groupId: groupId,
                templateId: templateId,
                amountMode: amountMode,
                baseItemId: baseItemId,
                percent: percent,
                frequency: frequency,
                intervalN: intervalN,
                month: month,
                weekday: weekday,
                months: months,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplateGroupItemsTable, TemplateGroupItemRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $TemplateGroupItemsTable,
                    TemplateGroupItemRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TemplateGroupItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateGroupItemsTable,
      TemplateGroupItemRow,
      $$TemplateGroupItemsTableFilterComposer,
      $$TemplateGroupItemsTableOrderingComposer,
      $$TemplateGroupItemsTableAnnotationComposer,
      $$TemplateGroupItemsTableCreateCompanionBuilder,
      $$TemplateGroupItemsTableUpdateCompanionBuilder,
      (
        TemplateGroupItemRow,
        BaseReferences<
          _$AppDatabase,
          $TemplateGroupItemsTable,
          TemplateGroupItemRow
        >,
      ),
      TemplateGroupItemRow,
      PrefetchHooks Function()
    >;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required String name,
  required String protagonistMemberId,
  required int startYear,
  required String baselineDate,
  required double defaultInflationRate,
  Value<String?> copiedFromPlanId,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<String> name,
  Value<String> protagonistMemberId,
  Value<int> startYear,
  Value<String> baselineDate,
  Value<double> defaultInflationRate,
  Value<String?> copiedFromPlanId,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protagonistMemberId => $composableBuilder(
    column: $table.protagonistMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startYear => $composableBuilder(
    column: $table.startYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baselineDate => $composableBuilder(
    column: $table.baselineDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultInflationRate => $composableBuilder(
    column: $table.defaultInflationRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get copiedFromPlanId => $composableBuilder(
    column: $table.copiedFromPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protagonistMemberId => $composableBuilder(
    column: $table.protagonistMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startYear => $composableBuilder(
    column: $table.startYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baselineDate => $composableBuilder(
    column: $table.baselineDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultInflationRate => $composableBuilder(
    column: $table.defaultInflationRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get copiedFromPlanId => $composableBuilder(
    column: $table.copiedFromPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get protagonistMemberId => $composableBuilder(
    column: $table.protagonistMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startYear =>
      $composableBuilder(column: $table.startYear, builder: (column) => column);

  GeneratedColumn<String> get baselineDate => $composableBuilder(
    column: $table.baselineDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get defaultInflationRate => $composableBuilder(
    column: $table.defaultInflationRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get copiedFromPlanId => $composableBuilder(
    column: $table.copiedFromPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$PlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlansTable,
          PlanRow,
          $$PlansTableFilterComposer,
          $$PlansTableOrderingComposer,
          $$PlansTableAnnotationComposer,
          $$PlansTableCreateCompanionBuilder,
          $$PlansTableUpdateCompanionBuilder,
          (PlanRow, BaseReferences<_$AppDatabase, $PlansTable, PlanRow>),
          PlanRow,
          PrefetchHooks Function()
        > {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> protagonistMemberId = const Value.absent(),
                Value<int> startYear = const Value.absent(),
                Value<String> baselineDate = const Value.absent(),
                Value<double> defaultInflationRate = const Value.absent(),
                Value<String?> copiedFromPlanId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                name: name,
                protagonistMemberId: protagonistMemberId,
                startYear: startYear,
                baselineDate: baselineDate,
                defaultInflationRate: defaultInflationRate,
                copiedFromPlanId: copiedFromPlanId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String name,
                required String protagonistMemberId,
                required int startYear,
                required String baselineDate,
                required double defaultInflationRate,
                Value<String?> copiedFromPlanId = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                name: name,
                protagonistMemberId: protagonistMemberId,
                startYear: startYear,
                baselineDate: baselineDate,
                defaultInflationRate: defaultInflationRate,
                copiedFromPlanId: copiedFromPlanId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlansTable, PlanRow>(table),
                  BaseReferences<_$AppDatabase, $PlansTable, PlanRow>(
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

typedef $$PlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlansTable,
      PlanRow,
      $$PlansTableFilterComposer,
      $$PlansTableOrderingComposer,
      $$PlansTableAnnotationComposer,
      $$PlansTableCreateCompanionBuilder,
      $$PlansTableUpdateCompanionBuilder,
      (PlanRow, BaseReferences<_$AppDatabase, $PlansTable, PlanRow>),
      PlanRow,
      PrefetchHooks Function()
    >;
typedef $$FamilyMembersTableCreateCompanionBuilder =
    FamilyMembersCompanion Function({
      required String id,
      required String createdAt,
      required String updatedAt,
      required String updatedBy,
      Value<String?> deletedAt,
      required String planId,
      required String name,
      required String relation,
      required String birthDate,
      required int lifeExpectancy,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$FamilyMembersTableUpdateCompanionBuilder =
    FamilyMembersCompanion Function({
      Value<String> id,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String> updatedBy,
      Value<String?> deletedAt,
      Value<String> planId,
      Value<String> name,
      Value<String> relation,
      Value<String> birthDate,
      Value<int> lifeExpectancy,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$FamilyMembersTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyMembersTable> {
  $$FamilyMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relation => $composableBuilder(
    column: $table.relation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lifeExpectancy => $composableBuilder(
    column: $table.lifeExpectancy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FamilyMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyMembersTable> {
  $$FamilyMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relation => $composableBuilder(
    column: $table.relation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lifeExpectancy => $composableBuilder(
    column: $table.lifeExpectancy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamilyMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyMembersTable> {
  $$FamilyMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get relation =>
      $composableBuilder(column: $table.relation, builder: (column) => column);

  GeneratedColumn<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<int> get lifeExpectancy => $composableBuilder(
    column: $table.lifeExpectancy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$FamilyMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamilyMembersTable,
          FamilyMemberRow,
          $$FamilyMembersTableFilterComposer,
          $$FamilyMembersTableOrderingComposer,
          $$FamilyMembersTableAnnotationComposer,
          $$FamilyMembersTableCreateCompanionBuilder,
          $$FamilyMembersTableUpdateCompanionBuilder,
          (
            FamilyMemberRow,
            BaseReferences<_$AppDatabase, $FamilyMembersTable, FamilyMemberRow>,
          ),
          FamilyMemberRow,
          PrefetchHooks Function()
        > {
  $$FamilyMembersTableTableManager(_$AppDatabase db, $FamilyMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> relation = const Value.absent(),
                Value<String> birthDate = const Value.absent(),
                Value<int> lifeExpectancy = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyMembersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                name: name,
                relation: relation,
                birthDate: birthDate,
                lifeExpectancy: lifeExpectancy,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String planId,
                required String name,
                required String relation,
                required String birthDate,
                required int lifeExpectancy,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => FamilyMembersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                name: name,
                relation: relation,
                birthDate: birthDate,
                lifeExpectancy: lifeExpectancy,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FamilyMembersTable, FamilyMemberRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FamilyMembersTable,
                    FamilyMemberRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FamilyMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamilyMembersTable,
      FamilyMemberRow,
      $$FamilyMembersTableFilterComposer,
      $$FamilyMembersTableOrderingComposer,
      $$FamilyMembersTableAnnotationComposer,
      $$FamilyMembersTableCreateCompanionBuilder,
      $$FamilyMembersTableUpdateCompanionBuilder,
      (
        FamilyMemberRow,
        BaseReferences<_$AppDatabase, $FamilyMembersTable, FamilyMemberRow>,
      ),
      FamilyMemberRow,
      PrefetchHooks Function()
    >;
typedef $$PlanLinesTableCreateCompanionBuilder = PlanLinesCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required String planId,
  required int year,
  required int month,
  required String kind,
  required int amount,
  Value<String?> categoryId,
  required String accountId,
  Value<String?> toAccountId,
  Value<String?> assetId,
  Value<String?> assetAction,
  Value<int?> quantityX1e4,
  Value<String?> eventId,
  Value<String?> memo,
  required String source,
  Value<String?> sourceId,
  Value<String?> memberId,
  Value<String?> groupItemId,
  Value<int> rowid,
});
typedef $$PlanLinesTableUpdateCompanionBuilder = PlanLinesCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<String> planId,
  Value<int> year,
  Value<int> month,
  Value<String> kind,
  Value<int> amount,
  Value<String?> categoryId,
  Value<String> accountId,
  Value<String?> toAccountId,
  Value<String?> assetId,
  Value<String?> assetAction,
  Value<int?> quantityX1e4,
  Value<String?> eventId,
  Value<String?> memo,
  Value<String> source,
  Value<String?> sourceId,
  Value<String?> memberId,
  Value<String?> groupItemId,
  Value<int> rowid,
});

class $$PlanLinesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanLinesTable> {
  $$PlanLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetAction => $composableBuilder(
    column: $table.assetAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupItemId => $composableBuilder(
    column: $table.groupItemId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanLinesTable> {
  $$PlanLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetAction => $composableBuilder(
    column: $table.assetAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupItemId => $composableBuilder(
    column: $table.groupItemId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanLinesTable> {
  $$PlanLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get assetAction => $composableBuilder(
    column: $table.assetAction,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get groupItemId => $composableBuilder(
    column: $table.groupItemId,
    builder: (column) => column,
  );
}

class $$PlanLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanLinesTable,
          PlanLineRow,
          $$PlanLinesTableFilterComposer,
          $$PlanLinesTableOrderingComposer,
          $$PlanLinesTableAnnotationComposer,
          $$PlanLinesTableCreateCompanionBuilder,
          $$PlanLinesTableUpdateCompanionBuilder,
          (
            PlanLineRow,
            BaseReferences<_$AppDatabase, $PlanLinesTable, PlanLineRow>,
          ),
          PlanLineRow,
          PrefetchHooks Function()
        > {
  $$PlanLinesTableTableManager(_$AppDatabase db, $PlanLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<String?> assetAction = const Value.absent(),
                Value<int?> quantityX1e4 = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<String?> groupItemId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanLinesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                year: year,
                month: month,
                kind: kind,
                amount: amount,
                categoryId: categoryId,
                accountId: accountId,
                toAccountId: toAccountId,
                assetId: assetId,
                assetAction: assetAction,
                quantityX1e4: quantityX1e4,
                eventId: eventId,
                memo: memo,
                source: source,
                sourceId: sourceId,
                memberId: memberId,
                groupItemId: groupItemId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String planId,
                required int year,
                required int month,
                required String kind,
                required int amount,
                Value<String?> categoryId = const Value.absent(),
                required String accountId,
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<String?> assetAction = const Value.absent(),
                Value<int?> quantityX1e4 = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                required String source,
                Value<String?> sourceId = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<String?> groupItemId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanLinesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                year: year,
                month: month,
                kind: kind,
                amount: amount,
                categoryId: categoryId,
                accountId: accountId,
                toAccountId: toAccountId,
                assetId: assetId,
                assetAction: assetAction,
                quantityX1e4: quantityX1e4,
                eventId: eventId,
                memo: memo,
                source: source,
                sourceId: sourceId,
                memberId: memberId,
                groupItemId: groupItemId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanLinesTable, PlanLineRow>(table),
                  BaseReferences<_$AppDatabase, $PlanLinesTable, PlanLineRow>(
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

typedef $$PlanLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanLinesTable,
      PlanLineRow,
      $$PlanLinesTableFilterComposer,
      $$PlanLinesTableOrderingComposer,
      $$PlanLinesTableAnnotationComposer,
      $$PlanLinesTableCreateCompanionBuilder,
      $$PlanLinesTableUpdateCompanionBuilder,
      (
        PlanLineRow,
        BaseReferences<_$AppDatabase, $PlanLinesTable, PlanLineRow>,
      ),
      PlanLineRow,
      PrefetchHooks Function()
    >;
typedef $$PlanEventsTableCreateCompanionBuilder = PlanEventsCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required String planId,
  required String memberId,
  required String title,
  required int year,
  required int month,
  Value<int?> day,
  required String status,
  Value<String?> doneDate,
  Value<String?> memo,
  Value<int> rowid,
});
typedef $$PlanEventsTableUpdateCompanionBuilder = PlanEventsCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<String> planId,
  Value<String> memberId,
  Value<String> title,
  Value<int> year,
  Value<int> month,
  Value<int?> day,
  Value<String> status,
  Value<String?> doneDate,
  Value<String?> memo,
  Value<int> rowid,
});

class $$PlanEventsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanEventsTable> {
  $$PlanEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doneDate => $composableBuilder(
    column: $table.doneDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanEventsTable> {
  $$PlanEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doneDate => $composableBuilder(
    column: $table.doneDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanEventsTable> {
  $$PlanEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get doneDate =>
      $composableBuilder(column: $table.doneDate, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);
}

class $$PlanEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanEventsTable,
          PlanEventRow,
          $$PlanEventsTableFilterComposer,
          $$PlanEventsTableOrderingComposer,
          $$PlanEventsTableAnnotationComposer,
          $$PlanEventsTableCreateCompanionBuilder,
          $$PlanEventsTableUpdateCompanionBuilder,
          (
            PlanEventRow,
            BaseReferences<_$AppDatabase, $PlanEventsTable, PlanEventRow>,
          ),
          PlanEventRow,
          PrefetchHooks Function()
        > {
  $$PlanEventsTableTableManager(_$AppDatabase db, $PlanEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<int?> day = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> doneDate = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanEventsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                memberId: memberId,
                title: title,
                year: year,
                month: month,
                day: day,
                status: status,
                doneDate: doneDate,
                memo: memo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String planId,
                required String memberId,
                required String title,
                required int year,
                required int month,
                Value<int?> day = const Value.absent(),
                required String status,
                Value<String?> doneDate = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanEventsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                memberId: memberId,
                title: title,
                year: year,
                month: month,
                day: day,
                status: status,
                doneDate: doneDate,
                memo: memo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanEventsTable, PlanEventRow>(table),
                  BaseReferences<_$AppDatabase, $PlanEventsTable, PlanEventRow>(
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

typedef $$PlanEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanEventsTable,
      PlanEventRow,
      $$PlanEventsTableFilterComposer,
      $$PlanEventsTableOrderingComposer,
      $$PlanEventsTableAnnotationComposer,
      $$PlanEventsTableCreateCompanionBuilder,
      $$PlanEventsTableUpdateCompanionBuilder,
      (
        PlanEventRow,
        BaseReferences<_$AppDatabase, $PlanEventsTable, PlanEventRow>,
      ),
      PlanEventRow,
      PrefetchHooks Function()
    >;
typedef $$PlanRatesTableCreateCompanionBuilder = PlanRatesCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required String planId,
  required String targetType,
  required String targetId,
  required double annualRate,
  Value<int> rowid,
});
typedef $$PlanRatesTableUpdateCompanionBuilder = PlanRatesCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<String> planId,
  Value<String> targetType,
  Value<String> targetId,
  Value<double> annualRate,
  Value<int> rowid,
});

class $$PlanRatesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanRatesTable> {
  $$PlanRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get annualRate => $composableBuilder(
    column: $table.annualRate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanRatesTable> {
  $$PlanRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get annualRate => $composableBuilder(
    column: $table.annualRate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanRatesTable> {
  $$PlanRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<double> get annualRate => $composableBuilder(
    column: $table.annualRate,
    builder: (column) => column,
  );
}

class $$PlanRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanRatesTable,
          PlanRateRow,
          $$PlanRatesTableFilterComposer,
          $$PlanRatesTableOrderingComposer,
          $$PlanRatesTableAnnotationComposer,
          $$PlanRatesTableCreateCompanionBuilder,
          $$PlanRatesTableUpdateCompanionBuilder,
          (
            PlanRateRow,
            BaseReferences<_$AppDatabase, $PlanRatesTable, PlanRateRow>,
          ),
          PlanRateRow,
          PrefetchHooks Function()
        > {
  $$PlanRatesTableTableManager(_$AppDatabase db, $PlanRatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<double> annualRate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanRatesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                targetType: targetType,
                targetId: targetId,
                annualRate: annualRate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String planId,
                required String targetType,
                required String targetId,
                required double annualRate,
                Value<int> rowid = const Value.absent(),
              }) => PlanRatesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                targetType: targetType,
                targetId: targetId,
                annualRate: annualRate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanRatesTable, PlanRateRow>(table),
                  BaseReferences<_$AppDatabase, $PlanRatesTable, PlanRateRow>(
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

typedef $$PlanRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanRatesTable,
      PlanRateRow,
      $$PlanRatesTableFilterComposer,
      $$PlanRatesTableOrderingComposer,
      $$PlanRatesTableAnnotationComposer,
      $$PlanRatesTableCreateCompanionBuilder,
      $$PlanRatesTableUpdateCompanionBuilder,
      (
        PlanRateRow,
        BaseReferences<_$AppDatabase, $PlanRatesTable, PlanRateRow>,
      ),
      PlanRateRow,
      PrefetchHooks Function()
    >;
typedef $$PlanBaselinesTableCreateCompanionBuilder =
    PlanBaselinesCompanion Function({
      required String id,
      required String createdAt,
      required String updatedAt,
      required String updatedBy,
      Value<String?> deletedAt,
      required String planId,
      required String targetType,
      required String targetId,
      Value<int?> balance,
      Value<int?> quantityX1e4,
      Value<int?> priceX100,
      Value<int> rowid,
    });
typedef $$PlanBaselinesTableUpdateCompanionBuilder =
    PlanBaselinesCompanion Function({
      Value<String> id,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String> updatedBy,
      Value<String?> deletedAt,
      Value<String> planId,
      Value<String> targetType,
      Value<String> targetId,
      Value<int?> balance,
      Value<int?> quantityX1e4,
      Value<int?> priceX100,
      Value<int> rowid,
    });

class $$PlanBaselinesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanBaselinesTable> {
  $$PlanBaselinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceX100 => $composableBuilder(
    column: $table.priceX100,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanBaselinesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanBaselinesTable> {
  $$PlanBaselinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceX100 => $composableBuilder(
    column: $table.priceX100,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanBaselinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanBaselinesTable> {
  $$PlanBaselinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<int> get quantityX1e4 => $composableBuilder(
    column: $table.quantityX1e4,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priceX100 =>
      $composableBuilder(column: $table.priceX100, builder: (column) => column);
}

class $$PlanBaselinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanBaselinesTable,
          PlanBaselineRow,
          $$PlanBaselinesTableFilterComposer,
          $$PlanBaselinesTableOrderingComposer,
          $$PlanBaselinesTableAnnotationComposer,
          $$PlanBaselinesTableCreateCompanionBuilder,
          $$PlanBaselinesTableUpdateCompanionBuilder,
          (
            PlanBaselineRow,
            BaseReferences<_$AppDatabase, $PlanBaselinesTable, PlanBaselineRow>,
          ),
          PlanBaselineRow,
          PrefetchHooks Function()
        > {
  $$PlanBaselinesTableTableManager(_$AppDatabase db, $PlanBaselinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanBaselinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanBaselinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanBaselinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<int?> balance = const Value.absent(),
                Value<int?> quantityX1e4 = const Value.absent(),
                Value<int?> priceX100 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanBaselinesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                targetType: targetType,
                targetId: targetId,
                balance: balance,
                quantityX1e4: quantityX1e4,
                priceX100: priceX100,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String planId,
                required String targetType,
                required String targetId,
                Value<int?> balance = const Value.absent(),
                Value<int?> quantityX1e4 = const Value.absent(),
                Value<int?> priceX100 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanBaselinesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                targetType: targetType,
                targetId: targetId,
                balance: balance,
                quantityX1e4: quantityX1e4,
                priceX100: priceX100,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanBaselinesTable, PlanBaselineRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlanBaselinesTable,
                    PlanBaselineRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanBaselinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanBaselinesTable,
      PlanBaselineRow,
      $$PlanBaselinesTableFilterComposer,
      $$PlanBaselinesTableOrderingComposer,
      $$PlanBaselinesTableAnnotationComposer,
      $$PlanBaselinesTableCreateCompanionBuilder,
      $$PlanBaselinesTableUpdateCompanionBuilder,
      (
        PlanBaselineRow,
        BaseReferences<_$AppDatabase, $PlanBaselinesTable, PlanBaselineRow>,
      ),
      PlanBaselineRow,
      PrefetchHooks Function()
    >;
typedef $$PlanGroupsTableCreateCompanionBuilder = PlanGroupsCompanion Function({
  required String id,
  required String createdAt,
  required String updatedAt,
  required String updatedBy,
  Value<String?> deletedAt,
  required String planId,
  required String groupId,
  required String startYm,
  required String endYm,
  Value<String?> memo,
  Value<int> rowid,
});
typedef $$PlanGroupsTableUpdateCompanionBuilder = PlanGroupsCompanion Function({
  Value<String> id,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> updatedBy,
  Value<String?> deletedAt,
  Value<String> planId,
  Value<String> groupId,
  Value<String> startYm,
  Value<String> endYm,
  Value<String?> memo,
  Value<int> rowid,
});

class $$PlanGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanGroupsTable> {
  $$PlanGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startYm => $composableBuilder(
    column: $table.startYm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endYm => $composableBuilder(
    column: $table.endYm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanGroupsTable> {
  $$PlanGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startYm => $composableBuilder(
    column: $table.startYm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endYm => $composableBuilder(
    column: $table.endYm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanGroupsTable> {
  $$PlanGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get startYm =>
      $composableBuilder(column: $table.startYm, builder: (column) => column);

  GeneratedColumn<String> get endYm =>
      $composableBuilder(column: $table.endYm, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);
}

class $$PlanGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanGroupsTable,
          PlanGroupRow,
          $$PlanGroupsTableFilterComposer,
          $$PlanGroupsTableOrderingComposer,
          $$PlanGroupsTableAnnotationComposer,
          $$PlanGroupsTableCreateCompanionBuilder,
          $$PlanGroupsTableUpdateCompanionBuilder,
          (
            PlanGroupRow,
            BaseReferences<_$AppDatabase, $PlanGroupsTable, PlanGroupRow>,
          ),
          PlanGroupRow,
          PrefetchHooks Function()
        > {
  $$PlanGroupsTableTableManager(_$AppDatabase db, $PlanGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> startYm = const Value.absent(),
                Value<String> endYm = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanGroupsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                groupId: groupId,
                startYm: startYm,
                endYm: endYm,
                memo: memo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String createdAt,
                required String updatedAt,
                required String updatedBy,
                Value<String?> deletedAt = const Value.absent(),
                required String planId,
                required String groupId,
                required String startYm,
                required String endYm,
                Value<String?> memo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanGroupsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                planId: planId,
                groupId: groupId,
                startYm: startYm,
                endYm: endYm,
                memo: memo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanGroupsTable, PlanGroupRow>(table),
                  BaseReferences<_$AppDatabase, $PlanGroupsTable, PlanGroupRow>(
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

typedef $$PlanGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanGroupsTable,
      PlanGroupRow,
      $$PlanGroupsTableFilterComposer,
      $$PlanGroupsTableOrderingComposer,
      $$PlanGroupsTableAnnotationComposer,
      $$PlanGroupsTableCreateCompanionBuilder,
      $$PlanGroupsTableUpdateCompanionBuilder,
      (
        PlanGroupRow,
        BaseReferences<_$AppDatabase, $PlanGroupsTable, PlanGroupRow>,
      ),
      PlanGroupRow,
      PrefetchHooks Function()
    >;
typedef $$DeviceSettingsTableCreateCompanionBuilder =
    DeviceSettingsCompanion Function({
      required String deviceId,
      Value<String?> selectedPlanId,
      Value<String?> redisHost,
      Value<int?> redisPort,
      Value<String?> lastSyncAt,
      Value<int> rowid,
    });
typedef $$DeviceSettingsTableUpdateCompanionBuilder =
    DeviceSettingsCompanion Function({
      Value<String> deviceId,
      Value<String?> selectedPlanId,
      Value<String?> redisHost,
      Value<int?> redisPort,
      Value<String?> lastSyncAt,
      Value<int> rowid,
    });

class $$DeviceSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceSettingsTable> {
  $$DeviceSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedPlanId => $composableBuilder(
    column: $table.selectedPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get redisHost => $composableBuilder(
    column: $table.redisHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get redisPort => $composableBuilder(
    column: $table.redisPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceSettingsTable> {
  $$DeviceSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedPlanId => $composableBuilder(
    column: $table.selectedPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get redisHost => $composableBuilder(
    column: $table.redisHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get redisPort => $composableBuilder(
    column: $table.redisPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceSettingsTable> {
  $$DeviceSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get selectedPlanId => $composableBuilder(
    column: $table.selectedPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get redisHost =>
      $composableBuilder(column: $table.redisHost, builder: (column) => column);

  GeneratedColumn<int> get redisPort =>
      $composableBuilder(column: $table.redisPort, builder: (column) => column);

  GeneratedColumn<String> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );
}

class $$DeviceSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceSettingsTable,
          DeviceSettingRow,
          $$DeviceSettingsTableFilterComposer,
          $$DeviceSettingsTableOrderingComposer,
          $$DeviceSettingsTableAnnotationComposer,
          $$DeviceSettingsTableCreateCompanionBuilder,
          $$DeviceSettingsTableUpdateCompanionBuilder,
          (
            DeviceSettingRow,
            BaseReferences<
              _$AppDatabase,
              $DeviceSettingsTable,
              DeviceSettingRow
            >,
          ),
          DeviceSettingRow,
          PrefetchHooks Function()
        > {
  $$DeviceSettingsTableTableManager(
    _$AppDatabase db,
    $DeviceSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String?> selectedPlanId = const Value.absent(),
                Value<String?> redisHost = const Value.absent(),
                Value<int?> redisPort = const Value.absent(),
                Value<String?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceSettingsCompanion(
                deviceId: deviceId,
                selectedPlanId: selectedPlanId,
                redisHost: redisHost,
                redisPort: redisPort,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                Value<String?> selectedPlanId = const Value.absent(),
                Value<String?> redisHost = const Value.absent(),
                Value<int?> redisPort = const Value.absent(),
                Value<String?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceSettingsCompanion.insert(
                deviceId: deviceId,
                selectedPlanId: selectedPlanId,
                redisHost: redisHost,
                redisPort: redisPort,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeviceSettingsTable, DeviceSettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DeviceSettingsTable,
                    DeviceSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceSettingsTable,
      DeviceSettingRow,
      $$DeviceSettingsTableFilterComposer,
      $$DeviceSettingsTableOrderingComposer,
      $$DeviceSettingsTableAnnotationComposer,
      $$DeviceSettingsTableCreateCompanionBuilder,
      $$DeviceSettingsTableUpdateCompanionBuilder,
      (
        DeviceSettingRow,
        BaseReferences<_$AppDatabase, $DeviceSettingsTable, DeviceSettingRow>,
      ),
      DeviceSettingRow,
      PrefetchHooks Function()
    >;
typedef $$CategoryRulesTableCreateCompanionBuilder =
    CategoryRulesCompanion Function({
      required String kind,
      required String content,
      required String categoryId,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$CategoryRulesTableUpdateCompanionBuilder =
    CategoryRulesCompanion Function({
      Value<String> kind,
      Value<String> content,
      Value<String> categoryId,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$CategoryRulesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryRulesTable> {
  $$CategoryRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryRulesTable> {
  $$CategoryRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryRulesTable> {
  $$CategoryRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoryRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryRulesTable,
          CategoryRuleRow,
          $$CategoryRulesTableFilterComposer,
          $$CategoryRulesTableOrderingComposer,
          $$CategoryRulesTableAnnotationComposer,
          $$CategoryRulesTableCreateCompanionBuilder,
          $$CategoryRulesTableUpdateCompanionBuilder,
          (
            CategoryRuleRow,
            BaseReferences<_$AppDatabase, $CategoryRulesTable, CategoryRuleRow>,
          ),
          CategoryRuleRow,
          PrefetchHooks Function()
        > {
  $$CategoryRulesTableTableManager(_$AppDatabase db, $CategoryRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryRulesCompanion(
                kind: kind,
                content: content,
                categoryId: categoryId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String content,
                required String categoryId,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoryRulesCompanion.insert(
                kind: kind,
                content: content,
                categoryId: categoryId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoryRulesTable, CategoryRuleRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CategoryRulesTable,
                    CategoryRuleRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryRulesTable,
      CategoryRuleRow,
      $$CategoryRulesTableFilterComposer,
      $$CategoryRulesTableOrderingComposer,
      $$CategoryRulesTableAnnotationComposer,
      $$CategoryRulesTableCreateCompanionBuilder,
      $$CategoryRulesTableUpdateCompanionBuilder,
      (
        CategoryRuleRow,
        BaseReferences<_$AppDatabase, $CategoryRulesTable, CategoryRuleRow>,
      ),
      CategoryRuleRow,
      PrefetchHooks Function()
    >;
typedef $$DevicePrefsTableCreateCompanionBuilder =
    DevicePrefsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$DevicePrefsTableUpdateCompanionBuilder =
    DevicePrefsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$DevicePrefsTableFilterComposer
    extends Composer<_$AppDatabase, $DevicePrefsTable> {
  $$DevicePrefsTableFilterComposer({
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

class $$DevicePrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicePrefsTable> {
  $$DevicePrefsTableOrderingComposer({
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

class $$DevicePrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicePrefsTable> {
  $$DevicePrefsTableAnnotationComposer({
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

class $$DevicePrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicePrefsTable,
          DevicePrefRow,
          $$DevicePrefsTableFilterComposer,
          $$DevicePrefsTableOrderingComposer,
          $$DevicePrefsTableAnnotationComposer,
          $$DevicePrefsTableCreateCompanionBuilder,
          $$DevicePrefsTableUpdateCompanionBuilder,
          (
            DevicePrefRow,
            BaseReferences<_$AppDatabase, $DevicePrefsTable, DevicePrefRow>,
          ),
          DevicePrefRow,
          PrefetchHooks Function()
        > {
  $$DevicePrefsTableTableManager(_$AppDatabase db, $DevicePrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicePrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicePrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicePrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => DevicePrefsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => DevicePrefsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DevicePrefsTable, DevicePrefRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DevicePrefsTable,
                    DevicePrefRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DevicePrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicePrefsTable,
      DevicePrefRow,
      $$DevicePrefsTableFilterComposer,
      $$DevicePrefsTableOrderingComposer,
      $$DevicePrefsTableAnnotationComposer,
      $$DevicePrefsTableCreateCompanionBuilder,
      $$DevicePrefsTableUpdateCompanionBuilder,
      (
        DevicePrefRow,
        BaseReferences<_$AppDatabase, $DevicePrefsTable, DevicePrefRow>,
      ),
      DevicePrefRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HouseholdTableTableManager get household =>
      $$HouseholdTableTableManager(_db, _db.household);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TxnsTableTableManager get txns => $$TxnsTableTableManager(_db, _db.txns);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$AssetValuesTableTableManager get assetValues =>
      $$AssetValuesTableTableManager(_db, _db.assetValues);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$TemplateGroupsTableTableManager get templateGroups =>
      $$TemplateGroupsTableTableManager(_db, _db.templateGroups);
  $$TemplateGroupItemsTableTableManager get templateGroupItems =>
      $$TemplateGroupItemsTableTableManager(_db, _db.templateGroupItems);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$FamilyMembersTableTableManager get familyMembers =>
      $$FamilyMembersTableTableManager(_db, _db.familyMembers);
  $$PlanLinesTableTableManager get planLines =>
      $$PlanLinesTableTableManager(_db, _db.planLines);
  $$PlanEventsTableTableManager get planEvents =>
      $$PlanEventsTableTableManager(_db, _db.planEvents);
  $$PlanRatesTableTableManager get planRates =>
      $$PlanRatesTableTableManager(_db, _db.planRates);
  $$PlanBaselinesTableTableManager get planBaselines =>
      $$PlanBaselinesTableTableManager(_db, _db.planBaselines);
  $$PlanGroupsTableTableManager get planGroups =>
      $$PlanGroupsTableTableManager(_db, _db.planGroups);
  $$DeviceSettingsTableTableManager get deviceSettings =>
      $$DeviceSettingsTableTableManager(_db, _db.deviceSettings);
  $$CategoryRulesTableTableManager get categoryRules =>
      $$CategoryRulesTableTableManager(_db, _db.categoryRules);
  $$DevicePrefsTableTableManager get devicePrefs =>
      $$DevicePrefsTableTableManager(_db, _db.devicePrefs);
}
