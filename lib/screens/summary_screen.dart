import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:path_provider/path_provider.dart';
import '../models/course_model.dart';
import '../services/groq_service.dart';
import '../config/supabase_config.dart';

// ════════════════════════════════════════════════════════════
//  COULEURS
// ════════════════════════════════════════════════════════════
class AppColors {
  static const primary = Color(0xFF1E3A5F);
  static const secondary = Color(0xFF4A90D9);
  static const success = Color(0xFF27AE60);
  static const warning = Color(0xFFE67E22);
  static const danger = Color(0xFFC0392B);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE0EAF5);
  static const textPrimary = Color(0xFF1E3A5F);
  static const textSecondary = Color(0xFF6B8BA4);
  static const textHint = Color(0xFF94AFC6);
}

// ════════════════════════════════════════════════════════════
//  SUMMARY SCREEN
// ════════════════════════════════════════════════════════════
class SummaryScreen extends StatefulWidget {
  final CourseModel course;

  const SummaryScreen({super.key, required this.course});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _groqService = GroqService();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isDownloading = false;
  String? _error;
  Map<String, dynamic>? _summary;
  String _pdfText = '';

  @override
  void initState() {
    super.initState();
    _loadAndGenerate();
  }

  Future<void> _loadAndGenerate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.course.pdfText.isNotEmpty) {
        _pdfText = widget.course.pdfText;
      } else {
        await _downloadAndExtractText();
      }

      if (_pdfText.isEmpty) {
        setState(() {
          _error = 'Le texte du PDF est vide. Ré-uploader le document.';
          _isLoading = false;
        });
        return;
      }

      final summary = await _groqService.generateSummary(_pdfText);

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndExtractText() async {
    setState(() => _isDownloading = true);

    try {
      final uri = Uri.parse(widget.course.pdfUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(SupabaseConfig.bucketPdfs);

      if (bucketIndex == -1 || bucketIndex + 1 >= pathSegments.length) {
        throw Exception('URL de PDF invalide');
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      final bytes = await _supabase.storage
          .from(SupabaseConfig.bucketPdfs)
          .download(filePath);

      if (kIsWeb) {
        throw Exception('Sur Web, le texte doit être extrait lors de l\'upload.');
      } else {
        final text = await _extractTextWithTempFile(bytes);
        _pdfText = text;
      }

      setState(() => _isDownloading = false);
    } catch (e) {
      setState(() => _isDownloading = false);
      throw Exception('Erreur d\'extraction: $e');
    }
  }

  Future<String> _extractTextWithTempFile(Uint8List bytes) async {
    File? tempFile;
    try {
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await tempFile.writeAsBytes(bytes);

      final pdfDoc = await PDFDoc.fromFile(tempFile);
      final text = await pdfDoc.text;

      return text;
    } finally {
      if (tempFile != null) {
        try {
          await tempFile.delete();
        } catch (e) {}
      }
    }
  }

  Future<void> _regenerateSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _groqService.generateSummary(_pdfText);
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé IA',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            Text(
              widget.course.title,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          if (!_isLoading && _summary != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _regenerateSummary,
            ),
        ],
      ),
      body: _isLoading || _isDownloading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isDownloading ? '📥 Téléchargement du PDF...' : '🤖 Génération du résumé...',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      )
          : _error != null
          ? _ErrorView(error: _error!, onRetry: _loadAndGenerate)
          : _summary != null
          ? _SummaryContent(
        summary: _summary!,
        course: widget.course,
      )
          : const SizedBox(),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ERROR VIEW
// ════════════════════════════════════════════════════════════
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline, size: 36, color: AppColors.danger),
            ),
            const SizedBox(height: 20),
            const Text(
              'Erreur lors de la génération',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SUMMARY CONTENT
// ════════════════════════════════════════════════════════════
class _SummaryContent extends StatelessWidget {
  final Map<String, dynamic> summary;
  final CourseModel course;

  const _SummaryContent({required this.summary, required this.course});

  @override
  Widget build(BuildContext context) {
    final executiveSummary = summary['executiveSummary']?.toString() ?? 'Résumé non disponible';
    final keyPoints = summary['keyPoints'] as List? ?? [];
    final definitions = summary['definitions'] as Map? ?? {};
    final examTips = summary['examTips'] as List? ?? [];
    final difficultyLevel = summary['difficultyLevel']?.toString() ?? 'Moyen';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Niveau de difficulté
          _DifficultyBadge(level: difficultyLevel),
          const SizedBox(height: 16),

          // Résumé exécutif
          _SectionCard(
            title: '📋 Résumé',
            icon: Icons.summarize_outlined,
            color: const Color(0xFF4A90D9),
            child: Text(
              executiveSummary,
              style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 16),

          // Points clés
          if (keyPoints.isNotEmpty)
            _SectionCard(
              title: '🔑 Points clés',
              icon: Icons.key_outlined,
              color: const Color(0xFFE67E22),
              child: Column(
                children: keyPoints.map<Widget>((point) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16, color: AppColors.secondary)),
                        Expanded(
                          child: Text(
                            point.toString(),
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          if (keyPoints.isNotEmpty) const SizedBox(height: 16),

          // Définitions
          if (definitions.isNotEmpty)
            _SectionCard(
              title: '📖 Définitions',
              icon: Icons.book_outlined,
              color: const Color(0xFF27AE60),
              child: Column(
                children: definitions.entries.map<Widget>((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📌 ', style: TextStyle(fontSize: 14, color: AppColors.success)),
                            Expanded(
                              child: Text(
                                entry.key.toString(),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 22),
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          if (definitions.isNotEmpty) const SizedBox(height: 16),

          // Conseils examen
          if (examTips.isNotEmpty)
            _SectionCard(
              title: '💡 Conseils pour l\'examen',
              icon: Icons.lightbulb_outline,
              color: const Color(0xFFF39C12),
              child: Column(
                children: examTips.map<Widget>((tip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            tip.toString(),
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/quiz', arguments: course);
                  },
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Faire le Quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chat', arguments: course);
                  },
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Chat IA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  DIFFICULTY BADGE
// ════════════════════════════════════════════════════════════
class _DifficultyBadge extends StatelessWidget {
  final String level;

  const _DifficultyBadge({required this.level});

  Color get _color {
    switch (level.toLowerCase()) {
      case 'facile': return AppColors.success;
      case 'moyen': return AppColors.warning;
      case 'difficile': return AppColors.danger;
      default: return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.signal_cellular_alt, size: 14, color: _color),
          const SizedBox(width: 6),
          Text('Niveau : $level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _color)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SECTION CARD
// ════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),








          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}