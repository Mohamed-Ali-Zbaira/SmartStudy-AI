import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ════════════════════════════════════════════════════════════
//  COULEURS
// ════════════════════════════════════════════════════════════
class AppColors {
  static const primary = Color(0xFF1E3A5F);
  static const secondary = Color(0xFF4A90D9);
  static const success = Color(0xFF27AE60);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1E3A5F);
  static const textSecondary = Color(0xFF6B8BA4);
}

// ════════════════════════════════════════════════════════════
//  MODÈLE DE PAGE ONBOARDING
// ════════════════════════════════════════════════════════════
class OnboardingPageData {
  final String emoji;
  final String pillLabel;
  final String titleDark;
  final String titleBlue;
  final String subtitle;
  final List<FeatureItem> features;

  const OnboardingPageData({
    required this.emoji,
    required this.pillLabel,
    required this.titleDark,
    required this.titleBlue,
    required this.subtitle,
    required this.features,
  });
}

class FeatureItem {
  final String icon;
  final String label;
  const FeatureItem({required this.icon, required this.label});
}

final List<OnboardingPageData> _pages = [
  const OnboardingPageData(
    emoji: '📄',
    pillLabel: 'Résumés Intelligents',
    titleDark: 'Résumés',
    titleBlue: 'Intelligents',
    subtitle: 'Uploadez n\'importe quel PDF de cours. L\'IA génère un résumé structuré avec les points clés et définitions essentielles en quelques secondes.',
    features: [
      FeatureItem(icon: '📌', label: 'Points clés automatiques'),
      FeatureItem(icon: '📖', label: 'Définitions et glossaire'),
      FeatureItem(icon: '⚡', label: 'Généré en quelques secondes'),
    ],
  ),
  const OnboardingPageData(
    emoji: '❓',
    pillLabel: 'Quiz Personnalisés',
    titleDark: 'Quiz',
    titleBlue: 'Personnalisés',
    subtitle: 'Testez vos connaissances avec des quiz générés automatiquement. Choisissez votre niveau et progressez à votre rythme.',
    features: [
      FeatureItem(icon: '🔟', label: '10 questions par quiz'),
      FeatureItem(icon: '✅', label: 'Correction instantanée'),
      FeatureItem(icon: '💡', label: 'Explications détaillées'),
    ],
  ),
  const OnboardingPageData(
    emoji: '💬',
    pillLabel: 'Chat IA Contextuel',
    titleDark: 'Chat IA',
    titleBlue: 'Contextuel',
    subtitle: 'Posez des questions directement sur vos cours. L\'IA vous répond en se basant uniquement sur le contenu de votre document.',
    features: [
      FeatureItem(icon: '🎯', label: 'Réponses précises'),
      FeatureItem(icon: '📚', label: 'Basé sur votre cours'),
      FeatureItem(icon: '💬', label: 'Historique de conversation'),
    ],
  ),
];

// ════════════════════════════════════════════════════════════
//  ONBOARDING SCREEN
// ════════════════════════════════════════════════════════════
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // Cercles décoratifs fond
            Positioned(
              top: -80, right: -80,
              child: _decoCircle(250),
            ),
            Positioned(
              bottom: -60, left: -60,
              child: _decoCircle(200),
            ),

            // Contenu
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Center(
                              child: Text('📚', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'SmartStudy AI',
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: Colors.white, letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _finishOnboarding,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          backgroundColor: Colors.white.withOpacity(0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Passer',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => _OnboardingPage(page: _pages[i]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _decoCircle(double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.03),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  PAGE WIDGET
// ════════════════════════════════════════════════════════════
class _OnboardingPage extends StatefulWidget {
  final OnboardingPageData page;
  const _OnboardingPage({required this.page});

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          children: [
            // TOP : section bleue avec icône
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.10),
                      ),
                      child: Center(
                        child: Container(
                          width: 86, height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: Center(
                            child: Text(
                              page.emoji,
                              style: const TextStyle(fontSize: 38),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        page.pillLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM : carte blanche
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre deux couleurs
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${page.titleDark}\n',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: page.titleBlue,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      page.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Features
                    ...page.features.map((f) => _FeatureRow(item: f)),
                    const Spacer(),
                    // Dots + bouton
                    _BottomNav(page: widget.page),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FEATURE ROW
// ════════════════════════════════════════════════════════════
class _FeatureRow extends StatelessWidget {
  final FeatureItem item;
  const _FeatureRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(item.icon, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 22, height: 22,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 13),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  BOTTOM NAV (dots + bouton)
// ════════════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final OnboardingPageData page;
  const _BottomNav({required this.page});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_OnboardingScreenState>()!;
    final cur = state._currentPage;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: List.generate(_pages.length, (i) {
            final isActive = i == cur;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 6),
              width: isActive ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.secondary
                    : AppColors.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        GestureDetector(
          onTap: state._nextPage,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              cur == _pages.length - 1
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}