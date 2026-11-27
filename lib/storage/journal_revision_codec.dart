import 'dart:convert';

import '../domain/balanced_journal.dart';
import 'journal_transaction_store.dart';

/// Versioned journal persistence representation. This contains financial data
/// and must only be stored inside an authenticated encrypted boundary.
class JournalRevisionCodec {
  const JournalRevisionCodec._();

  static String encode(JournalRevision state) => jsonEncode({
    'schema': 1,
    'revision': state.number,
    'accounts': [
      for (final a in state.journal.accounts.values)
        {'id': a.id, 'type': a.type.name, 'currency': a.currency},
    ],
    'batches': [
      for (final b in state.journal.batches)
        {
          'id': b.id, 'at': b.at.toUtc().toIso8601String(),
          'category': b.category,
          'postings': [
            for (final p in b.postings)
              {'accountId': p.accountId, 'side': p.side.name,
                'amountCents': p.amountCents, 'currency': p.currency},
          ],
        },
    ],
  });

  static JournalRevision decode(String payload) {
    final data = _map(jsonDecode(payload));
    final revision = data['revision'];
    if (data['schema'] != 1 || revision is! int || revision < 0) {
      throw const FormatException('Unsupported journal revision.');
    }
    final accounts = <String, JournalAccount>{};
    for (final value in _list(data['accounts'])) {
      final a = _map(value);
      final id = _string(a['id']);
      if (accounts.containsKey(id)) {
        throw const FormatException('Duplicate journal account.');
      }
      accounts[id] = JournalAccount(
        id: id, type: _enum(JournalAccountType.values, a['type']),
        currency: _currency(a['currency']),
      );
    }
    final batches = <JournalBatch>[];
    for (final value in _list(data['batches'])) {
      final b = _map(value);
      final rawAt = _string(b['at']);
      final at = DateTime.tryParse(rawAt);
      if (at == null || !at.isUtc || at.toIso8601String() != rawAt) {
        throw const FormatException('Invalid journal timestamp.');
      }
      final category = b['category'];
      if (category != null && category is! String) {
        throw const FormatException('Invalid journal category.');
      }
      final postings = <JournalPosting>[];
      for (final item in _list(b['postings'])) {
        final p = _map(item);
        final amount = p['amountCents'];
        if (amount is! int) {
          throw const FormatException('Invalid journal amount.');
        }
        postings.add(JournalPosting(
          accountId: _string(p['accountId']),
          side: _enum(JournalSide.values, p['side']),
          amountCents: amount, currency: _currency(p['currency']),
        ));
      }
      batches.add(JournalBatch(
        id: _string(b['id']), at: at, category: category as String?,
        postings: postings,
      ));
    }
    final result = JournalRevision(
      number: revision,
      journal: BalancedJournal(accounts: accounts, batches: batches),
    );
    // Only canonical, understood fields may cross the persistence boundary.
    // This also rejects duplicate JSON keys and unknown extensions.
    if (encode(result) != payload) {
      throw const FormatException('Noncanonical journal revision.');
    }
    return result;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected journal object.');
    }
    return value;
  }

  static List<dynamic> _list(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Expected journal list.');
    }
    return value;
  }

  static String _string(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Invalid journal identifier.');
    }
    return value;
  }

  static String _currency(Object? value) {
    final code = _string(value);
    if (code != 'AUD') {
      throw const FormatException('Unsupported journal currency.');
    }
    return code;
  }

  static T _enum<T extends Enum>(List<T> values, Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const FormatException('Unknown journal enum.');
  }
}
