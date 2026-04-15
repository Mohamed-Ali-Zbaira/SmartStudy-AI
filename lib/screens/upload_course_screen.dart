import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/storage_service.dart';
import '../services/course_service.dart';
import '../services/pdf_extractor_service.dart';

class AppColors {
  static const primary = Color(0xFF1E3A5F);
  static const secondary = Color(0xFF4A90D9);
  static const success = Color(0xFF27AE60);
  static const danger = Color(0xFFC0392B);
  static const warning = Color(0xFFE67E22);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE0EAF5);
  static const textPrimary = Color(0xFF1E3A5F);
  static const textSecondary = Color(0xFF6B8BA4);
  static const textHint = Color(0xFF94AFC6);
}

class UploadCourseScreen extends StatefulWidget {
  const UploadCourseScreen({super.key});

  @override
  State<UploadCourseScreen> createState() => _UploadCourseScreenState();
}

class _UploadCourseScreenState extends State<UploadCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();

  final _storageService = StorageService();
  final _courseService = CourseService();
  final _pdfExtractor = PdfExtractorService();  // ✅ Nouveau service

  Uint8List? _fileBytes;
  String? _fileName;
  int? _fileSize;
  bool _isUploading = false;
  bool _isExtracting = false;
  String? _extractedText;
  int? _pageCount;
  bool _extractionSuccess = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickPDF() async {
    try {
      print('📂 Opening file picker...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        print('📂 Selected file: ${pickedFile.name}');
        print('📂 File size: ${pickedFile.size} bytes');

        if (pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty) {
          setState(() {
            _fileBytes = pickedFile.bytes;
            _fileName = pickedFile.name;
            _fileSize = pickedFile.size;

            if (_titleController.text.isEmpty) {
              _titleController.text = pickedFile.name.replaceAll('.pdf', '');
            }
          });

          // ✅ Extraire avec Syncfusion
          await _extractTextWithSyncfusion(pickedFile.bytes!);
        } else {
          _showError('Le fichier est vide');
        }
      }
    } catch (e) {
      print('❌ Error picking file: $e');
      _showError('Erreur: $e');
    }
  }

  Future<void> _extractTextWithSyncfusion(Uint8List bytes) async {
    setState(() => _isExtracting = true);

    try {
      final result = await _pdfExtractor.extractTextFromBytes(bytes);

      setState(() {
        _isExtracting = false;
        _extractionSuccess = result['success'] == true;
        _extractedText = result['text'];
        _pageCount = result['pageCount'];
      });

      if (_extractionSuccess && _extractedText!.isNotEmpty) {
        print('✅ Extraction réussie: ${_extractedText!.length} caractères');
        _showSuccess('✅ Texte extrait avec succès !');
      } else {
        print('⚠️ Aucun texte trouvé dans le PDF');
        _showError('Ce PDF ne contient pas de texte sélectionnable (image scannée)');

        // On garde quand même le PDF, mais sans texte
        setState(() {
          _extractedText = '';
        });
      }
    } catch (e) {
      setState(() => _isExtracting = false);
      _extractionSuccess = false;
      _extractedText = '';
      print('❌ Extraction error: $e');
      _showError('Erreur lors de l\'extraction du texte');
    }
  }

  Future<void> _uploadCourse() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Veuillez remplir le titre');
      return;
    }

    if (_fileBytes == null) {
      _showError('Veuillez sélectionner un fichier PDF');
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showError('Utilisateur non connecté');
      return;
    }

    setState(() => _isUploading = true);

    try {
      print('📤 Starting upload...');
      print('📤 Extracted text available: ${_extractedText != null && _extractedText!.isNotEmpty}');

      // 1. Upload du PDF vers Storage
      final pdfUrl = await _storageService.uploadPDFBytes(
        userId: userId,
        fileBytes: _fileBytes!,
        fileName: _fileName ?? 'document.pdf',
      );

      print('📤 PDF URL: $pdfUrl');

      // 2. Créer l'entrée dans la table courses
      final course = await _courseService.createCourse(
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim().isEmpty
            ? 'Non spécifié'
            : _subjectController.text.trim(),
        pdfUrl: pdfUrl,
        pdfText: _extractedText ?? '',  // ✅ Peut être vide si PDF scanné
        fileSize: _fileSize ?? 0,
        pageCount: _pageCount ?? 1,
      );

      if (course != null) {
        if (_extractedText == null || _extractedText!.isEmpty) {
          _showSuccess('✅ Cours uploadé (sans texte - PDF scanné)');
        } else {
          _showSuccess('✅ Cours uploadé avec succès !');
        }
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showError('Erreur lors de la création du cours');
      }
    } catch (e) {
      print('❌ Upload error: $e');
      _showError('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    print('❌ $msg');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    print('✅ $msg');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Importer un cours',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zone de sélection
              GestureDetector(
                onTap: (_isUploading || _isExtracting) ? null : _pickPDF,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _fileBytes != null
                          ? (_extractionSuccess ? AppColors.success : AppColors.warning)
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_isExtracting)
                        const CircularProgressIndicator()
                      else
                        Icon(
                          _fileBytes != null
                              ? (_extractionSuccess ? Icons.check_circle : Icons.warning)
                              : Icons.upload_file,
                          size: 48,
                          color: _fileBytes != null
                              ? (_extractionSuccess ? AppColors.success : AppColors.warning)
                              : AppColors.secondary,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _isExtracting
                            ? 'Extraction du texte en cours...'
                            : (_fileName ?? 'Cliquez pour sélectionner un PDF'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _fileBytes != null
                              ? (_extractionSuccess ? AppColors.success : AppColors.textPrimary)
                              : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_fileSize != null && !_isExtracting) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_formatFileSize(_fileSize!)} · ${_pageCount ?? 0} pages',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                      if (_extractedText != null && _extractedText!.isNotEmpty && !_isExtracting) ...[
                        const SizedBox(height: 4),
                        Text(
                          '✅ ${_extractedText!.length} caractères extraits',
                          style: const TextStyle(fontSize: 12, color: AppColors.success),
                        ),
                      ],
                      if (_fileBytes != null && !_extractionSuccess && !_isExtracting) ...[
                        const SizedBox(height: 4),
                        Text(
                          '⚠️ PDF scanné - Pas de texte extractible',
                          style: const TextStyle(fontSize: 12, color: AppColors.warning),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Formulaire
              Container(
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
                      'Informations du cours',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _titleController,
                      enabled: !_isUploading,
                      decoration: InputDecoration(
                        labelText: 'Titre du cours *',
                        hintText: 'ex: Chapitre 6 - IA générative',
                        prefixIcon: Icon(Icons.title_outlined, color: AppColors.secondary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Titre obligatoire' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _subjectController,
                      enabled: !_isUploading,
                      decoration: InputDecoration(
                        labelText: 'Matière (optionnel)',
                        hintText: 'ex: Intelligence Artificielle',
                        prefixIcon: Icon(Icons.category_outlined, color: AppColors.secondary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bouton Upload
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isUploading || _isExtracting || _fileBytes == null)
                      ? null
                      : _uploadCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    disabledBackgroundColor: AppColors.textHint,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _extractionSuccess ? 'Importer le cours' : 'Importer quand même (sans texte)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
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