import 'dart:io';

import 'finance_book_codec.dart';
import 'journal_migration_preflight.dart';
import 'journal_revision_codec.dart';
import 'journal_transaction_store.dart';
import 'sqlcipher_journal_stage.dart';

/// Creates and independently reopens a journal and legacy snapshot candidate.
/// No active vault or activation is performed here.
/// Only caller-owned private staging directories may be used.
class SqlCipherMigrationCandidate {
  const SqlCipherMigrationCandidate._();

  static String _expected(String sourceSnapshot) {
    final journal = JournalMigrationPreflight.verify(
      sourceSnapshot: sourceSnapshot,
      candidateSnapshot: sourceSnapshot,
    );
    return JournalRevisionCodec.encode(
      JournalRevision(number: 0, journal: journal),
    );
  }

  static Future<File> create({
    required Directory stagingRoot,
    required String sourceSnapshot,
    required List<int> key,
  }) async {
    final expected = JournalRevisionCodec.decode(_expected(sourceSnapshot));
    final stage = await SqlCipherJournalStage.create(
      stagingRoot: stagingRoot, initial: expected.journal, key: key,
      legacySnapshot: sourceSnapshot,
    );
    final file = stage.file;
    try {
      await stage.close();
      await verify(file: file, sourceSnapshot: sourceSnapshot, key: key);
      return file;
    } catch (_) {
      // This directory was uniquely allocated by create(), never supplied
      // by a caller as the legacy vault location.
      await file.parent.delete(recursive: true);
      rethrow;
    }
  }

  static Future<void> verify({
    required File file,
    required String sourceSnapshot,
    required List<int> key,
  }) async {
    final expected = _expected(sourceSnapshot);
    final stage = await SqlCipherJournalStage.reopen(file: file, key: key);
    try {
      final actual = JournalRevisionCodec.encode(await stage.read());
      final canonicalSource = FinanceBookCodec.encode(
        FinanceBookCodec.decode(sourceSnapshot),
      );
      final storedSource = await stage.readLegacySnapshot();
      if (storedSource != canonicalSource) {
        throw const FormatException('Staged legacy metadata differs from source.');
      }
      if (actual != expected) {
        throw const FormatException('Staged journal differs from source.');
      }
    } finally {
      await stage.close();
    }
  }
}
