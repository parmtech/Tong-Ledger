import 'dart:convert';
import 'dart:io';

import '../domain/balanced_journal.dart';
import 'encrypted_document.dart';
import 'finance_book_codec.dart';
import 'journal_migration_preflight.dart';

/// Experimental encrypted migration fixture. This is NOT an active vault,
/// append-only journal database, or an activation/rollback implementation.
/// Callers supply a staging-only directory and a 256-bit test/migration key.
class EncryptedJournalStage {
  EncryptedJournalStage({EncryptedDocument? cipher})
      : _cipher = cipher ?? EncryptedDocument();

  final EncryptedDocument _cipher;
  static const maxEnvelopeBytes = 64 * 1024 * 1024;

  /// Creates a unique, ciphertext-only candidate and verifies readback.
  /// Never modifies the source vault or replaces an existing candidate.
  Future<File> create({
    required Directory stagingRoot,
    required String sourceSnapshot,
    required List<int> key,
  }) async {
    final canonical = FinanceBookCodec.encode(
      FinanceBookCodec.decode(sourceSnapshot),
    );
    final journal = JournalMigrationPreflight.verify(
      sourceSnapshot: sourceSnapshot,
      candidateSnapshot: canonical,
    );
    final payload = _payload(canonical, journal);
    final envelope = await _cipher.encrypt(payload, key);
    if (utf8.encode(envelope).length > maxEnvelopeBytes) {
      throw const FormatException('Encrypted stage exceeds size limit.');
    }

    final directory = await stagingRoot.createTemp('journal-stage-');
    final file = File('${directory.path}${Platform.pathSeparator}candidate.enc');
    try {
      await file.writeAsString(envelope, flush: true);
      await verify(file: file, sourceSnapshot: sourceSnapshot, key: key);
      return file;
    } catch (_) {
      // Only remove the unique directory allocated by this invocation.
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  /// Re-authenticates ciphertext and compares all stored postings with a
  /// fresh, independently calculated projection of the supplied source.
  Future<BalancedJournal> verify({
    required File file,
    required String sourceSnapshot,
    required List<int> key,
  }) async {
    if (await file.length() > maxEnvelopeBytes) {
      throw const FormatException('Encrypted stage exceeds size limit.');
    }
    final bytes = await file.openRead().fold<List<int>>([], (all, chunk) {
      if (all.length + chunk.length > maxEnvelopeBytes) {
        throw const FormatException('Encrypted stage exceeds size limit.');
      }
      return all..addAll(chunk);
    });
    final payload = await _cipher.decrypt(utf8.decode(bytes), key);
    final data = jsonDecode(payload);
    if (data is! Map<String, dynamic> ||
        data['format'] != 1 ||
        data['snapshot'] is! String) {
      throw const FormatException('Unsupported journal stage.');
    }
    final snapshot = data['snapshot'] as String;
    final journal = JournalMigrationPreflight.verify(
      sourceSnapshot: sourceSnapshot,
      candidateSnapshot: snapshot,
    );
    if (payload != _payload(snapshot, journal)) {
      throw const FormatException('Journal stage postings do not match.');
    }
    return journal;
  }

  String _payload(String snapshot, BalancedJournal journal) => jsonEncode({
    'format': 1,
    'snapshot': snapshot,
    'accounts': [
      for (final account in journal.accounts.values)
        {'id': account.id, 'type': account.type.name,
          'currency': account.currency},
    ],
    'batches': [
      for (final batch in journal.batches)
        {'id': batch.id, 'at': batch.at.toUtc().toIso8601String(),
          'category': batch.category,
          'postings': [
            for (final posting in batch.postings)
              {'accountId': posting.accountId, 'side': posting.side.name,
                'amountCents': posting.amountCents,
                'currency': posting.currency},
          ]},
    ],
  });
}
