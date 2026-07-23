import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:uuid/uuid.dart';
import 'package:scanme_app/core/database/hive_service.dart';
import 'package:scanme_app/core/providers/repositories.dart';

/// Vraie implémentation Firebase Auth (téléphone + OTP par SMS).
///
/// Remplace [MockAuthRepository]. Le profil (nom, type de compte) reste
/// mis en cache localement dans Hive pour l'instant — la migration vers
/// Firestore (pour que le profil soit visible par les autres utilisateurs)
/// est une étape séparée.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final _controller = StreamController<Map<String, dynamic>?>.broadcast();

  Map<String, dynamic>? _cachedUser;
  String? _verificationId;
  int? _resendToken;

  FirebaseAuthRepository() {
    _cachedUser = HiveService.getUser();
    _controller.add(_cachedUser);

    // Si Firebase déconnecte l'utilisateur (token expiré, suppression de
    // compte ailleurs, etc.), on vide le cache local en conséquence.
    _auth.authStateChanges().listen((fb.User? fbUser) {
      if (fbUser == null && _cachedUser != null) {
        _cachedUser = null;
        _controller.add(null);
      }
    });
  }

  @override
  Map<String, dynamic>? get currentUser => _cachedUser;

  @override
  Stream<Map<String, dynamic>?> get authStateChanges => _controller.stream;

  /// Envoie le SMS contenant le code OTP au numéro fourni.
  /// [phone] doit être au format international, ex: '+22670000000'.
  @override
  Future<void> sendOtp(String phone) async {
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,

      // Android peut auto-valider le SMS sans que l'utilisateur tape le code.
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (fb.FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete();
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  /// Vérifie le code OTP saisi par l'utilisateur.
  /// Retourne `true` si la connexion Firebase a réussi.
  @override
  Future<bool> verifyOtp(String otp) async {
    if (_verificationId == null) return false;

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final result = await _auth.signInWithCredential(credential);
      if (result.user == null) return false;

      // Si un profil local existe déjà pour cet uid (utilisateur qui se
      // reconnecte), on le recharge directement.
      final existing = HiveService.getUser();
      if (existing != null && existing['uid'] == result.user!.uid) {
        _cachedUser = existing;
        _controller.add(_cachedUser);
      }
      // Sinon, currentUser reste null jusqu'à l'appel de registerProfile()
      // (cas d'un nouvel utilisateur qui doit encore choisir son nom).

      return true;
    } on fb.FirebaseAuthException {
      return false;
    }
  }

  @override
  Future<void> registerProfile({
    required String name,
    required String accountType,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      throw StateError(
        'Aucun utilisateur Firebase authentifié — appelle verifyOtp() avant registerProfile().',
      );
    }

    final user = {
      'uid': fbUser.uid,
      'name': name,
      'phone': fbUser.phoneNumber ?? '',
      'accountType': accountType, // 'particulier' ou 'commercant'
      'photoUrl': '',
    };
    _cachedUser = user;
    await HiveService.saveUser(user);

    // Génère le QR contact par défaut, comme dans le mock.
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
    await _auth.signOut();
    _cachedUser = null;
    await HiveService.clearAll();
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      // Firebase exige une reconnexion récente pour delete() — si ça
      // échoue avec 'requires-recent-login', il faudra renvoyer un OTP
      // juste avant cet appel.
      await fbUser.delete();
    }
    await logout();
  }
}
