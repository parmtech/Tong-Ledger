import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// AES-256-GCM authenticated encryption.
/// Only the encrypted envelope may be written to disk.
class EncryptedDocument {
  EncryptedDocument() : _algorithm = AesGcm.with256bits();

  final AesGcm _algorithm;
  static const version = 1;

  Future<String> encrypt(String data, List<int> key) async {
    if (key.length != 32) throw ArgumentError('A 256-bit key is required.');
    final nonce = _algorithm.newNonce();
    final secret = await _algorithm.encrypt(
      utf8.encode(data),
      secretKey: SecretKey(key),
      nonce: nonce,
    );
    return jsonEncode({
      'format': version,
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(secret.cipherText),
      'mac': base64Encode(secret.mac.bytes),
    });
  }

  Future<String> decrypt(String envelope, List<int> key) async {
    if (key.length != 32) throw ArgumentError('A 256-bit key is required.');
    final parsed = (jsonDecode(envelope) as Map).cast<String, dynamic>();
    if (parsed['format'] != version) {
      throw const FormatException('Unsupported encrypted file format.');
    }
    final nonce = base64Decode(parsed['nonce'] as String);
    final ciphertext = base64Decode(parsed['ciphertext'] as String);
    final mac = base64Decode(parsed['mac'] as String);
    if (nonce.length != 12 || mac.length != 16) {
      throw const FormatException('Invalid encrypted document header.');
    }
    final plaintext = await _algorithm.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(key),
    );
    return utf8.decode(plaintext);
  }
}
