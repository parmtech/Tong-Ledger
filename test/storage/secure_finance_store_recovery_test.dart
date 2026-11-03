import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/demo_data.dart';
import 'package:tong_ledger/domain/finance_models.dart';
import 'package:tong_ledger/storage/encrypted_document.dart';
import 'package:tong_ledger/storage/secure_finance_store.dart';
import 'package:tong_ledger/storage/vault_key_access.dart';

class MemoryVaultKeys implements VaultKeyAccess {
  final Map<String, String> slots = {};
  bool rejectPrimaryWrite = false;
  bool rejectRecoveryWrite = false;

  @override
  Future<String?> read(String slot) async => slots[slot];

  @override
  Future<void> write(String slot, String value) async {
    if (slot == 'tong_ledger_snapshot_key_v1' && rejectPrimaryWrite) {
      throw StateError('Simulated device key write failure');
    }
    if (slot == 'tong_ledger_recovery_key_v1' && rejectRecoveryWrite) {
      throw StateError('Simulated recovery key write failure');
    }
    slots[slot] = value;
  }

  @override
  Future<void> delete(String slot) async => slots.remove(slot);
}

void main() {
  late Directory directory;
  late MemoryVaultKeys keys;
  late SecureFinanceStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('tong-ledger-recovery-');
    keys = MemoryVaultKeys();
    store = SecureFinanceStore(
      keyAccess: keys, supportDirectory: () async => directory,
    );
  });
  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  File vault() => File(
    '${directory.path}${Platform.pathSeparator}tong_ledger_private_v1.enc',
  );

  test('fresh encrypted vault does not write plaintext', () async {
    final book = createDemoBook();
    await store.save(book);
    expect(await vault().readAsString(), isNot(contains('Commonwealth Bank')));
    final loaded = await store.load();
    expect(loaded.accounts.length, book.accounts.length);
  });

  test('missing primary key blocks saves and verified backup recovers safely',
      () async {
    await store.save(createDemoBook());
    final oldCiphertext = await vault().readAsString();
    final oldKey = keys.slots['tong_ledger_snapshot_key_v1']!;
    keys.slots.remove('tong_ledger_snapshot_key_v1');
    await expectLater(store.load(), throwsA(isA<SecureStorageFailure>()));
    await expectLater(store.save(FinanceBook()),
        throwsA(isA<SecureStorageFailure>()));
    expect(await vault().readAsString(), oldCiphertext);

    final replacement = FinanceBook(accounts: [
      const CashAccount(id: 'restored', name: 'Recovered',
        openingCents: 42000),
    ]);
    await store.restoreVerifiedBackup(replacement);
    expect((await store.load()).accounts.single.id, 'restored');
    final copies = await directory.list()
        .where((entry) => entry.path.contains('.preserved-')).toList();
    expect(copies.length, 1);
    expect(await File(copies.single.path).readAsString(), oldCiphertext);
    final plaintext = await EncryptedDocument().decrypt(
      oldCiphertext, base64Decode(oldKey),
    );
    expect(plaintext, contains('Commonwealth Bank'));
  });

  test('interrupted key promotion can be recovered after process restart',
      () async {
    await store.save(createDemoBook());
    final replacement = FinanceBook(accounts: [
      const CashAccount(id: 'new', name: 'New account', openingCents: 7000),
    ]);
    keys.rejectPrimaryWrite = true;
    await expectLater(store.restoreVerifiedBackup(replacement),
      throwsA(isA<SecureStorageFailure>()));
    expect(await File('${vault().path}.recovery-in-progress').exists(), true);
    expect(keys.slots['tong_ledger_recovery_key_v1'], isNotNull);

    keys.rejectPrimaryWrite = false;
    final freshProcess = SecureFinanceStore(
      keyAccess: keys, supportDirectory: () async => directory,
    );
    expect((await freshProcess.load()).accounts.single.id, 'new');
    expect(keys.slots['tong_ledger_recovery_key_v1'], isNull);
    expect(await File('${vault().path}.recovery-in-progress').exists(), false);
  });

  test('failed recovery-key provisioning leaves active encrypted vault intact',
      () async {
    await store.save(createDemoBook());
    final before = await vault().readAsString();
    keys.rejectRecoveryWrite = true;
    await expectLater(store.restoreVerifiedBackup(FinanceBook()),
      throwsA(isA<StateError>()));
    expect(await vault().readAsString(), before);
    expect((await store.load()).institutions, isNotEmpty);
  });

  test('interrupted recovery does not initialise an empty vault', () async {
    await store.save(createDemoBook());
    await vault().delete();
    await File('${vault().path}.recovery-in-progress')
        .writeAsString('unfinished', flush: true);
    await expectLater(store.load(), throwsA(isA<SecureStorageFailure>()));
    expect(await vault().exists(), false);
  });

  test('recovery marker rejects regular saves', () async {
    await store.save(createDemoBook());
    final before = await vault().readAsString();
    await File('${vault().path}.recovery-in-progress')
        .writeAsString('unfinished', flush: true);
    await expectLater(store.save(FinanceBook()),
      throwsA(isA<SecureStorageFailure>()));
    expect(await vault().readAsString(), before);
  });
}
