import '../database/database.dart';

class AccountRepository {
  final AppDatabase _db;

  AccountRepository(this._db);

  Future<List<Account>> getAllAccounts() => _db.select(_db.accounts).get();

  Stream<List<Account>> watchAllAccounts() => _db.select(_db.accounts).watch();

  Future<int> insertAccount(AccountsCompanion account) => _db.into(_db.accounts).insert(account);

  Future<bool> updateAccount(Account account) => _db.update(_db.accounts).replace(account);

  Future<int> deleteAccount(Account account) => _db.delete(_db.accounts).delete(account);

  // Recovery Codes
  Stream<List<RecoveryCode>> watchRecoveryCodesForAccount(int accountId) {
    return (_db.select(_db.recoveryCodes)..where((t) => t.accountId.equals(accountId))).watch();
  }

  Future<int> insertRecoveryCode(RecoveryCodesCompanion code) => _db.into(_db.recoveryCodes).insert(code);

  Future<bool> updateRecoveryCode(RecoveryCode code) => _db.update(_db.recoveryCodes).replace(code);

  Future<int> deleteRecoveryCode(RecoveryCode code) => _db.delete(_db.recoveryCodes).delete(code);
}
