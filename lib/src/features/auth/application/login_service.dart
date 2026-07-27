import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrim/src/features/auth/application/account_profile_service.dart';
import 'package:skrim/src/features/auth/application/auth_service.dart';

final loginServiceProvider = Provider<LoginService>((ref) {
  return LoginService(
    ref.watch(authServiceProvider),
    ref.watch(accountProfileServiceProvider),
  );
});

class LoginService {
  LoginService(this._authService, this._accountProfileService);

  final AuthService _authService;
  final AccountProfileService _accountProfileService;

  bool get isSignedIn => _authService.currentUser != null;

  String get termsRequiredMessage =>
      'Accetta termini e condizioni per creare un account';

  bool requiresAcceptedTerms({
    required bool isLogin,
    required bool acceptedTerms,
  }) {
    return !isLogin && !acceptedTerms;
  }

  String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Inserisci il nome';
    return null;
  }

  String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Inserisci il cognome';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Inserisci la tua email';
    return null;
  }

  String? validatePassword(String? value, {required bool isLogin}) {
    if (value == null || value.trim().isEmpty) {
      return 'Inserisci la password';
    }
    if (!isLogin && value.length < 6) {
      return 'La password deve avere almeno 6 caratteri';
    }
    return null;
  }

  Future<void> submitWithEmail({
    required bool isLogin,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? photoPath,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();
    if (isLogin) {
      await _authService.signInWithEmail(normalizedEmail, normalizedPassword);
    } else {
      await _authService.registerWithEmail(normalizedEmail, normalizedPassword);
    }
    await _authService.waitForSignedIn();
    if (isLogin) return;
    await _accountProfileService.saveProfile(
      AccountProfileDraft(
        firstName: firstName,
        lastName: lastName,
        photoPath: photoPath,
      ),
    );
  }

  Future<void> submitWithGoogle() async {
    await _authService.signInWithGoogle();
    await _authService.waitForSignedIn();
  }

  Future<String?> pickProfilePhotoPath() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path?.trim();
    if (path == null || path.isEmpty) return null;
    return path;
  }

  String errorMessage(Object error, {required bool isGoogle}) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('configuration-not-found')) {
      return isGoogle
          ? 'Firebase Auth non è configurato: abilita Google nella console Firebase.'
          : 'Firebase Auth non è configurato: abilita Email/Password e Google nella console Firebase.';
    }
    if (isGoogle) return 'Accesso con Google fallito o annullato: $error';
    if (errorStr.contains('user-not-found') ||
        errorStr.contains('invalid-credential')) {
      return 'Credenziali non valide';
    }
    if (errorStr.contains('wrong-password')) return 'Password errata';
    if (errorStr.contains('email-already-in-use')) return 'Email già in uso';
    if (errorStr.contains('weak-password')) {
      return 'La password deve avere almeno 6 caratteri';
    }
    if (errorStr.contains('invalid-email')) return 'Email non valida';
    return 'Si è verificato un errore';
  }
}
