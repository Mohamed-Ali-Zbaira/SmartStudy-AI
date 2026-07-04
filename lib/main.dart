import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_study/screens/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/upload_course_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/quiz_screen.dart';
import 'models/course_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90D9)),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      ),
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        // ✅ Détecter le callback OAuth
        if (settings.name?.startsWith('/auth/callback') ?? false) {
          // Rediriger vers Home si connecté
          return MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          );
        }
        return null;
      },
      routes: {
        '/login':      (_) => const LoginScreen(),
        '/register':   (_) => const RegisterScreen(),
        '/home':       (_) => const HomeScreen(),
        '/profile':    (_) => const ProfileScreen(),
        '/upload':     (_) => const UploadCourseScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/summary':    (context) {
          final course = ModalRoute.of(context)!.settings.arguments as CourseModel;
          return SummaryScreen(course: course);
        },
        '/quiz':       (context) {
          final course = ModalRoute.of(context)!.settings.arguments as CourseModel;
          return QuizScreen(course: course);
        },
        '/chat': (context) {
          final course = ModalRoute.of(context)!.settings.arguments as CourseModel;
          return ChatScreen(course: course);
        },
      },

    );
  }
}