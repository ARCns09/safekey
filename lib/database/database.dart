import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

part 'database.g.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get issuer => text()();
  TextColumn get accountName => text()();
  TextColumn get secret => text()();
  TextColumn get algorithm => text().withDefault(const Constant('SHA1'))();
  IntColumn get digits => integer().withDefault(const Constant(6))();
  IntColumn get period => integer().withDefault(const Constant(30))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();
  TextColumn get tags => text().withDefault(const Constant(''))();
}

class RecoveryCodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().customConstraint('NOT NULL REFERENCES accounts(id) ON DELETE CASCADE')();
  TextColumn get code => text()();
  BoolColumn get isUsed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Accounts, RecoveryCodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(accounts, accounts.isPinned);
      }
      if (from < 3) {
        await m.addColumn(accounts, accounts.sortIndex);
      }
      if (from < 4) {
        await m.addColumn(accounts, accounts.tags);
        await m.createTable(recoveryCodes);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'safekey.sqlite'));

    // Provide the key via secure storage
    const secureStorage = FlutterSecureStorage();
    String? encryptionKey = await secureStorage.read(key: 'db_encryption_key');

    if (encryptionKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      encryptionKey = base64UrlEncode(keyBytes);
      await secureStorage.write(key: 'db_encryption_key', value: encryptionKey);
    }

    // Override sqlite3 library to use SQLCipher on Android
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

    return NativeDatabase(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$encryptionKey';");
      },
    );
  });
}
