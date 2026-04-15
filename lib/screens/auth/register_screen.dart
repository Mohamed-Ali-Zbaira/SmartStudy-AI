import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

// ════════════════════════════════════════════════════════════
//  COULEURS
// ════════════════════════════════════════════════════════════
class AppColors {
  static const primary = Color(0xFF1E3A5F);
  static const secondary = Color(0xFF4A90D9);
  static const success = Color(0xFF27AE60);
  static const danger = Color(0xFFC0392B);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE0EAF5);
  static const textPrimary = Color(0xFF1E3A5F);
  static const textSecondary = Color(0xFF6B8BA4);
  static const textHint = Color(0xFF94AFC6);
}

// ════════════════════════════════════════════════════════════
//  REGISTER SCREEN
// ════════════════════════════════════════════════════════════
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _filiereController = TextEditingController();
  final _universityController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _acceptTerms = false;

  // Indicateur force mot de passe
  int _passwordStrength = 0; // 0-3

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
    _emailController.addListener(_checkPasswordStrength);

  }

  void _checkPasswordStrength() {
    final p = _passwordController.text;
    int strength = 0;

    if (p.length >= 8) strength++;
    if (p.contains(RegExp(r'[A-Z]'))) strength++;
    if (p.contains(RegExp(r'[0-9]'))) strength++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength++;

    // Bonus: vérifie que le mdp ne contient pas l'email
    final email = _emailController.text.trim().toLowerCase();
    if (email.isNotEmpty && p.toLowerCase().contains(email.split('@')[0])) {
      strength = 0; // Force à 0 si contient l'email
    }

    setState(() => _passwordStrength = strength > 3 ? 3 : strength);
  }
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _filiereController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  // ── Inscription email/password ────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showError('Veuillez accepter les conditions d\'utilisation.');
      return;
    }

    // Validation supplémentaire : mot de passe ≠ email
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (password.toLowerCase().contains(email.split('@')[0])) {
      _showError('Le mot de passe ne doit pas contenir votre adresse email.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        filiere: _filiereController.text.trim().isEmpty
            ? null
            : _filiereController.text.trim(),
        university: _universityController.text.trim().isEmpty
            ? null
            : _universityController.text.trim(),
      );

      _showSuccess('Compte créé ! Vérifiez votre email pour activer votre compte.');

      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      // Affiche le message traduit
      _showError(e.message);
    } catch (e) {
      _showError('Erreur inattendue: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // ── Inscription Google ────────────────────────────────
  Future<void> _registerWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final response = await _authService.signInWithGoogle();
      if (response == null) return; // Annulé par l'utilisateur
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      _showError(_authErrorMessage(e.message));
    } catch (e) {
      _showError('Connexion Google échouée.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  String _authErrorMessage(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('user already registered')) {
      return 'Cet email est déjà utilisé par un autre compte.';
    } else if (msg.contains('invalid email')) {
      return 'Adresse email invalide.';
    } else if (msg.contains('password')) {
      return 'Mot de passe trop faible (minimum 6 caractères).';
    } else if (msg.contains('network')) {
      return 'Pas de connexion Internet.';
    }
    return 'Erreur lors de l\'inscription. Réessayez.';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── HEADER ────────────────────────────────
              _RegisterHeader(onBack: () => Navigator.pop(context)),

              // ── FORM ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Card formulaire
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Créer un compte',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Rejoignez SmartStudy AI gratuitement.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),

                            const SizedBox(height: 20),

                            // ── Section : Informations personnelles ──
                            _SectionLabel(
                                label: '👤 Informations personnelles'),
                            const SizedBox(height: 10),

                            // Nom complet
                            _FormField(
                              controller: _nameController,
                              label: 'Nom complet',
                              hint: 'Mohamed Ben Ali',
                              icon: Icons.person_outline,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Nom obligatoire';
                                if (v.trim().length < 3)
                                  return 'Minimum 3 caractères';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Email
                            _FormField(
                              controller: _emailController,
                              label: 'Adresse email',
                              hint: 'exemple@email.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Email obligatoire';
                                if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(v))
                                  return 'Email invalide';
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // ── Section : Sécurité ──
                            _SectionLabel(label: '🔐 Sécurité'),
                            const SizedBox(height: 10),

                            // Mot de passe
                            _FormField(
                              controller: _passwordController,
                              label: 'Mot de passe',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textHint,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Mot de passe obligatoire';
                                if (v.length < 6)
                                  return 'Minimum 6 caractères';
                                return null;
                              },
                            ),

                            // Indicateur force
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _PasswordStrengthBar(
                                  strength: _passwordStrength),
                            ],

                            const SizedBox(height: 12),

                            // Confirmer mot de passe
                            _FormField(
                              controller: _confirmController,
                              label: 'Confirmer le mot de passe',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirm,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textHint,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                        () => _obscureConfirm = !_obscureConfirm),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Confirmation obligatoire';
                                if (v != _passwordController.text)
                                  return 'Les mots de passe ne correspondent pas';
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // ── Section : Informations académiques ──
                            _SectionLabel(label: '🎓 Informations académiques'),
                            const SizedBox(height: 10),

                            // Filière
                            _FormField(
                              controller: _filiereController,
                              label: 'Filière (optionnel)',
                              hint: 'ex : Master Informatique',
                              icon: Icons.school_outlined,
                            ),
                            const SizedBox(height: 12),

                            // Université
                            _FormField(
                              controller: _universityController,
                              label: 'Université (optionnel)',
                              hint: 'ex : ISET Sfax',
                              icon: Icons.account_balance_outlined,
                            ),

                            const SizedBox(height: 20),

                            // ── Conditions d'utilisation ──
                            _TermsCheckbox(
                              value: _acceptTerms,
                              onChanged: (v) =>
                                  setState(() => _acceptTerms = v ?? false),
                            ),

                            const SizedBox(height: 16),

                            // Bouton S'inscrire
                            _PrimaryButton(
                              label: 'Créer mon compte',
                              isLoading: _isLoading,
                              onTap: _register,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Séparateur ─────────────────────────
                    _OrDivider(),

                    const SizedBox(height: 16),

                    // ── Google ─────────────────────────────
                    _GoogleButton(
                      isLoading: _isGoogleLoading,
                      onTap: _registerWithGoogle,
                    ),

                    const SizedBox(height: 28),

                    // ── Lien connexion ─────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Déjà un compte ? ',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
//  REGISTER HEADER
// ════════════════════════════════════════════════════════════
class _RegisterHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _RegisterHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2A5482)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton retour
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 20),

          // Logo + texte
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: const Center(
                  child: Text('📚', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SmartStudy AI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Créer votre compte gratuit',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Feature pills
          Row(
            children: const [
              _FeaturePill(emoji: '🤖', label: 'IA Gemini'),
              SizedBox(width: 8),
              _FeaturePill(emoji: '❓', label: 'Quiz auto'),
              SizedBox(width: 8),
              _FeaturePill(emoji: '📄', label: 'Résumés'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String emoji;
  final String label;

  const _FeaturePill({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SECTION LABEL
// ════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  PASSWORD STRENGTH BAR
// ════════════════════════════════════════════════════════════
class _PasswordStrengthBar extends StatelessWidget {
  final int strength; // 0-3

  const _PasswordStrengthBar({required this.strength});

  Color get _color {
    switch (strength) {
      case 1:
        return const Color(0xFFE05050);
      case 2:
        return const Color(0xFFE67E22);
      case 3:
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFFE2EAF5);
    }
  }

  String get _label {
    switch (strength) {
      case 1:
        return 'Faible';
      case 2:
        return 'Moyen';
      case 3:
        return 'Fort';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final active = i < strength;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: active ? _color : const Color(0xFFE2EAF5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (_label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Force : $_label',
            style: TextStyle(fontSize: 11, color: _color),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TERMS CHECKBOX
// ════════════════════════════════════════════════════════════
class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.secondary,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: AppColors.border, width: 1.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              children: [
                TextSpan(text: 'J\'accepte les '),
                TextSpan(
                  text: 'Conditions d\'utilisation',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' et la '),
                TextSpan(
                  text: 'Politique de confidentialité',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SHARED WIDGETS (dupliqués pour indépendance du fichier)
// ════════════════════════════════════════════════════════════
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
        const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        hintStyle:
        const TextStyle(fontSize: 13, color: AppColors.textHint),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          disabledBackgroundColor: AppColors.textHint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
        )
            : Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OU',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border, width: 1.5),
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.secondary),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'G',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'S\'inscrire avec Google',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}