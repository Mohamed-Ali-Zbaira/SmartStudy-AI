class SupabaseConfig {
  static const String url = 'https://your-project.supabase.co';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';

  static const String tableProfiles      = 'profiles';
  static const String tableCourses       = 'courses';
  static const String tableSummaries     = 'summaries';
  static const String tableQuizzes       = 'quizzes';
  static const String tableQuestions     = 'questions';
  static const String tableChatMessages  = 'chat_messages';
  static const String tableStudySessions = 'study_sessions';

  static const String bucketPdfs    = 'course-pdfs';
  static const String bucketAvatars = 'avatars';
}

class GeminiConfig {
  static const String apiKey = 'YOUR_GEMINI_API_KEY';
  static const String model = 'gemini-1.5-flash';
  static const String summaryModel = 'gemini-1.5-pro';
}