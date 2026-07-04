import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  final _supabase = Supabase.instance.client;

  GoogleSignIn get _googleSignIn => GoogleSignIn(
    clientId: kIsWeb
        ? '979672174383-ck7kj7i0c0ndudgq36nsikvf47j9u5g7.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      print('🔑 GOOGLE SIGN-IN START (Web compatible)');

      // ✅ Sur Web, utiliser signInSilently puis signIn
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        // Essayer d'abord silencieusement
        googleUser = await _googleSignIn.signInSilently();

        // Si pas de session, forcer la connexion
        googleUser ??= await _googleSignIn.signIn();
      } else {
        // Sur mobile, signIn direct fonctionne
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) {
        print('❌ GOOGLE ANNULÉ');
        return null;
      }

      print('✅ GOOGLE OK: ${googleUser.email}');

      // Récupérer l'authentification
      final auth = await googleUser.authentication;

      print('✅ idToken: ${auth.idToken != null ? "PRÉSENT (${auth.idToken!.length} chars)" : "ABSENT"}');

      if (auth.idToken != null) {
        // Connexion Supabase avec idToken
        final response = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: auth.idToken!,
          accessToken: auth.accessToken,
        );
        print('✅ SUPABASE OK: ${response.user?.email}');
      } else {
        // Fallback : utiliser l'accessToken seul
        print('⚠️ Pas d\'idToken, tentative avec accessToken...');
        if (auth.accessToken != null) {
          try {
            final response = await _supabase.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: auth.accessToken!,
              accessToken: auth.accessToken,
            );
            print('✅ SUPABASE OK (via accessToken): ${response.user?.email}');
          } catch (e) {
            print('❌ Échec accessToken: $e');
          }
        }
      }

      return googleUser;
    } catch (e) {
      print('❌ ERREUR: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }
}