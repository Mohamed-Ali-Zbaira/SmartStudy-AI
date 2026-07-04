import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/course_model.dart';

class CourseService {
  final _client = Supabase.instance.client;

  // ─── Récupérer les cours de l'utilisateur ───────────────
  Future<List<CourseModel>> getUserCourses() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await _client
          .from(SupabaseConfig.tableCourses)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) => CourseModel.fromMap(json)).toList();
    } catch (e) {
      print('❌ Error loading courses: $e');
      return [];
    }
  }

  // ─── Récupérer un cours par ID ──────────────────────────
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      final data = await _client
          .from(SupabaseConfig.tableCourses)
          .select()
          .eq('id', courseId)
          .maybeSingle();

      if (data == null) return null;
      return CourseModel.fromMap(data);
    } catch (e) {
      print('❌ Error loading course: $e');
      return null;
    }
  }

  // ─── Créer un nouveau cours ─────────────────────────────
  Future<CourseModel?> createCourse({
    required String title,
    required String subject,
    required String pdfUrl,
    required String pdfText,
    required int fileSize,
    required int pageCount,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ User not logged in');
        return null;
      }

      print('📝 Creating course: $title');
      print('👤 User ID: $userId');
      print('📄 PDF Text length: ${pdfText.length}');

      final data = await _client
          .from(SupabaseConfig.tableCourses)
          .insert({
        'user_id': userId,
        'title': title,
        'subject': subject,
        'pdf_url': pdfUrl,
        'pdf_text': pdfText,
        'file_size': fileSize,
        'page_count': pageCount,
        'preparation_score': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      print('✅ Course created: ${data['id']}');
      return CourseModel.fromMap(data);
    } catch (e) {
      print('❌ Error creating course: $e');
      return null;
    }
  }

  // ─── Mettre à jour un cours ─────────────────────────────
  Future<void> updateCourse({
    required String courseId,
    String? title,
    String? subject,
    int? preparationScore,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (subject != null) updates['subject'] = subject;
      if (preparationScore != null) updates['preparation_score'] = preparationScore;

      await _client
          .from(SupabaseConfig.tableCourses)
          .update(updates)
          .eq('id', courseId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // ─── Mettre à jour le score de préparation ──────────────
  Future<void> updatePreparationScore(String courseId, int score) async {
    try {
      await _client
          .from(SupabaseConfig.tableCourses)
          .update({
        'preparation_score': score,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', courseId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du score: $e');
    }
  }

  // ─── Supprimer un cours ─────────────────────────────────
  Future<void> deleteCourse(String courseId) async {
    try {
      // Récupérer l'URL du PDF pour le supprimer du storage
      final course = await getCourseById(courseId);

      await _client
          .from(SupabaseConfig.tableCourses)
          .delete()
          .eq('id', courseId);

      print('✅ Course deleted: $courseId');

      // TODO: Supprimer aussi le PDF du storage
      // if (course != null) {
      //   await _storageService.deletePDF(course.pdfUrl);
      // }
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}