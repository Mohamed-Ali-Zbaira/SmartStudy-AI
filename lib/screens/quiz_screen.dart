import 'dart:async';
import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/groq_service.dart';

// ════════════════════════════════════════════════════════════
//  COULEURS
// ════════════════════════════════════════════════════════════
class AppColors {
  static const primary = Color(0xFF1E3A5F);
  static const secondary = Color(0xFF4A90D9);
  static const success = Color(0xFF27AE60);
  static const warning = Color(0xFFE67E22);
  static const danger = Color(0xFFE05050);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE0EAF5);
  static const textPrimary = Color(0xFF1E3A5F);
  static const textSecondary = Color(0xFF6B8BA4);
  static const textHint = Color(0xFF94AFC6);
}

// ════════════════════════════════════════════════════════════
//  MODÈLES
// ════════════════════════════════════════════════════════════
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

// ════════════════════════════════════════════════════════════
//  QUIZ SCREEN — 10 questions, avec Skip
// ════════════════════════════════════════════════════════════
class QuizScreen extends StatefulWidget {
  final CourseModel course;

  const QuizScreen({super.key, required this.course});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _groqService = GroqService();

  bool _quizStarted = false;
  bool _quizFinished = false;
  bool _isGenerating = false;
  String? _generationError;

  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  List<int?> _userAnswers = [];

  Timer? _timer;
  int _secondsLeft = 120; // 2 minutes par question

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Démarrer directement la génération
    _generateQuestions();
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      final questions = await _groqService.generateQuiz(
        widget.course.pdfText,
        numberOfQuestions: 10, // ✅ 10 questions
      );

      if (questions.isEmpty) {
        throw Exception('Aucune question générée');
      }

      setState(() {
        _questions = questions;
        _isGenerating = false;
      });

