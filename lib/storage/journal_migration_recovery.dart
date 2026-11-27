import 'dart:io';

import 'journal_key_manager.dart';
import 'sqlcipher_migration_candidate.dart';

class JournalStageRecoveryFailure implements Exception {
  const JournalStageRecoveryFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A dedicated, app-owned staging directory must contain either no entries
/// or exactly one candidate allocated by SqlCipherJournalStage.create.
/// Unknown, partial or ambiguous evidence is never automatically deleted.
class JournalStageEvidence {
  const JournalStageEvidence._();

  static Future<File?> inspect(Directory root) async {
    if (await FileSystemEntity.type(root.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const JournalStageRecoveryFailure('Invalid staging directory.');
    }
    final entries = await root.list(followLinks: false).toList();
    if (entries.isEmpty) return null;
    if (entries.length != 1 || entries.single is! Directory) {
      throw const JournalStageRecoveryFailure('Ambiguous staging evidence.');
    }
    final stage = entries.single as Directory;
    final name = stage.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (!name.startsWith('sqlcipher-stage-')) {
      throw const JournalStageRecoveryFailure('Unrecognized staging evidence.');
    }
    final file = File('${stage.path}${Platform.pathSeparator}journal.db');
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file || await file.length() == 0) {
      throw const JournalStageRecoveryFailure('Incomplete database candidate.');
    }
    // Native rollback/WAL sidecars can be necessary for reopening a valid
    // candidate. Refuse unexpected files without deleting any evidence.
    for (final entity in await stage.list(followLinks: false).toList()) {
      final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (entity is! File || !const {
        'journal.db', 'journal.db-journal', 'journal.db-wal', 'journal.db-shm',
      }.contains(name)) {
        throw const JournalStageRecoveryFailure('Unexpected staging evidence.');
      }
    }
    return file;
  }
}

/// Staging-only restart coordinator. No production activation or app writes.
/// The caller must own the directory and serialize all access across isolates,
/// processes and other services. This guard only covers this Dart instance.
class JournalMigrationRecovery {
  JournalMigrationRecovery(this._keys);

  final JournalKeyManager _keys;
  bool _working = false;

  Future<File> prepareOrResume({
    required Directory stagingRoot,
    required String sourceSnapshot,
  }) async {
    if (_working) {
      throw const JournalStageRecoveryFailure('Migration already in progress.');
    }
    _working = true;
    try {
      final existing = await JournalStageEvidence.inspect(stagingRoot);
      final key = await _keys.acquire(existingEvidence: existing != null);
      if (existing != null) {
        await SqlCipherMigrationCandidate.verify(
          file: existing, sourceSnapshot: sourceSnapshot, key: key,
        );
        return existing;
      }
      return await SqlCipherMigrationCandidate.create(
        stagingRoot: stagingRoot, sourceSnapshot: sourceSnapshot, key: key,
      );
    } finally {
      _working = false;
    }
  }
}
