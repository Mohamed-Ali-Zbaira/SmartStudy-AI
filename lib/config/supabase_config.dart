class SupabaseConfig {
  static const String url = 'https://nhwgvqzicqazxxahhahz.supabase.co';
  static const String anonKey = 'sb_publishable_8xmCAWNYAKT4d6qUFpwsZA_dy-VBDru';

  // Noms des tables — évite les typos dans tout le projet
  static const String tableProfiles      = 'profiles';
  static const String tableCourses       = 'courses';
  static const String tableSummaries     = 'summaries';
  static const String tableQuizzes       = 'quizzes';
  static const String tableQuestions     = 'questions';
  static const String tableChatMessages  = 'chat_messages';
  static const String tableStudySessions = 'study_sessions';

  // Noms des buckets Storage
  static const String bucketPdfs    = 'course-pdfs';
  static const String bucketAvatars = 'avatars';
}
class GeminiConfig {
  static const String apiKey = 'AIzaSyAr-GNecUqd9hc4lTtSOG7PmFy_7P1ubg8';
  
  static const String model = 'gemini-1.5-flash';
  static const String summaryModel = 'gemini-1.5-pro';
}