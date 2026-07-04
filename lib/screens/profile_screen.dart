import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/course_service.dart';
import '../models/profile_model.dart';
import '../config/supabase_config.dart';

// ════════════════════════════════════════════════════════════
//  COULEURS
// ════════════════════════════════════════════════════════════
class AppColors {
  static const primary = Color(0xFF1E3A5F);
  static const secondary = Color(0xFF4A90D9);
  static const success = Color(0xFF27AE60);
  static const danger = Color(0xFFC0392B);
  static const warning = Color(0xFFF39C12);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE0EAF5);
  static const textPrimary = Color(0xFF1E3A5F);
  static const textSecondary = Color(0xFF6B8BA4);
  static const textHint = Color(0xFF94AFC6);
}

// ════════════════════════════════════════════════════════════
//  PROFILE SCREEN
// ════════════════════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _courseService = CourseService();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _fieldOfStudyController = TextEditingController();

  ProfileModel? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isEditMode = false;
  String? _email;
  File? _selectedImageFile;
  String? _avatarUrl;

  // ✅ Statistiques réelles
  int _coursesCount = 0;
  int _quizzesCount = 0;
  double _averageScore = 0;
  int _totalStudyTime = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStats();
    _getCurrentEmail();
  }

  void _getCurrentEmail() {
    final user = Supabase.instance.client.auth.currentUser;
    _email = user?.email;
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getMyProfile();
      setState(() {
        _profile = profile;
        _avatarUrl = profile?.avatarUrl;
        _initControllers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur de chargement du profil');
    }
  }

  // ✅ Charger les vraies statistiques
  Future<void> _loadStats() async {
    try {
      // Récupérer les cours
      final courses = await _courseService.getUserCourses();

      // Calculer les stats
      int coursesCount = courses.length;
      int quizzesCount = 0;
      double totalScore = 0;
      int scoredCourses = 0;

      for (final course in courses) {
        if (course.preparationScore > 0) {
          quizzesCount++;
          totalScore += course.preparationScore;
          scoredCourses++;
        }
      }

      final averageScore = scoredCourses > 0 ? totalScore / scoredCourses : 0.0;

      setState(() {
        _coursesCount = coursesCount;
        _quizzesCount = quizzesCount;
        _averageScore = averageScore;
      });
    } catch (e) {
      print('❌ Error loading stats: $e');
    }
  }

  void _initControllers() {
    _nameController.text = _profile?.fullName ?? '';
    _universityController.text = _profile?.university ?? '';
    _fieldOfStudyController.text = _profile?.fieldOfStudy ?? '';
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _initControllers();
        _selectedImageFile = null;
        _avatarUrl = _profile?.avatarUrl;
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() {
      _selectedImageFile = File(pickedFile.path);
      _isUploadingImage = true;
    });

    try {
      final userId = _profileService.currentUserId;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final publicUrl = await _profileService.uploadAvatar(
        userId,
        _selectedImageFile!,
      );

      setState(() {
        _avatarUrl = publicUrl;
        _isUploadingImage = false;
      });

      _showSuccess('Photo de profil mise à jour !');
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showError('Erreur lors de l\'upload: ${e.toString()}');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _profileService.updateProfile(
        fullName: _nameController.text.trim(),
        university: _universityController.text.trim().isEmpty
            ? null
            : _universityController.text.trim(),
        fieldOfStudy: _fieldOfStudyController.text.trim().isEmpty
            ? null
            : _fieldOfStudyController.text.trim(),
        avatarUrl: _avatarUrl,
      );

      _showSuccess('Profil mis à jour avec succès !');
      setState(() {
        _isEditMode = false;
        _selectedImageFile = null;
      });
      await _loadProfile();
    } catch (e) {
      _showError('Erreur lors de la mise à jour: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
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
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _fieldOfStudyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mon Profil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: _toggleEditMode,
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _AvatarSection(
              name: _profile?.fullName ?? 'Utilisateur',
              email: _email,
              avatarUrl: _avatarUrl,
              selectedImageFile: _selectedImageFile,
              isEditMode: _isEditMode,
              isUploading: _isUploadingImage,
              onTapUpload: _pickAndUploadImage,
            ),
            const SizedBox(height: 24),
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
                      'Informations personnelles',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 20),
                    _ProfileField(
                      controller: _nameController,
                      label: 'Nom complet',
                      icon: Icons.person_outline,
                      enabled: _isEditMode,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nom obligatoire';
                        if (v.trim().length < 3) return 'Minimum 3 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _ProfileField(
                      controller: TextEditingController(text: _email),
                      label: 'Adresse email',
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 20),
                    const Text(
                      'Informations académiques',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 20),
                    _ProfileField(
                      controller: _fieldOfStudyController,
                      label: 'Filière',
                      icon: Icons.school_outlined,
                      enabled: _isEditMode,
                      hint: 'ex: Master Informatique',
                    ),
                    const SizedBox(height: 16),
                    _ProfileField(
                      controller: _universityController,
                      label: 'Université',
                      icon: Icons.account_balance_outlined,
                      enabled: _isEditMode,
                      hint: 'ex: ISET Sfax',
                    ),
                    const SizedBox(height: 24),
                    if (_isEditMode)
                      _SaveButton(isLoading: _isSaving, onTap: _saveProfile),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ✅ Statistiques mises à jour
            _StatsSection(
              coursesCount: _coursesCount,
              quizzesCount: _quizzesCount,
              averageScore: _averageScore,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  AVATAR SECTION
// ════════════════════════════════════════════════════════════
class _AvatarSection extends StatelessWidget {
  final String name;
  final String? email;
  final String? avatarUrl;
  final File? selectedImageFile;
  final bool isEditMode;
  final bool isUploading;
  final VoidCallback onTapUpload;

  const _AvatarSection({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.selectedImageFile,
    required this.isEditMode,
    required this.isUploading,
    required this.onTapUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2A5482)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: isEditMode ? onTapUpload : null,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: _buildAvatarContent(),
                  ),
                ),
              ),
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
              if (isEditMode && !isUploading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onTapUpload,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(email ?? '', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (selectedImageFile != null) {
      return Image.file(selectedImageFile!, fit: BoxFit.cover);
    }
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.white.withOpacity(0.1),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildInitialAvatar(),
      );
    }
    return _buildInitialAvatar();
  }

  Widget _buildInitialAvatar() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  PROFILE FIELD
// ════════════════════════════════════════════════════════════
class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final String? hint;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: TextStyle(fontSize: 14, color: enabled ? AppColors.textPrimary : AppColors.textSecondary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
        prefixIcon: Icon(icon, size: 20, color: AppColors.secondary),
        filled: true,
        fillColor: enabled ? AppColors.background : const Color(0xFFF0F4F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.secondary, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SAVE BUTTON
// ════════════════════════════════════════════════════════════
class _SaveButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _SaveButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          disabledBackgroundColor: AppColors.textHint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text('Sauvegarder les modifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  STATS SECTION - Mise à jour avec vraies données
// ════════════════════════════════════════════════════════════
class _StatsSection extends StatelessWidget {
  final int coursesCount;
  final int quizzesCount;
  final double averageScore;

  const _StatsSection({
    required this.coursesCount,
    required this.quizzesCount,
    required this.averageScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Statistiques',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                value: '$coursesCount',
                label: 'Cours',
                icon: Icons.folder_outlined,
                color: const Color(0xFF4A90D9),
              ),
              _StatItem(
                value: '$quizzesCount',
                label: 'Quiz',
                icon: Icons.quiz_outlined,
                color: const Color(0xFF27AE60),
              ),
              _StatItem(
                value: '${averageScore.toStringAsFixed(1)}%',
                label: 'Score moyen',
                icon: Icons.trending_up,
                color: const Color(0xFFF39C12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}