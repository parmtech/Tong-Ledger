import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../domain/finance_models.dart';
import 'finance_book_codec.dart';

/// A portable encrypted backup independent of the Android Keystore.
///
/// A user-supplied passphrase derives a separate encryption key using PBKDF2.
/// Neither a device key nor the unencrypted finance JSON is exported.
class PassphraseBackup {
  PassphraseBackup()
      : _kdf = Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: iterations,
          bits: 256,
        ),
        _aes = AesGcm.with256bits();

  static const int iterations = 310000;
  static const int maxBackupBytes = 16 * 1024 * 1024;
  static const int minimumPassphraseLength = 12;
  static const String formatName = 'tong-ledger-encrypted-backup';
  static const String kdfName = 'PBKDF2-HMAC-SHA256';
  static const String _aad = 'tong-ledger-backup/v1';

  final Pbkdf2 _kdf;
  final AesGcm _aes;

  Future<String> create(FinanceBook book, String passphrase) async {
    _checkPassphrase(passphrase);
    final plaintext = FinanceBookCodec.encode(book);
    FinanceBookCodec.decode(plaintext);
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final nonce = _aes.newNonce();
    final key = await _kdf.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    final encrypted = await _aes.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
      aad: utf8.encode(_aad),
    );
    final output = jsonEncode(<String, Object>{
      'format': formatName,
      'version': 1,
      'kdf': kdfName,
      'iterations': iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(encrypted.cipherText),
      'mac': base64Encode(encrypted.mac.bytes),
    });
    if (utf8.encode(output).length > maxBackupBytes) {
      throw const FormatException('Backup exceeds the maximum supported size.');
    }
    return output;
  }

  Future<FinanceBook> open(String backup, String passphrase) async {
    if (utf8.encode(backup).length > maxBackupBytes) {
      throw const FormatException('Backup file is too large.');
    }
    // Import accepts the exact cryptographic scheme and work factor only.
    final Map<String, dynamic> header;
    try {
      header = (jsonDecode(backup) as Map).cast<String, dynamic>();
    } catch (_) {
      throw const FormatException('Not a recognised Tong Ledger backup.');
    }
    if (header['format'] != formatName ||
        header['version'] != 1 ||
        header['kdf'] != kdfName ||
        header['iterations'] != iterations) {
      throw const FormatException('Unsupported backup format or work factor.');
    }

    final List<int> salt;
    final List<int> nonce;
    final List<int> ciphertext;
    final List<int> mac;
    try {
      salt = base64Decode(header['salt'] as String);
      nonce = base64Decode(header['nonce'] as String);
      ciphertext = base64Decode(header['ciphertext'] as String);
      mac = base64Decode(header['mac'] as String);
    } catch (_) {
      throw const FormatException('Invalid backup envelope.');
    }
    if (salt.length != 16 || nonce.length != 12 ||
        mac.length != 16 || ciphertext.length > maxBackupBytes) {
      throw const FormatException('Invalid encrypted backup structure.');
    }
    final key = await _kdf.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    try {
      final plaintext = await _aes.decrypt(
        SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
        aad: utf8.encode(_aad),
      );
      return FinanceBookCodec.decode(utf8.decode(plaintext));
    } on SecretBoxAuthenticationError {
      throw const FormatException(
        'Incorrect password or a modified/corrupted backup file.',
      );
    }
  }

  void _checkPassphrase(String passphrase) {
    if (passphrase.runes.length < minimumPassphraseLength) {
      throw const FormatException(
        'Use a password with at least 12 characters.',
      );
    }
  }
}
