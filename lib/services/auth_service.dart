import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  // ── Inscription ───────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? filiere,
    String? university,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'filiere': filiere?.trim() ?? '',
          'university': university?.trim() ?? '',
        },
      );
    } on AuthException catch (e) {
      // Réémet avec un message plus clair
      throw AuthException(_getReadableErrorMessage(e.message));
    } catch (e) {
      throw Exception('Erreur réseau ou serveur. Réessayez.');
    }
  }

  // ── Connexion ─────────────────────────────────────
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthException(_getReadableErrorMessage(e.message));
    } catch (e) {
      throw Exception('Erreur réseau ou serveur. Réessayez.');
    }
  }

  // ── Google ────────────────────────────────────────
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      return await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
    } on AuthException catch (e) {
      throw AuthException(_getReadableErrorMessage(e.message));
    } catch (e) {
      throw Exception('Connexion Google échouée.');
    }
  }

  // ── Reset password ────────────────────────────────
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthException(_getReadableErrorMessage(e.message));
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email.');
    }
  }

  // ── Déconnexion ───────────────────────────────────
  Future<void> signOut() => _client.auth.signOut();

  // ── Helpers ───────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Traduction des messages d'erreur Supabase ─────
  String _getReadableErrorMessage(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('password') && msg.contains('same as email')) {
      return 'Le mot de passe ne doit pas contenir votre adresse email.';
    }
    if (msg.contains('password') && msg.contains('weak')) {
      return 'Mot de passe trop faible. Utilisez au moins 6 caractères avec majuscules, chiffres et symboles.';
    }
    if (msg.contains('password') && msg.contains('common')) {
      return 'Ce mot de passe est trop commun. Choisissez-en un plus sécurisé.';
    }
    if (msg.contains('password') && msg.contains('short')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (msg.contains('user already registered') || msg.contains('already been registered')) {
      return 'Cet email est déjà utilisé. Connectez-vous ou réinitialisez votre mot de passe.';
    }
    if (msg.contains('invalid email')) {
      return 'Format d\'email invalide.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Veuillez confirmer votre email avant de vous connecter.';
    }
    if (msg.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (msg.contains('too many requests')) {
      return 'Trop de tentatives. Réessayez dans quelques minutes.';
    }
    if (msg.contains('network')) {
      return 'Erreur de connexion Internet.';
    }

    // Message par défaut avec la cause originale (pour debug)
    return 'Erreur: $message';
  }
}