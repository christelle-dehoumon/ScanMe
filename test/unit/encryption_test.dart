import 'package:flutter_test/flutter_test.dart';
import 'package:scanme_app/core/utils/encryption.dart';

void main() {
  group('EncryptionService Tests', () {
    test('encrypt and decrypt returns original text', () {
      const original = 'Hello World';
      final encrypted = EncryptionService.encrypt(original);
      final decrypted = EncryptionService.decrypt(encrypted);

      expect(decrypted, equals(original));
      expect(encrypted, isNot(equals(original)));
    });

    test('encrypt phone number', () {
      const phoneNumber = '+226701234567';
      final encrypted = EncryptionService.encryptToBase64(phoneNumber);
      final decrypted = EncryptionService.decryptFromBase64(encrypted);

      expect(decrypted, equals(phoneNumber));
    });

    test('same input produces same encrypted output', () {
      const text = 'Test';
      final encrypted1 = EncryptionService.encrypt(text);
      final encrypted2 = EncryptionService.encrypt(text);

      expect(encrypted1, equals(encrypted2));
    });

    test('hash sensitive data is consistent', () {
      const phoneNumber = '+226701234567';
      final hash1 = EncryptionService.hashSensitiveData(phoneNumber);
      final hash2 = EncryptionService.hashSensitiveData(phoneNumber);

      expect(hash1, equals(hash2));
    });

    test('decrypt with wrong data throws exception', () {
      expect(
        () => EncryptionService.decrypt('invalid-base64'),
        throwsException,
      );
    });
  });
}
