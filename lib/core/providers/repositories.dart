import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanme_app/core/database/hive_service.dart';
import 'package:uuid/uuid.dart';

// ==========================================
// 1. AUTH REPOSITORY INTERFACE & PROVIDER
// ==========================================

abstract class AuthRepository {
  Map<String, dynamic>? get currentUser;
  Stream<Map<String, dynamic>?> get authStateChanges;
  Future<void> sendOtp(String phone);
  Future<bool> verifyOtp(String otp);
  Future<void> registerProfile({required String name, required String accountType});
  Future<void> logout();
  Future<void> deleteAccount();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Vraie auth Firebase (téléphone + OTP). Nécessite que
  // Firebase.initializeApp() ait été appelé dans main.dart au préalable
  // (voir lib/firebase_options.dart généré par `flutterfire configure`).
  return 
 MockAuthRepository();

 
});

// Mock Implementation for testing & demo out of the box
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<Map<String, dynamic>?>.broadcast();
  Map<String, dynamic>? _cachedUser;
  String? _tempPhone;

  MockAuthRepository() {
    _cachedUser = HiveService.getUser();
    _controller.add(_cachedUser);
  }

  @override
  Map<String, dynamic>? get currentUser => _cachedUser;

  @override
  Stream<Map<String, dynamic>?> get authStateChanges => _controller.stream;

  @override
  Future<void> sendOtp(String phone) async {
    _tempPhone = phone;
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 1200));
  }

  @override
  Future<bool> verifyOtp(String otp) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // Accept any 6-digit OTP for demo convenience
    if (otp.length == 6) {
      if (_cachedUser == null) {
        // Not fully registered yet (waiting for profile setup)
        return true;
      }
      _controller.add(_cachedUser);
      return true;
    }
    return false;
  }

  @override
  Future<void> registerProfile({required String name, required String accountType}) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final user = {
      'uid': const Uuid().v4(),
      'name': name,
      'phone': _tempPhone ?? '+226 70 00 00 00',
      'accountType': accountType, // 'particulier' or 'commercant'
      'photoUrl': '',
    };
    _cachedUser = user;
    await HiveService.saveUser(user);
    
    // Automatically generate a default offline telephone contact QR code for the user
    final contactQrId = const Uuid().v4();
    await HiveService.savePersonalQr({
      'id': contactQrId,
      'type': 'contact',
      'title': 'Mon Contact',
      'phone': user['phone'],
      'name': user['name'],
      'isActive': true,
    });

    _controller.add(_cachedUser);
  }

  @override
  Future<void> logout() async {
    _cachedUser = null;
    await HiveService.clearAll(); // Clean slate on logout
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    await logout();
  }
}

// ==========================================
// 2. CONTACTS REPOSITORY INTERFACE & PROVIDER
// ==========================================

abstract class ContactsRepository {
  Future<List<Map<String, dynamic>>> getPersonalQrs();
  Future<void> savePersonalQr(Map<String, dynamic> qr);
  Future<void> deletePersonalQr(String id);
  
  Future<List<Map<String, dynamic>>> getScannedContacts();
  Future<void> saveScannedContact(Map<String, dynamic> contact);
  Future<void> deleteScannedContact(String id);
  
  Future<void> sendSocialAccessRequest({
    required String targetUserPhone,
    required String requesterPhone,
    required String networkType,
    required String networkUsername,
  });
  Future<List<Map<String, dynamic>>> getDemands();
  Future<void> respondToDemand(String demandId, String status); // 'accepted', 'rejected'
  Future<void> revokeSocialAccess(String demandId);
}

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return MockContactsRepository(ref);
});

class MockContactsRepository implements ContactsRepository {
  final Ref _ref;

  MockContactsRepository(this._ref);

  @override
  Future<List<Map<String, dynamic>>> getPersonalQrs() async {
    return HiveService.getPersonalQrs();
  }

  @override
  Future<void> savePersonalQr(Map<String, dynamic> qr) async {
    await HiveService.savePersonalQr(qr);
  }

