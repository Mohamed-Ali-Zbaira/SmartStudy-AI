import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/course_service.dart';
import '../models/profile_model.dart';
import '../models/course_model.dart';
import 'profile_screen.dart';

// ════════════════════════════════════════════════════════════
//  COULEURS (charte SmartStudy AI — inchangée)
// ════════════════════════════════════════════════════════════
class AppColors {
  static const primary       = Color(0xFF1E3A5F);
  static const secondary     = Color(0xFF4A90D9);
  static const success       = Color(0xFF27AE60);
  static const warning       = Color(0xFFE67E22);
  static const danger        = Color(0xFFC0392B);
  static const background    = Color(0xFFF4F7FB);
  static const surface       = Colors.white;
  static const border        = Color(0xFFE0EAF5);
  static const textPrimary   = Color(0xFF1E3A5F);
  static const textSecondary = Color(0xFF6B8BA4);
  static const textHint      = Color(0xFF94AFC6);

  // Teintes supplémentaires pour le design 2026
  static const primaryLight  = Color(0xFF2A5482);
  static const secondaryBg   = Color(0xFFEBF4FF);
  static const cardShadow    = Color(0x0A1E3A5F);
}

// ════════════════════════════════════════════════════════════
//  HOME SCREEN
// ════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final _authService    = AuthService();
  final _profileService = ProfileService();
  final _courseService  = CourseService();
  final _searchController = TextEditingController();

  String         _searchQuery   = '';
  int            _selectedIndex = 0;
  ProfileModel?  _profile;
  List<CourseModel> _courses    = [];
  bool _isLoading        = true;
  bool _isCoursesLoading = true;

  // Animation controller pour les cartes
  late AnimationController _listAnimCtrl;

  @override
  void initState() {
    super.initState();
    _listAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadProfile();
    _loadCourses();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getMyProfile();
      setState(() => _profile = profile);
    } catch (_) {}
  }

  Future<void> _loadCourses() async {
    setState(() => _isCoursesLoading = true);
    try {
      final courses = await _courseService.getUserCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
        _isCoursesLoading = false;
      });
      _listAnimCtrl.forward(from: 0);
    } catch (_) {
      setState(() {
        _isLoading = false;
        _isCoursesLoading = false;
      });
    }
  }

  List<CourseModel> get _filteredCourses {
    if (_searchQuery.isEmpty) return _courses;
    return _courses.where((c) =>
    c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c.subject.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.danger, size: 24),
              ),
              const SizedBox(height: 16),
              const Text(
                'Déconnexion',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Voulez-vous vraiment vous déconnecter ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Déconnecter',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await _authService.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onUpload() async {
    final result = await Navigator.pushNamed(context, '/upload');
    if (result == true) await _loadCourses();
  }

  Future<void> _onDelete(CourseModel course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger, size: 24),
              ),
              const SizedBox(height: 16),
              const Text(
                'Supprimer le cours',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Voulez-vous supprimer "${course.title}" et toutes ses données ?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await _courseService.deleteCourse(course.id);
        _showSuccess('Cours supprimé');
        await _loadCourses();
      } catch (_) {
        _showError('Erreur lors de la suppression');
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _onNavigationTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        _showComingSoon('Statistiques');
        setState(() => _selectedIndex = 0);
        break;
      case 2:
        Navigator.pushNamed(context, '/profile')
            .then((_) => setState(() => _selectedIndex = 0));
        break;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — Bientôt disponible !'),
      backgroundColor: AppColors.warning,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listAnimCtrl.dispose();
    super.dispose();
  }

  // ── Stats rapides ─────────────────────────────────
  int get _avgScore {
    if (_courses.isEmpty) return 0;
    final total = _courses.fold(0, (s, c) => s + (c.preparationScore ?? 0));
    return (total / _courses.length).round();
  }

  int get _readyCourses =>
      _courses.where((c) => (c.preparationScore ?? 0) >= 80).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────
            _ModernHeader(
              profile: _profile,
              courseCount: _courses.length,
              avgScore: _avgScore,
              readyCourses: _readyCourses,
              searchController: _searchController,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              onProfileTap: () => Navigator.pushNamed(context, '/profile'),
              onLogout: _logout,
            ),

            // ── BODY ────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.secondary,
                  strokeWidth: 2.5,
                ),
              )
                  : _filteredCourses.isEmpty
                  ? _EmptyState(onAdd: _onUpload)
                  : RefreshIndicator(
                onRefresh: _loadCourses,
                color: AppColors.secondary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _filteredCourses.length,
                  itemBuilder: (_, i) {
                    final delay = i * 0.08;
                    return AnimatedBuilder(
                      animation: _listAnimCtrl,
                      builder: (_, child) {
                        final progress = Curves.easeOutCubic.transform(
                          ((_listAnimCtrl.value - delay)
                              .clamp(0.0, 1.0 - delay) /
                              (1.0 - delay))
                              .clamp(0.0, 1.0),
                        );
                        return Opacity(
                          opacity: progress,
                          child: Transform.translate(
                            offset: Offset(0, 24 * (1 - progress)),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ModernCourseCard(
                          course: _filteredCourses[i],
                          onDelete: () =>
                              _onDelete(_filteredCourses[i]),
                          onSummary: () => Navigator.pushNamed(
                            context,
                            '/summary',
                            arguments: _filteredCourses[i],
                          ),
                          onQuiz: () => Navigator.pushNamed(
                            context,
                            '/quiz',
                            arguments: _filteredCourses[i],
                          ),
                          onChat: () => Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: _filteredCourses[i],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // FAB
      floatingActionButton: _AnimatedFAB(onPressed: _onUpload),

      // Bottom Nav Moderne et arrondi
      bottomNavigationBar: _ModernRoundedBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MODERN HEADER
// ════════════════════════════════════════════════════════════
class _ModernHeader extends StatelessWidget {
  final ProfileModel? profile;
  final int courseCount;
  final int avgScore;
  final int readyCourses;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onProfileTap;
  final VoidCallback onLogout;

  const _ModernHeader({
    required this.profile,
    required this.courseCount,
    required this.avgScore,
    required this.readyCourses,
    required this.searchController,
    required this.onSearchChanged,
    required this.onProfileTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final firstName =
        profile?.fullName.split(' ').first ?? 'Utilisateur';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // ── Ligne 1 : avatar + greeting + menu ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.5),
                      child: profile?.avatarUrl != null &&
                          profile!.avatarUrl!.isNotEmpty
                          ? Image.network(
                        profile!.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildInitial(firstName),
                      )
                          : _buildInitial(firstName),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        firstName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.more_horiz,
                        color: Colors.white, size: 18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  offset: const Offset(0, 44),
                  onSelected: (v) {
                    if (v == 'profile') onProfileTap();
                    if (v == 'logout') onLogout();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 17, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        const Text('Mon profil',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [
                        const Icon(Icons.logout_rounded,
                            size: 17, color: AppColors.danger),
                        const SizedBox(width: 10),
                        const Text('Déconnexion',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.danger)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Ligne 2 : Stats pills ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StatPill(
                  icon: Icons.auto_stories_rounded,
                  value: '$courseCount',
                  label: 'cours',
                ),
                const SizedBox(width: 10),
                _StatPill(
                  icon: Icons.trending_up_rounded,
                  value: '$avgScore%',
                  label: 'moy. score',
                ),
                const SizedBox(width: 10),
                _StatPill(
                  icon: Icons.check_circle_outline_rounded,
                  value: '$readyCourses',
                  label: 'prêts',
                  highlight: readyCourses > 0,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Ligne 3 : Barre de recherche ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher un cours...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 19,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withOpacity(0.5),
                        size: 17),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour 👋';
    if (h < 18) return 'Bon après-midi 👋';
    return 'Bonsoir 👋';
  }
}

// ════════════════════════════════════════════════════════════
//  STAT PILL
// ════════════════════════════════════════════════════════════
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.success.withOpacity(0.18)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight
                ? AppColors.success.withOpacity(0.4)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 15,
                color: highlight
                    ? const Color(0xFF6EDFA8)
                    : Colors.white.withOpacity(0.6)),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: highlight
                        ? const Color(0xFF6EDFA8)
                        : Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MODERN COURSE CARD
// ════════════════════════════════════════════════════════════
class _ModernCourseCard extends StatefulWidget {
  final CourseModel course;
  final VoidCallback onDelete;
  final VoidCallback onSummary;
  final VoidCallback onQuiz;
  final VoidCallback onChat;

  const _ModernCourseCard({
    required this.course,
    required this.onDelete,
    required this.onSummary,
    required this.onQuiz,
    required this.onChat,
  });

  @override
  State<_ModernCourseCard> createState() => _ModernCourseCardState();
}

class _ModernCourseCardState extends State<_ModernCourseCard> {
  bool _pressed = false;

  Color get _scoreColor {
    final s = widget.course.preparationScore ?? 0;
    if (s >= 80) return AppColors.success;
    if (s >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  Color get _scoreBg {
    final s = widget.course.preparationScore ?? 0;
    if (s >= 80) return const Color(0xFFE8F7EE);
    if (s >= 50) return const Color(0xFFFEF3E7);
    return const Color(0xFFFDEBEB);
  }

  String _getEmoji(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('base') || s.contains('donnée')) return '📊';
    if (s.contains('algo') || s.contains('program')) return '🧮';
    if (s.contains('réseau')) return '🌐';
    if (s.contains('système')) return '🖥️';
    if (s.contains('math')) return '📐';
    if (s.contains('physique')) return '⚡';
    return '📄';
  }

  // Couleur accent selon matière
  Color _getAccentColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('base') || s.contains('donnée')) return const Color(0xFF3B82F6);
    if (s.contains('algo') || s.contains('program')) return const Color(0xFFF59E0B);
    if (s.contains('réseau')) return const Color(0xFF10B981);
    if (s.contains('système')) return const Color(0xFF8B5CF6);
    if (s.contains('math')) return const Color(0xFFEC4899);
    if (s.contains('physique')) return const Color(0xFFF97316);
    return AppColors.secondary;
  }

  String _getUploadedAgo() {
    final diff = DateTime.now().difference(widget.course.createdAt);
    if (diff.inDays > 7) return 'Il y a ${diff.inDays ~/ 7} sem.';
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    return 'À l\'instant';
  }

  @override
  Widget build(BuildContext context) {
    final score  = widget.course.preparationScore ?? 0;
    final accent = _getAccentColor(widget.course.subject);
    final emoji  = _getEmoji(widget.course.subject);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Bande couleur accent (top) ──
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    // ── Ligne principale ──
                    Row(
                      children: [
                        // Icône emoji dans cercle coloré
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accent.withOpacity(0.15),
                            ),
                          ),
                          child: Center(
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Titre + meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.course.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.course.subject,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.course.pageCount} p. · ${_getUploadedAgo()}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Score badge + delete
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _scoreBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$score%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _scoreColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: widget.onDelete,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Barre progression ──
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2F9),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: score / 100,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _scoreColor.withOpacity(0.7),
                                  _scoreColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Boutons actions ──
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          _ModernActionBtn(
                            emoji: '📄',
                            label: 'Résumé',
                            color: const Color(0xFF185FA5),
                            bg: const Color(0xFFEBF4FF),
                            onTap: widget.onSummary,
                          ),
                          const SizedBox(width: 8),
                          _ModernActionBtn(
                            emoji: '❓',
                            label: 'Quiz',
                            color: const Color(0xFF1A8044),
                            bg: const Color(0xFFE8F7EE),
                            onTap: widget.onQuiz,
                          ),
                          const SizedBox(width: 8),
                          _ModernActionBtn(
                            emoji: '💬',
                            label: 'Chat IA',
                            color: const Color(0xFFB8620A),
                            bg: const Color(0xFFFEF3E7),
                            onTap: widget.onChat,
                          ),
                        ],
                      ),
                    ),
                  ],
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
//  MODERN ACTION BUTTON
// ════════════════════════════════════════════════════════════
class _ModernActionBtn extends StatefulWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ModernActionBtn({
    required this.emoji,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  State<_ModernActionBtn> createState() => _ModernActionBtnState();
}

class _ModernActionBtnState extends State<_ModernActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: _pressed
                ? widget.color.withOpacity(0.12)
                : widget.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
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
//  ANIMATED FAB
// ════════════════════════════════════════════════════════════
class _AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedFAB({required this.onPressed});

  @override
  State<_AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<_AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5BA8E8), AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded,
              color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MODERN ROUNDED BOTTOM NAV (Design arrondi et moderne)
// ════════════════════════════════════════════════════════════
class _ModernRoundedBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _ModernRoundedBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _RoundedNavItem(
                icon: Icons.auto_stories_outlined,
                activeIcon: Icons.auto_stories_rounded,
                label: 'Bibliothèque',
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _RoundedNavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Statistiques',
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _RoundedNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundedNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoundedNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  size: 22,
                  color: isSelected
                      ? AppColors.secondary
                      : AppColors.textHint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: isSelected
                      ? AppColors.secondary
                      : AppColors.textHint,
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
//  EMPTY STATE (Sans bouton upload)
// ════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.15),
                ),
              ),
              child: const Center(
                child: Text('📚', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun cours pour l\'instant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Importez votre premier PDF pour commencer\nà réviser intelligemment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            // Le bouton "Ajouter un cours" a été supprimé
          ],
        ),
      ),
    );
  }
}