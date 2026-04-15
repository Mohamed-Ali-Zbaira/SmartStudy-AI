import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/upload_course_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/quiz_screen.dart';  // ✅ Importer QuizScreen
import 'models/course_model.dart';  // ✅ Importer CourseModel

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  FlutterNativeSplash.remove();

  runApp(const SmartStudyApp());
}

final supabase = Supabase.instance.client;

class SmartStudyApp extends StatelessWidget {
  const SmartStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartStudy AI',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/login':    (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home':     (context) => const HomeScreen(),
        '/profile':  (context) => const ProfileScreen(),
        '/upload':   (context) => const UploadCourseScreen(),
        '/summary':  (context) {
          final course = ModalRoute.of(context)!.settings.arguments as CourseModel;
          return SummaryScreen(course: course);
        },
        // ✅ Ajouter la route /quiz
        '/quiz':     (context) {
          final course = ModalRoute.of(context)!.settings.arguments as CourseModel;
          return QuizScreen(course: course);
        },
      },
    );
  }
}