import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tong_ledger/storage/encrypted_document.dart';

void main() {
  test('AES-GCM encrypted records are not readable in stored envelope', () async {
    final cipher = EncryptedDocument();
    final key = List<int>.generate(32, (i) => i + 1);
    final envelope = await cipher.encrypt(
      'Salary Account: 1500 AUD', key,
    );
    expect(envelope, isNot(contains('Salary Account')));
    expect(await cipher.decrypt(envelope, key), 'Salary Account: 1500 AUD');
  });

  test('tampering or a wrong device key fails authentication', () async {
    final cipher = EncryptedDocument();
    final key = List<int>.filled(32, 1);
    final original = await cipher.encrypt('private', key);
    await expectLater(
      cipher.decrypt(original, List<int>.filled(32, 2)),
      throwsA(isA<Exception>()),
    );
    final document = jsonDecode(original) as Map<String, dynamic>;
    final bytes = base64Decode(document['ciphertext'] as String);
    bytes[0] ^= 1;
    document['ciphertext'] = base64Encode(bytes);
    await expectLater(
      cipher.decrypt(jsonEncode(document), key),
      throwsA(isA<Exception>()),
    );
  });
}
