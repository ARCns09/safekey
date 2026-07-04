import '../database/database.dart';

class AccountRepository {
  final AppDatabase _db;

  AccountRepository(this._db);

  Future<List<Account>> getAllAccounts() => _db.select(_db.accounts).get();

  Stream<List<Account>> watchAllAccounts() => _db.select(_db.accounts).watch();

  Future<int> insertAccount(AccountsCompanion account) => _db.into(_db.accounts).insert(account);

  Future<bool> updateAccount(Account account) => _db.update(_db.accounts).replace(account);

  Future<int> deleteAccount(Account account) => _db.delete(_db.accounts).delete(account);
}
