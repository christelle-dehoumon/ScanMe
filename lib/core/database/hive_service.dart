import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static const String _userBoxName = 'scanme_user_box';
  static const String _scannedContactsBoxName = 'scanme_scanned_contacts';
  static const String _personalQrsBoxName = 'scanme_personal_qrs';
  static const String _paymentQrsBoxName = 'scanme_payment_qrs';
  static const String _transactionsBoxName = 'scanme_transactions';
  static const String _demandsBoxName = 'scanme_demands';

  static Future<void> init() async {
    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(directory.path);
    } else {
      await Hive.initFlutter();
    }

    // Open required boxes
    await Hive.openBox(_userBoxName);
    await Hive.openBox<String>(_scannedContactsBoxName);
    await Hive.openBox<String>(_personalQrsBoxName);
    await Hive.openBox<String>(_paymentQrsBoxName);
    await Hive.openBox<String>(_transactionsBoxName);
    await Hive.openBox<String>(_demandsBoxName);
  }

  // --- USER METHODS ---
  static Box get _userBox => Hive.box(_userBoxName);

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await _userBox.put('profile', jsonEncode(userData));
  }

  static Map<String, dynamic>? getUser() {
    final raw = _userBox.get('profile');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> deleteUser() async {
    await _userBox.delete('profile');
  }

  // --- SCANNED CONTACTS METHODS ---
  static Box<String> get _scannedContactsBox => Hive.box<String>(_scannedContactsBoxName);

  static List<Map<String, dynamic>> getScannedContacts() {
    return _scannedContactsBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> saveScannedContact(Map<String, dynamic> contact) async {
    final id = contact['id'] ?? contact['phone'];
    await _scannedContactsBox.put(id, jsonEncode(contact));
  }

  static Future<void> deleteScannedContact(String id) async {
    await _scannedContactsBox.delete(id);
  }

  // --- PERSONAL CONTACT/SOCIAL QR METHODS ---
  static Box<String> get _personalQrsBox => Hive.box<String>(_personalQrsBoxName);

  static List<Map<String, dynamic>> getPersonalQrs() {
    return _personalQrsBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> savePersonalQr(Map<String, dynamic> qrData) async {
    final id = qrData['id'];
    await _personalQrsBox.put(id, jsonEncode(qrData));
  }

  static Future<void> deletePersonalQr(String id) async {
    await _personalQrsBox.delete(id);
  }

  // --- PAYMENT QR METHODS ---
  static Box<String> get _paymentQrsBox => Hive.box<String>(_paymentQrsBoxName);

  static List<Map<String, dynamic>> getPaymentQrs() {
    return _paymentQrsBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> savePaymentQr(Map<String, dynamic> paymentQr) async {
    final id = paymentQr['id'];
    await _paymentQrsBox.put(id, jsonEncode(paymentQr));
  }

  static Future<void> deletePaymentQr(String id) async {
    await _paymentQrsBox.delete(id);
  }

  // --- TRANSACTION HISTORY METHODS ---
  static Box<String> get _transactionsBox => Hive.box<String>(_transactionsBoxName);

  static List<Map<String, dynamic>> getTransactions() {
    final list = _transactionsBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    // Sort chronologically (newest first)
    list.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    return list;
  }

  static Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    final id = transaction['id'];
    await _transactionsBox.put(id, jsonEncode(transaction));
  }

  // --- AUTHORIZATION DEMANDS METHODS ---
  static Box<String> get _demandsBox => Hive.box<String>(_demandsBoxName);

  static List<Map<String, dynamic>> getDemands() {
    final list = _demandsBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    // Sort chronologically (newest first)
    list.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    return list;
  }

  static Future<void> saveDemand(Map<String, dynamic> demand) async {
    final id = demand['id'];
    await _demandsBox.put(id, jsonEncode(demand));
  }

  static Future<void> deleteDemand(String id) async {
    await _demandsBox.delete(id);
  }

  // --- GENERAL APP RESET ---
  static Future<void> clearAll() async {
    await _userBox.clear();
    await _scannedContactsBox.clear();
    await _personalQrsBox.clear();
    await _paymentQrsBox.clear();
    await _transactionsBox.clear();
    await _demandsBox.clear();
  }
}