      _startQuiz();
    } catch (e) {
      setState(() {
        _generationError = e.toString();
        _isGenerating = false;
      });
    }
  }

  void _startQuiz() {
    setState(() {
      _quizStarted = true;
      _currentIndex = 0;
      _selectedAnswer = null;
      _answered = false;
      _score = 0;
      _userAnswers = List.filled(_questions.length, null);
      _secondsLeft = 120;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        // Temps écoulé → passer à la question suivante (réponse fausse)
        _timeoutQuestion();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _timeoutQuestion() {
    if (!_answered) {
      // Marquer comme non répondu (faux)
      setState(() {
        _answered = true;
        _userAnswers[_currentIndex] = -1; // -1 = pas répondu
        // Pas de point
      });
    }
    _nextQuestion();
  }

  void _selectAnswer(int index) {
    if (_answered) return;

    _timer?.cancel();

    setState(() {
      _selectedAnswer = index;
      _answered = true;
      _userAnswers[_currentIndex] = index;
      if (index == _questions[_currentIndex].correctIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
        _secondsLeft = 120;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      setState(() => _quizFinished = true);
    }
  }

  // ✅ Skip / Quitter le quiz
  Future<void> _skipQuiz() async {
    _timer?.cancel();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitter le quiz ?'),
        content: Text(
          _currentIndex > 0
              ? 'Vous avez répondu à ${_currentIndex} question${_currentIndex > 1 ? 's' : ''}. Les questions restantes seront comptées comme fausses.'
              : 'Vous n\'avez répondu à aucune question. Voulez-vous vraiment quitter ?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer', style: TextStyle(color: AppColors.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitter', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // ✅ Marquer les questions restantes comme fausses
      for (int i = _currentIndex + 1; i < _questions.length; i++) {
        if (_userAnswers[i] == null) {
          _userAnswers[i] = -1; // -1 = pas répondu → faux
        }
      }

      // Si la question actuelle n'a pas été répondue, la marquer comme fausse
      if (!_answered) {
        _userAnswers[_currentIndex] = -1;
      }

      setState(() => _quizFinished = true);
    }
  }

  void _restart() {
    setState(() {
      _quizStarted = false;
      _quizFinished = false;
      _questions = [];
      _generationError = null;
    });
    _generateQuestions();
  }

  String get _timerFormatted {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _courseEmoji {
    final s = widget.course.subject.toLowerCase();
    if (s.contains('base') || s.contains('donnée')) return '📊';
    if (s.contains('algo') || s.contains('program')) return '🧮';
    if (s.contains('réseau')) return '🌐';
    if (s.contains('système')) return '🖥️';
    return '📄';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _QuizHeader(
              courseTitle: widget.course.title,
              courseEmoji: _courseEmoji,
              onBack: () => Navigator.pop(context),
              onSkip: _quizStarted && !_quizFinished ? _skipQuiz : null, // ✅ Bouton Skip
            ),
            Expanded(
              child: _quizFinished
                  ? _ResultsView(
                score: _score,
                total: _questions.length,
                questions: _questions,
                userAnswers: _userAnswers,
                onRestart: _restart,
              )
                  : _quizStarted
                  ? _QuizView(
                question: _questions[_currentIndex],
                questionIndex: _currentIndex,
                totalQuestions: _questions.length,
                selectedAnswer: _selectedAnswer,
                answered: _answered,
                timerText: _timerFormatted,
                secondsLeft: _secondsLeft,
                onSelectAnswer: _selectAnswer,
                onNext: _nextQuestion,
              )
                  : _LoadingView(
                isGenerating: _isGenerating,
                error: _generationError,
                onRetry: _generateQuestions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  HEADER (avec bouton Skip)
// ────────────────────────────────────────────────────────────
class _QuizHeader extends StatelessWidget {
  final String courseTitle;
  final String courseEmoji;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  const _QuizHeader({
    required this.courseTitle,
    required this.courseEmoji,
    required this.onBack,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2A5482)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(6, 12, 16, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
          ),
          Text(courseEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text('Quiz · 10 questions', style: TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          // ✅ Bouton Skip
          if (onSkip != null)
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Quitter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  LOADING VIEW
// ────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  final bool isGenerating;
  final String? error;
  final VoidCallback onRetry;

  const _LoadingView({
    required this.isGenerating,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGenerating) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                '🤖 Génération des questions...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cela peut prendre quelques secondes',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ] else if (error != null) ...[
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
                'Erreur de génération',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.danger),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  QUIZ VIEW
// ────────────────────────────────────────────────────────────
class _QuizView extends StatelessWidget {
  final QuizQuestion question;
  final int questionIndex;
  final int totalQuestions;
  final int? selectedAnswer;
  final bool answered;
  final String timerText;
  final int secondsLeft;
  final ValueChanged<int> onSelectAnswer;
  final VoidCallback onNext;

  const _QuizView({
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.selectedAnswer,
    required this.answered,
    required this.timerText,
    required this.secondsLeft,
    required this.onSelectAnswer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final letters = ['A', 'B', 'C', 'D'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre progression + timer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${questionIndex + 1} / $totalQuestions',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: secondsLeft <= 15 ? const Color(0xFFFDEAEA) : const Color(0xFFFEF3E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: secondsLeft <= 15 ? AppColors.danger : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timerText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: secondsLeft <= 15 ? AppColors.danger : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (questionIndex + 1) / totalQuestions,
                    backgroundColor: const Color(0xFFE2EAF5),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Question
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QCM',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  question.question,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Options
          ...List.generate(question.options.length, (i) {
            final isSelected = selectedAnswer == i;
            final isCorrect = i == question.correctIndex;
            final showResult = answered;

            Color borderColor = AppColors.border;
            Color bgColor = AppColors.surface;
            Color textColor = AppColors.textPrimary;
            Color letterBg = const Color(0xFFE2EAF5);
            Color letterFg = AppColors.textPrimary;

            if (showResult) {
              if (isCorrect) {
                borderColor = AppColors.success;
                bgColor = const Color(0xFFEAF7EF);
                textColor = const Color(0xFF1A6B3A);
                letterBg = AppColors.success;
                letterFg = Colors.white;
              } else if (isSelected && !isCorrect) {
                borderColor = AppColors.danger;
                bgColor = const Color(0xFFFDEAEA);
                textColor = const Color(0xFF8B2020);
                letterBg = AppColors.danger;
                letterFg = Colors.white;
              }
            } else if (isSelected) {
              borderColor = AppColors.secondary;
              bgColor = const Color(0xFFEDF4FD);
              letterBg = AppColors.secondary;
              letterFg = Colors.white;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onSelectAnswer(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: letterBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            letters[i],
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: letterFg),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.options[i],
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
                        ),
                      ),
                      if (showResult && isCorrect)
                        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                      if (showResult && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: AppColors.danger, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Explication
          if (answered) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF4FD),
                borderRadius: BorderRadius.circular(10),
                border: const Border(left: BorderSide(color: AppColors.secondary, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Explication',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    question.explanation,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF3D5A75), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bouton Suivant
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  questionIndex < totalQuestions - 1 ? 'Question suivante →' : 'Voir les résultats',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  RESULTS VIEW
// ────────────────────────────────────────────────────────────
class _ResultsView extends StatelessWidget {
  final int score;
  final int total;
  final List<QuizQuestion> questions;
  final List<int?> userAnswers;
  final VoidCallback onRestart;

  const _ResultsView({
    required this.score,
    required this.total,
    required this.questions,
    required this.userAnswers,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final color = pct >= 80
        ? AppColors.success
        : pct >= 50
        ? AppColors.warning
        : AppColors.danger;
    final emoji = pct >= 80 ? '🎉' : pct >= 50 ? '👍' : '📚';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2A5482)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 10),
                Text(
                  '$score / $total',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pct% de bonnes réponses',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Text(
                    pct >= 80
                        ? 'Excellent ! Prêt pour l\'examen'
                        : pct >= 50
                        ? 'Bien ! Continuez à réviser'
                        : 'Revoir ce cours',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détail des réponses',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                ...List.generate(questions.length, (i) {
                  final userAnswer = userAnswers[i];
                  final correct = userAnswer == questions[i].correctIndex;
                  final skipped = userAnswer == -1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          skipped ? Icons.skip_next : (correct ? Icons.check_circle : Icons.cancel),
                          color: skipped ? AppColors.warning : (correct ? AppColors.success : AppColors.danger),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            skipped
                                ? 'Q${i + 1}: Non répondu'
                                : 'Q${i + 1}: ${questions[i].question}',
                            style: TextStyle(
                              fontSize: 12,
                              color: skipped ? AppColors.warning : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRestart,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Nouveau quiz',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Retour au cours',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}