  @override
  Future<void> deletePersonalQr(String id) async {
    await HiveService.deletePersonalQr(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getScannedContacts() async {
    return HiveService.getScannedContacts();
  }

  @override
  Future<void> saveScannedContact(Map<String, dynamic> contact) async {
    await HiveService.saveScannedContact(contact);
  }

  @override
  Future<void> deleteScannedContact(String id) async {
    await HiveService.deleteScannedContact(id);
  }

  @override
  Future<void> sendSocialAccessRequest({
    required String targetUserPhone,
    required String requesterPhone,
    required String networkType,
    required String networkUsername,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final id = const Uuid().v4();
    final demand = {
      'id': id,
      'targetUserPhone': targetUserPhone,
      'requesterPhone': requesterPhone,
      'requesterName': _ref.read(authRepositoryProvider).currentUser?['name'] ?? 'Inconnu',
      'networkType': networkType,
      'networkUsername': networkUsername,
      'status': 'pending', // pending, accepted, rejected
      'timestamp': DateTime.now().toIso8601String(),
    };
    await HiveService.saveDemand(demand);
  }

  @override
  Future<List<Map<String, dynamic>>> getDemands() async {
    return HiveService.getDemands();
  }

  @override
  Future<void> respondToDemand(String demandId, String status) async {
    final list = HiveService.getDemands();
    final item = list.firstWhere((element) => element['id'] == demandId);
    item['status'] = status;
    await HiveService.saveDemand(item);
  }

  @override
  Future<void> revokeSocialAccess(String demandId) async {
    await HiveService.deleteDemand(demandId);
  }
}

// ==========================================
// 3. PAYMENTS REPOSITORY INTERFACE & PROVIDER
// ==========================================

abstract class PaymentsRepository {
  Future<List<Map<String, dynamic>>> getPaymentQrs();
  Future<void> savePaymentQr(Map<String, dynamic> qr);
  Future<void> deletePaymentQr(String id);
  
  Future<List<Map<String, dynamic>>> getTransactions();
  Future<void> addTransaction(Map<String, dynamic> transaction);
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return MockPaymentsRepository();
});

class MockPaymentsRepository implements PaymentsRepository {
  @override
  Future<List<Map<String, dynamic>>> getPaymentQrs() async {
    final list = HiveService.getPaymentQrs();
    if (list.isEmpty) {
      // Seed default payment QRs for testing if empty
      final user = HiveService.getUser();
      if (user != null) {
        final omId = const Uuid().v4();
        final waveId = const Uuid().v4();
        
        final defaultQrs = [
          {
            'id': omId,
            'name': '${user['name']} (Orange)',
            'phone': user['phone'],
            'operator': 'Orange Money',
            'isActive': true,
          },
          {
            'id': waveId,
            'name': '${user['name']} (Wave)',
            'phone': user['phone'],
            'operator': 'Wave',
            'isActive': true,
          }
        ];
        
        for (var qr in defaultQrs) {
          await HiveService.savePaymentQr(qr);
        }
        return defaultQrs;
      }
    }
    return list;
  }

  @override
  Future<void> savePaymentQr(Map<String, dynamic> qr) async {
    await HiveService.savePaymentQr(qr);
  }

  @override
  Future<void> deletePaymentQr(String id) async {
    await HiveService.deletePaymentQr(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final list = HiveService.getTransactions();
    if (list.isEmpty) {
      // Seed mock transactions
      final seedList = [
        {
          'id': const Uuid().v4(),
          'beneficiaryName': 'Kaboré Alassane',
          'phone': '+226 70 11 22 33',
          'operator': 'Orange Money',
          'amount': 2500.0,
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'reference': 'TXN-${const Uuid().v4().substring(0, 8).toUpperCase()}',
          'type': 'sent', // sent or received
        },
        {
          'id': const Uuid().v4(),
          'beneficiaryName': 'Sama Aminata',
          'phone': '+226 67 44 55 66',
          'operator': 'Wave',
          'amount': 5000.0,
          'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          'reference': 'TXN-${const Uuid().v4().substring(0, 8).toUpperCase()}',
          'type': 'sent',
        },
        {
          'id': const Uuid().v4(),
          'beneficiaryName': 'Supermarché Marina',
          'phone': '+226 60 77 88 99',
          'operator': 'Moov Money',
          'amount': 12000.0,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
          'reference': 'TXN-${const Uuid().v4().substring(0, 8).toUpperCase()}',
          'type': 'sent',
        }
      ];
      for (var tx in seedList) {
        await HiveService.saveTransaction(tx);
      }
      return seedList;
    }
    return list;
  }

  @override
  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    await HiveService.saveTransaction(transaction);
  }
}
