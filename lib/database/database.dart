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
}

@DriftDatabase(tables: [Accounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
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
