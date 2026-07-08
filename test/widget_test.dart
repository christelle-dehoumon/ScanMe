import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:scanme_app/core/providers/repositories.dart';
import 'package:scanme_app/core/utils/qr_link_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // Set up temporary directory for Hive test storage
    tempDir = await Directory.systemTemp.createTemp('scanme_tests');
    Hive.init(tempDir.path);
    
    // Open boxes required by the test instances
    await Hive.openBox('scanme_user_box');
    await Hive.openBox<String>('scanme_personal_qrs');
    await Hive.openBox<String>('scanme_payment_qrs');
    await Hive.openBox<String>('scanme_transactions');
    await Hive.openBox<String>('scanme_demands');
  });

  tearDown(() async {
    // Close and delete Hive files
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('QR Code Parsing Tests', () {
    test('Parse vCard QR Code contact info successfully', () {
      const vcard = 'BEGIN:VCARD\nVERSION:3.0\nFN:Barry Amadou\nTEL;TYPE=CELL:+226 70 12 34 56\nEND:VCARD';
      
      final lines = vcard.split('\n');
      String name = 'Inconnu';
      String phone = '';

      for (var line in lines) {
        if (line.startsWith('FN:')) {
          name = line.substring(3).trim();
        } else if (line.startsWith('TEL;TYPE=CELL:')) {
          phone = line.substring(14).trim();
        }
      }

      expect(name, equals('Barry Amadou'));
      expect(phone, equals('+226 70 12 34 56'));
    });

    test('Parse Payment QR Scheme query parameters', () {
      const paymentUri = 'scanme://payment?phone=%2B226+70+99+99+99&operator=Orange+Money&name=Boutique+K-Fast';
      final uri = Uri.parse(paymentUri);
      
      expect(uri.scheme, equals('scanme'));
      expect(uri.host, equals('payment'));
      
      final params = uri.queryParameters;
      expect(params['phone'], equals('+226 70 99 99 99'));
      expect(params['operator'], equals('Orange Money'));
      expect(params['name'], equals('Boutique K-Fast'));
    });

    test('Parse Social Media QR query parameters (scanme scheme)', () {
      const socialUri = 'scanme://social?ownerPhone=%2B226+76+11+22+33&network=Instagram&username=diallo_pro';
      expect(QrLinkUtils.isSocialQrLink(socialUri), isTrue);

      final params = QrLinkUtils.parseSocialQrParams(socialUri);
      expect(params['ownerPhone'], equals('+226 76 11 22 33'));
      expect(params['network'], equals('Instagram'));
      expect(params['username'], equals('diallo_pro'));
    });

    test('Build and parse HTTPS social QR link', () {
      final link = QrLinkUtils.buildSocialQrLink(
        ownerPhone: '+226 76 11 22 33',
        network: 'Instagram',
        username: 'chris_t_ellee_dhm',
      );

      expect(link, startsWith('https://scanme.app/social?'));
      expect(QrLinkUtils.isSocialQrLink(link), isTrue);

      final params = QrLinkUtils.parseSocialQrParams(link);
      expect(params['ownerPhone'], equals('+226 76 11 22 33'));
      expect(params['network'], equals('Instagram'));
      expect(params['username'], equals('chris_t_ellee_dhm'));
    });
  });

  group('Mock Auth Repository State Rules', () {
    test('Initial user is null before login', () {
      final container = ProviderContainer();
      final authRepo = container.read(authRepositoryProvider);
      
      expect(authRepo.currentUser, isNull);
    });

    test('Verify OTP length rules', () async {
      final container = ProviderContainer();
      final authRepo = container.read(authRepositoryProvider);
      
      final validOtp = await authRepo.verifyOtp('123456');
      final invalidOtp = await authRepo.verifyOtp('1234');
      
      expect(validOtp, isTrue);
      expect(invalidOtp, isFalse);
    });
  });
}
