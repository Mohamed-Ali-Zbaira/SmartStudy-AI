import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile_model.dart';

class ProfileService {
  final _client = Supabase.instance.client;

  // ── Récupérer son propre profil ─────────────────────────
  Future<ProfileModel?> getMyProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await _client
          .from(SupabaseConfig.tableProfiles)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromMap(data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  // ── Récupérer un profil par ID ──────────────────────────
  Future<ProfileModel?> getProfileById(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConfig.tableProfiles)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromMap(data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  // ── Mettre à jour son profil ────────────────────────────
  Future<void> updateProfile({
    String? fullName,
    String? university,
    String? fieldOfStudy,
    String? avatarUrl,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null && fullName.isNotEmpty) {
        updates['full_name'] = fullName.trim();
      }
      if (university != null) {
        updates['university'] = university.trim().isEmpty ? null : university.trim();
      }
      if (fieldOfStudy != null) {
        updates['field_of_study'] = fieldOfStudy.trim().isEmpty ? null : fieldOfStudy.trim();
      }
      if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
      }

      await _client
          .from(SupabaseConfig.tableProfiles)
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  // ── Upload d'avatar ─────────────────────────────────────
  Future<String> uploadAvatar(String userId, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = '$userId/$fileName';

      await _client.storage
          .from(SupabaseConfig.bucketAvatars)
          .upload(
        storagePath,
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      final publicUrl = _client.storage
          .from(SupabaseConfig.bucketAvatars)
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'avatar: $e');
    }
  }

  // ── Supprimer l'avatar ──────────────────────────────────
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extraire le chemin du fichier depuis l'URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(SupabaseConfig.bucketAvatars);

      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

        await _client.storage
            .from(SupabaseConfig.bucketAvatars)
            .remove([filePath]);
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'avatar: $e');
    }
  }

  // ── Créer un profil (si pas auto-créé par trigger) ──────
  Future<void> createProfile({
    required String userId,
    required String email,
    required String fullName,
    String? university,
    String? fieldOfStudy,
  }) async {
    try {
      await _client.from(SupabaseConfig.tableProfiles).insert({
        'id': userId,
        'email': email,
        'full_name': fullName.trim(),
        'university': university?.trim(),
        'field_of_study': fieldOfStudy?.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }

  // ── Vérifier si le profil existe ────────────────────────
  Future<bool> profileExists(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConfig.tableProfiles)
          .select('id')
          .eq('id', userId);

      return data.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ── Récupérer les statistiques utilisateur ──────────────
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {'courses': 0, 'quizzes': 0, 'studyTime': 0};

      // Nombre de cours
      final coursesData = await _client
          .from(SupabaseConfig.tableCourses)
          .select('id')
          .eq('user_id', userId);

      // Nombre de quiz complétés
      final quizzesData = await _client
          .from(SupabaseConfig.tableQuizzes)
          .select('id')
          .eq('user_id', userId)
          .not('completed_at', 'is', null);

      // Temps d'étude total (en secondes)
      final sessionsData = await _client
          .from(SupabaseConfig.tableStudySessions)
          .select('duration_seconds')
          .eq('user_id', userId)
          .not('duration_seconds', 'is', null);

      int totalSeconds = 0;
      for (final session in sessionsData) {
        totalSeconds += (session['duration_seconds'] as int? ?? 0);
      }

      return {
        'courses': coursesData.length,
        'quizzes': quizzesData.length,
        'studyTime': totalSeconds,
      };
    } catch (e) {
      return {'courses': 0, 'quizzes': 0, 'studyTime': 0};
    }
  }

  // ── Helper: Utilisateur actuel ──────────────────────────
  String? get currentUserId => _client.auth.currentUser?.id;
  String? get currentUserEmail => _client.auth.currentUser?.email;
  bool get isLoggedIn => _client.auth.currentSession != null;
}