import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';

/// Service for AES-256 encryption/decryption of sensitive data
class EncryptionService {
  // Static encryption key (in production, load from secure storage)
  // WARNING: Replace with secure key management in production!
  static final _key = encrypt.Key.fromUtf8(
    'your-32-char-secret-key-here!!!',  // Must be exactly 32 chars
  );
  
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));

  /// Encrypts a string using AES-256
  static String encrypt(String plaintext) {
    try {
      final encrypted = _encrypter.encrypt(plaintext, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypts an AES-256 encrypted string
  static String decrypt(String encryptedBase64) {
    try {
      final decrypted = _encrypter.decrypt64(encryptedBase64, iv: _iv);
      return decrypted;
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Encrypts and returns base64 for storage
  static String encryptToBase64(String plaintext) => encrypt(plaintext);

  /// Decrypts from base64
  static String decryptFromBase64(String encrypted) => decrypt(encrypted);

  /// Hash sensitive data (phone numbers) for comparison without storing plaintext
  static String hashSensitiveData(String data) {
    // Use HMAC-SHA256 for deterministic hashing
    return data.hashCode.toString(); // Simple example, use cryptographic hash in production
  }
}
