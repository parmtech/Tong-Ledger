import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/storage/journal_key_manager.dart';
import 'package:tong_ledger/storage/vault_key_access.dart';

class FakeKeyAccess implements VaultKeyAccess {
  final Map<String, String> values = {};
  bool ignoreWrite = false;
  Completer<void>? readGate;
  int writes = 0;

  @override
  Future<String?> read(String slot) async {
    await readGate?.future;
    return values[slot];
  }

  @override
  Future<void> write(String slot, String value) async {
    writes++;
    if (!ignoreWrite) values[slot] = value;
  }

  @override
  Future<void> delete(String slot) async {
    values.remove(slot);
  }
}

void main() {
  late FakeKeyAccess keys;
  late JournalKeyManager manager;

  setUp(() {
    keys = FakeKeyAccess();
    manager = JournalKeyManager(keys);
  });

  test('fresh key is persisted and reused across manager restart', () async {
    final first = await manager.acquire(existingEvidence: false);
    expect(first, hasLength(32));
    expect(base64Decode(keys.values[JournalKeyManager.slot]!), first);
    final second = await JournalKeyManager(keys).acquire(existingEvidence: true);
    expect(second, first);
    expect(keys.writes, 1);
  });

  test('missing key with database evidence fails without writing', () async {
    await expectLater(manager.acquire(existingEvidence: true),
      throwsA(isA<JournalKeyFailure>()));
    expect(keys.writes, 0);
  });

  test('invalid stored key never gets replaced', () async {
    keys.values[JournalKeyManager.slot] = 'invalid';
    await expectLater(manager.acquire(existingEvidence: false),
      throwsA(isA<JournalKeyFailure>()));
    expect(keys.values[JournalKeyManager.slot], 'invalid');
    expect(keys.writes, 0);
  });

  test('unverified key write is not returned to caller', () async {
    keys.ignoreWrite = true;
    await expectLater(manager.acquire(existingEvidence: false),
      throwsA(isA<JournalKeyFailure>()));
    expect(keys.values, isEmpty);
  });

  test('overlapping calls on same manager fail closed', () async {
    final gate = Completer<void>();
    keys.readGate = gate;
    final first = manager.acquire(existingEvidence: false);
    await expectLater(manager.acquire(existingEvidence: false),
      throwsA(isA<JournalKeyFailure>()));
    gate.complete();
    expect(await first, hasLength(32));
    expect(keys.writes, 1);
  });

  test('legacy vault key remains untouched', () async {
    const oldSlot = 'tong_ledger_snapshot_key_v1';
    keys.values[oldSlot] = 'fictional-old-key';
    await manager.acquire(existingEvidence: false);
    expect(keys.values[oldSlot], 'fictional-old-key');
  });
}
