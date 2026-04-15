import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ════════════════════════════════════════════════════════════
//  SPLASH SCREEN — Animation au lancement de l'app
//
//  Séquence d'animation :
//  1. Fond gradient apparaît
//  2. Logo scale + fade in (0.0s → 0.8s)
//  3. Cercle lumineux pulse autour du logo (0.6s → 1.2s)
//  4. Nom "SmartStudy" slide up + fade in (0.8s → 1.4s)
//  5. "AI" + tagline fade in (1.2s → 1.8s)
//  6. Points de chargement apparaissent (1.8s → 2.2s)
//  7. Redirection vers Home ou Login (3.0s)
// ════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  late AnimationController _taglineController;
  late AnimationController _dotsController;

  // ── Animations Logo ───────────────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // ── Animations Pulse ──────────────────────────────────
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  // ── Animations Texte ──────────────────────────────────
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;

  // ── Animations Tagline ────────────────────────────────
  late Animation<double> _taglineOpacity;

  // ── Animations Dots ───────────────────────────────────
  late Animation<double> _dotsOpacity;

  // ── Supabase client ───────────────────────────────────
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Logo : scale de 0.3 → 1.0 + fade
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Pulse : cercle qui s'étend et disparaît (repeat)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Texte principal : slide from bottom + fade
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Tagline : fade in
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );

    // Dots : fade in
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeIn),
    );
  }

  Future<void> _startSequence() async {
    // 1. Logo apparaît
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();

    // 2. Pulse démarre
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _pulseController.repeat();

    // 3. Texte slide up
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textController.forward();

    // 4. Tagline fade in
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _taglineController.forward();

    // 5. Dots apparaissent
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _dotsController.forward();

    // 6. Navigation après délai total ~3s
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    // ✅ CORRECTION : Utiliser Supabase au lieu de Firebase
    final session = _supabase.auth.currentSession;
    final isLoggedIn = session != null;

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        isLoggedIn ? '/home' : '/login',
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fond gradient bleu foncé
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1F35),
              Color(0xFF1E3A5F),
              Color(0xFF2A5482),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Cercles décoratifs background ─────────
              _BackgroundDecorations(),

              // ── Contenu principal centré ───────────────
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo avec pulse ──────────────────
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Cercle pulse derrière le logo
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) => Transform.scale(
                              scale: _pulseScale.value,
                              child: Opacity(
                                opacity: _pulseOpacity.value,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF4A90D9),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Second pulse (décalé)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) {
                              final delayed =
                                  (_pulseController.value + 0.4) % 1.0;
                              final scale = 1.0 + delayed * 0.6;
                              final opacity =
                              (0.3 * (1.0 - delayed)).clamp(0.0, 0.3);
                              return Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF4A90D9),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Logo principal
                          AnimatedBuilder(
                            animation: _logoController,
                            builder: (_, __) => Transform.scale(
                              scale: _logoScale.value,
                              child: Opacity(
                                opacity: _logoOpacity.value,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4A90D9)
                                            .withOpacity(0.4),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/smartstudy_logo.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _FallbackLogo(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Nom de l'app ─────────────────────
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Column(
                            children: [
                              RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Smart',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Study',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF4A90D9),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' AI',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w300,
                                        color: Color(0xFF7DB8E8),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Tagline ───────────────────────────
                    AnimatedBuilder(
                      animation: _taglineController,
                      builder: (_, __) => Opacity(
                        opacity: _taglineOpacity.value,
                        child: Column(
                          children: [
                            Text(
                              'Assistant Intelligent d\'Apprentissage',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Chips features
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                _FeatureChip(text: 'Résumés IA'),
                                SizedBox(width: 8),
                                _FeatureChip(text: 'Quiz'),
                                SizedBox(width: 8),
                                _FeatureChip(text: 'Chat'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Dots de chargement en bas ──────────────
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _dotsController,
                  builder: (_, __) => Opacity(
                    opacity: _dotsOpacity.value,
                    child: Column(
                      children: [
                        _LoadingDots(),
                        const SizedBox(height: 12),
                        Text(
                          'Powered by Google Gemini',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.35),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  BACKGROUND DECORATIONS — cercles décoratifs flous
// ════════════════════════════════════════════════════════════
class _BackgroundDecorations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        // Cercle haut-gauche
        Positioned(
          top: -80,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A90D9).withOpacity(0.08),
            ),
          ),
        ),
        // Cercle bas-droite
        Positioned(
          bottom: -60,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A90D9).withOpacity(0.06),
            ),
          ),
        ),
        // Point lumineux haut-droite
        Positioned(
          top: size.height * 0.15,
          right: 30,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A90D9).withOpacity(0.4),
            ),
          ),
        ),
        // Point lumineux bas-gauche
        Positioned(
          bottom: size.height * 0.2,
          left: 40,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7DB8E8).withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  LOADING DOTS — 3 points animés en séquence
// ════════════════════════════════════════════════════════════
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _animations = _controllers.asMap().entries.map((e) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: e.value, curve: Curves.easeInOut),
      );
    }).toList();

    _startDots();
  }

  void _startDots() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      if (mounted) _controllers[i].repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                const Color(0xFF4A90D9).withOpacity(0.3),
                const Color(0xFF4A90D9),
                _animations[i].value,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FEATURE CHIP — petite pill en bas du nom
// ════════════════════════════════════════════════════════════
class _FeatureChip extends StatelessWidget {
  final String text;

  const _FeatureChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90D9).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4A90D9).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FALLBACK LOGO — si l'image n'est pas trouvée
// ════════════════════════════════════════════════════════════
class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF4A90D9), Color(0xFF1E3A5F)],
        ),
      ),
      child: const Center(
        child: Text('📚', style: TextStyle(fontSize: 52)),
      ),
    );
  }
}