import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/domain/balanced_journal.dart';
import 'package:tong_ledger/domain/demo_data.dart';
import 'package:tong_ledger/domain/journal_reversal.dart';
import 'package:tong_ledger/storage/journal_revision_codec.dart';
import 'package:tong_ledger/storage/journal_transaction_store.dart';

void main() {
  late JournalRevision state;
  late String encoded;

  setUp(() {
    final initial = BalancedJournal.fromLegacy(createDemoBook());
    final original = initial.batches.firstWhere(
      (batch) => batch.id.startsWith('transaction/'),
    );
    final revised = JournalReversal.append(
      journal: initial, originalId: original.id, effectiveAt: original.at,
    );
    state = JournalRevision(number: 1, journal: revised);
    encoded = JournalRevisionCodec.encode(state);
  });

  test('round trip preserves revision, balances and reversal history', () {
    final actual = JournalRevisionCodec.decode(encoded);
    expect(actual.number, state.number);
    expect(actual.journal.balances, state.journal.balances);
    expect(actual.journal.batches.map((b) => b.id),
      state.journal.batches.map((b) => b.id));
    expect(JournalRevisionCodec.encode(actual), encoded);
  });

  test('unknown schema and negative revision fail closed', () {
    for (final key in ['schema', 'revision']) {
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      data[key] = -1;
      expect(() => JournalRevisionCodec.decode(jsonEncode(data)),
        throwsFormatException);
    }
  });

  test('duplicate account IDs fail closed', () {
    final data = jsonDecode(encoded) as Map<String, dynamic>;
    final accounts = data['accounts'] as List<dynamic>;
    accounts.add(accounts.first);
    expect(() => JournalRevisionCodec.decode(jsonEncode(data)),
      throwsFormatException);
  });

  test('unbalanced posting fails validation', () {
    final data = jsonDecode(encoded) as Map<String, dynamic>;
    final batches = data['batches'] as List<dynamic>;
    final first = batches.first as Map<String, dynamic>;
    final postings = first['postings'] as List<dynamic>;
    final posting = postings.first as Map<String, dynamic>;
    posting['amountCents'] = (posting['amountCents'] as int) + 1;
    expect(() => JournalRevisionCodec.decode(jsonEncode(data)),
      throwsA(isA<JournalIntegrityException>()));
  });

  test('unknown field and noncanonical input are rejected', () {
    final data = jsonDecode(encoded) as Map<String, dynamic>;
    data['unknown'] = true;
    expect(() => JournalRevisionCodec.decode(jsonEncode(data)),
      throwsFormatException);
    expect(() => JournalRevisionCodec.decode(' $encoded'),
      throwsFormatException);
  });
}
